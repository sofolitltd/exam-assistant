import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/controllers/auth_controller.dart';
import '../../exam/controllers/taxonomy_providers.dart';
import '../../exam/data/models/exam_model.dart';
import '../../exam/data/models/exam_result_model.dart';
import '../../exam/data/services/exam_api_service.dart';
import '../../exam/data/services/taxonomy_api_service.dart';
import '../../learning/controllers/learning_providers.dart';
import 'bcs_models.dart';
import 'bcs_sample_data.dart';

/// REAL DATA for the বিসিএস flow.
///
/// The edition list (running, upcoming, past) comes from `/v1/bcs/editions`,
/// which the admin console's "BCS editions" page maintains. A past paper is
/// the published API exam with `kind = pyq` and the same `editionNumber`. Its questions come from the answer key (a past paper
/// has no sitting window, so the key is always open), and each question's
/// subject and part come from walking the syllabus tree up from its topic.
///
/// The live-exam schedule, merit lists for live exams and syllabus
/// comparison are still sample data in [BcsRepository]: the API has no
/// concept of them yet.

final _examApiProvider = Provider<ExamApiService>(
  (ref) => ExamApiService(accountApi: ref.watch(accountApiServiceProvider)),
);

/// Published past BCS papers, newest edition first.
final bcsPaperExamsProvider = FutureProvider.autoDispose<List<ExamModel>>((
  ref,
) async {
  final exams = await ref.read(_examApiProvider).getExams(publishedOnly: true);
  final papers =
      exams
          .where(
            (e) => e.isPublished && e.kind == 'pyq' && e.editionNumber != null,
          )
          .toList()
        ..sort((a, b) => b.editionNumber!.compareTo(a.editionNumber!));
  // One paper per edition: keep the first (a later variant/set is ignored
  // until the UI can tell them apart).
  final seen = <int>{};
  return [
    for (final e in papers)
      if (seen.add(e.editionNumber!)) e,
  ];
});

final bcsMyResultsProvider = FutureProvider.autoDispose<List<ExamResultModel>>((
  ref,
) async {
  try {
    return await ref.read(accountApiServiceProvider).getExamResults();
  } catch (_) {
    // Signed out or offline: show the papers without personal stats.
    return const [];
  }
});

EditionStatus _status(String? value) => switch (value) {
  'running' => EditionStatus.running,
  'upcoming' => EditionStatus.upcoming,
  _ => EditionStatus.completed,
};

BcsEdition _editionFrom(
  Map<String, dynamic> row,
  List<ExamResultModel> allResults,
) {
  final examId = row['paperExamId'] as String?;
  final results =
      allResults.where((r) => examId != null && r.examId == examId).toList()
        ..sort((a, b) => a.answeredAt.compareTo(b.answeredAt));
  var answered = 0;
  double? best;
  for (final r in results) {
    final done = r.correctCount + r.wrongCount;
    if (done > answered) answered = done;
    if (best == null || r.score > best) best = r.score;
  }
  final prelim = DateTime.tryParse(row['prelimDate'] as String? ?? '');
  int? days;
  if (prelim != null) {
    final now = DateTime.now();
    final diff = prelim
        .difference(DateTime(now.year, now.month, now.day))
        .inDays;
    if (diff >= 0) days = diff;
  }
  final questionCount = (row['questionCount'] as num? ?? 0).toInt();
  return BcsEdition(
    number: (row['editionNumber'] as num).toInt(),
    status: _status(row['status'] as String?),
    examId: examId,
    totalQuestions: questionCount > 0 ? questionCount : 200,
    answered: answered,
    bestScore: best,
    firstScore: results.isEmpty ? null : results.first.score,
    daysToPrelim: days,
    special: row['kind'] == 'special',
    specialLabel: row['specialLabel'] as String?,
    prelimDate: prelim,
    note: row['note'] as String?,
    hasPaper: examId != null && questionCount > 0,
  );
}

/// The বিসিএস list from the admin console's "BCS editions", with the
/// user's own progress on each published paper.
final bcsListProvider = FutureProvider.autoDispose<BcsEditionList>((ref) async {
  final json = await ref
      .read(accountApiServiceProvider)
      .getApiJson('/v1/bcs/editions');
  if (json is! List) {
    throw const FormatException('Expected a BCS editions list.');
  }
  final results = await ref.watch(bcsMyResultsProvider.future);
  final editions = [
    for (final row in json)
      _editionFrom(Map<String, dynamic>.from(row as Map), results),
  ];
  // Newest first from the API. The running edition is the newest marked
  // running; the upcoming one the oldest marked upcoming.
  final running = editions
      .where((e) => e.status == EditionStatus.running)
      .firstOrNull;
  final upcoming = editions
      .where((e) => e.status == EditionStatus.upcoming)
      .lastOrNull;
  return BcsEditionList(
    running: running,
    upcoming: upcoming,
    past: [
      for (final e in editions)
        if (e.status == EditionStatus.completed) e,
    ],
  );
});

/// Past editions, newest first, with the user's own progress.
final bcsPastEditionsProvider = FutureProvider<List<BcsEdition>>(
  (ref) async => (await ref.watch(bcsListProvider.future)).past,
);

/// Past editions whose paper can be opened.
final bcsPapersReadyProvider = FutureProvider<List<BcsEdition>>(
  (ref) async => [
    for (final e in await ref.watch(bcsPastEditionsProvider.future))
      if (e.hasPaper) e,
  ],
);

/// The running edition's number for screens outside the বিসিএস flow,
/// falling back to the sample while the list loads.
final bcsRunningNumberProvider = Provider.autoDispose<int>((ref) {
  return ref.watch(bcsListProvider).value?.running?.number ??
      ref.read(bcsRepositoryProvider).runningEdition().number;
});

/// One edition. A past edition with a paper also gets the first-attempt
/// rank and the number of mistakes still to fix.
final bcsEditionProvider = FutureProvider.autoDispose.family<BcsEdition, int>((
  ref,
  number,
) async {
  final list = await ref.watch(bcsListProvider.future);
  final edition = list.byNumber(number);
  if (edition == null) throw BcsPaperMissing(number);
  if (edition.status != EditionStatus.completed ||
      edition.firstScore == null ||
      edition.examId == null) {
    return edition;
  }

  final examId = edition.examId!;
  int? rank;
  int? participants;
  try {
    final json = await ref
        .read(accountApiServiceProvider)
        .getApiJson('/v1/exams/${Uri.encodeComponent(examId)}/my-rank');
    final map = Map<String, dynamic>.from(json as Map);
    rank = (map['rank'] as num?)?.toInt();
    participants = (map['participants'] as num?)?.toInt();
  } catch (_) {}
  int? mistakes;
  try {
    final page = await ref
        .read(learningApiServiceProvider)
        .getMistakes(examId: examId, limit: 200);
    mistakes = page.items.length;
  } catch (_) {}

  return edition.copyWith(
    firstRank: rank,
    participants: participants,
    pendingMistakes: mistakes,
  );
});

/// Thrown when an edition has no published paper yet.
class BcsPaperMissing implements Exception {
  final int number;
  const BcsPaperMissing(this.number);

  @override
  String toString() => 'এই বিসিএসের প্রশ্নপত্র এখনো যোগ করা হয়নি।';
}

/// A whole paper with its questions grouped by syllabus subject and part.
final bcsPaperProvider = FutureProvider.family<BcsPaper, int>((
  ref,
  number,
) async {
  final exams = await ref.watch(bcsPaperExamsProvider.future);
  final exam = exams.where((e) => e.editionNumber == number).firstOrNull;
  if (exam == null) {
    // No published paper yet for this edition (including the running one,
    // until the admin console publishes its exam) — honest "not out yet"
    // rather than a fake stand-in paper.
    throw BcsPaperMissing(number);
  }

  final questions = await ref
      .read(_examApiProvider)
      .getExamAnswerKey(exam.examId);

  final nodes = <int, SyllabusNode>{};
  if (exam.syllabusId != null) {
    try {
      for (final n in await ref.watch(
        syllabusNodesProvider(exam.syllabusId!).future,
      )) {
        nodes[n.nodeId] = n;
      }
    } catch (_) {
      // Without the tree the paper still works, just without the filter.
    }
  }

  SyllabusNode? ancestor(int? nodeId, String type) {
    var node = nodeId == null ? null : nodes[nodeId];
    while (node != null) {
      if (node.nodeType == type) return node;
      node = node.parentId == null ? null : nodes[node.parentId!];
    }
    return null;
  }

  final paperQuestions = <PaperQuestion>[];
  final subjectNodes = <String, SyllabusNode>{};
  final sectionNodes = <String, SyllabusNode>{};
  final subjectCounts = <String, int>{};
  final sectionCounts = <String, Map<String, int>>{};
  for (final q in questions) {
    final subject = ancestor(q.taxonomyNodeId, 'subject');
    final section = ancestor(q.taxonomyNodeId, 'section');
    final subjectId = subject == null ? 'other' : 'n${subject.nodeId}';
    final topicId = section == null ? '' : 'n${section.nodeId}';
    if (subject != null) subjectNodes[subjectId] = subject;
    if (section != null) sectionNodes[topicId] = section;
    subjectCounts[subjectId] = (subjectCounts[subjectId] ?? 0) + 1;
    if (topicId.isNotEmpty) {
      final counts = sectionCounts.putIfAbsent(subjectId, () => {});
      counts[topicId] = (counts[topicId] ?? 0) + 1;
    }
    paperQuestions.add(
      PaperQuestion(
        q,
        appearedIn: [number],
        subjectId: subjectId,
        topicId: topicId,
      ),
    );
  }

  int order(String id) => subjectNodes[id]?.sortOrder ?? 1 << 30;
  final subjectIds = subjectCounts.keys.toList()
    ..sort((a, b) => order(a).compareTo(order(b)));
  final subjects = [
    PaperSubject(id: 'all', label: 'সব', count: paperQuestions.length),
    for (final id in subjectIds)
      PaperSubject(
        id: id,
        label: subjectNodes[id]?.name ?? 'অন্যান্য',
        count: subjectCounts[id]!,
        topics: [
          for (final entry
              in (sectionCounts[id]?.entries.toList() ?? [])..sort(
                (a, b) => (sectionNodes[a.key]?.sortOrder ?? 0).compareTo(
                  sectionNodes[b.key]?.sortOrder ?? 0,
                ),
              ))
            (entry.key, sectionNodes[entry.key]!.name, entry.value),
        ],
      ),
  ];

  return BcsPaper(
    number: number,
    examId: exam.examId,
    syllabusId: exam.syllabusId,
    durationSeconds: exam.durationSeconds > 0
        ? exam.durationSeconds
        : 2 * 60 * 60,
    negativeMarks: exam.negativeMarks,
    questions: paperQuestions,
    subjects: subjects,
  );
});

/// Ids of the questions in [examId] the user got wrong and hasn't fixed.
final bcsMistakeIdsProvider = FutureProvider.autoDispose
    .family<Set<String>, String>((ref, examId) async {
      try {
        final page = await ref
            .read(learningApiServiceProvider)
            .getMistakes(examId: examId, limit: 200);
        return {for (final m in page.items) m.question.id};
      } catch (_) {
        return const {};
      }
    });

/// Subject-wise past questions: every published paper's questions grouped
/// by syllabus subject, then by topic. A topic's editions are the papers it
/// appeared in; topics that appeared in more papers come first.
final bcsPyqIndexProvider = FutureProvider<PyqIndex>((ref) async {
  final ready = await ref.watch(bcsPapersReadyProvider.future);
  final papers = await Future.wait([
    for (final e in ready) ref.watch(bcsPaperProvider(e.number).future),
  ]);

  final subjectOrder = <String, int>{};
  final topics = <String, Map<int, _TopicAcc>>{};
  for (final paper in papers) {
    final labels = {for (final s in paper.subjects) s.id: s.label};
    for (var i = 0; i < paper.subjects.length; i++) {
      subjectOrder.putIfAbsent(paper.subjects[i].label, () => i);
    }
    for (final q in paper.questions) {
      final nodeId = q.question.taxonomyNodeId;
      if (nodeId == null || paper.syllabusId == null) continue;
      final subject = labels[q.subjectId] ?? 'অন্যান্য';
      final acc = topics
          .putIfAbsent(subject, () => {})
          .putIfAbsent(
            nodeId,
            () => _TopicAcc(nodeId, paper.syllabusId!, q.question.subject),
          );
      acc.items.add(PyqItem(paper.number, q.question));
    }
  }

  final subjects =
      [
        for (final entry in topics.entries)
          PyqSubject(
            label: entry.key,
            topics:
                [
                  for (final t in entry.value.values)
                    PyqTopic(
                      nodeId: t.nodeId,
                      syllabusId: t.syllabusId,
                      name: t.name,
                      items: t.items
                        ..sort((a, b) => b.edition.compareTo(a.edition)),
                    ),
                ]..sort(
                  (a, b) => b.editions.length != a.editions.length
                      ? b.editions.length.compareTo(a.editions.length)
                      : b.questions.compareTo(a.questions),
                ),
          ),
      ]..sort(
        (a, b) => (subjectOrder[a.label] ?? 999).compareTo(
          subjectOrder[b.label] ?? 999,
        ),
      );

  return PyqIndex(
    editions: [for (final e in ready) e.number]..sort(),
    subjects: subjects,
  );
});

class _TopicAcc {
  final int nodeId;
  final int syllabusId;
  final String name;
  final List<PyqItem> items = [];

  _TopicAcc(this.nodeId, this.syllabusId, this.name);
}

/// The marks each subject carried under the syllabus BCS papers were
/// actually set on ("current" in `syllabus_versions`) and under the newest
/// officially-reported update ("draft"), for the সিলেবাস compare screen.
/// Falls back to just the current syllabus (no change) when no update has
/// been reported yet.
final bcsSyllabusCompareProvider = FutureProvider<List<SyllabusSubject>>((
  ref,
) async {
  final programs = await ref.watch(taxonomyProgramsProvider.future);
  final program = programs.where((p) => p.code == 'BCS').firstOrNull;
  if (program == null) return const [];

  final versions = await ref.watch(syllabiProvider(program.programId).future);
  final current = versions.where((v) => v.status == 'current').firstOrNull;
  if (current == null) return const [];
  final drafts = versions.where((v) => v.status == 'draft').toList()
    ..sort(
      (a, b) => (b.effectiveFrom ?? DateTime(0)).compareTo(
        a.effectiveFrom ?? DateTime(0),
      ),
    );
  final draft = drafts.firstOrNull;

  final oldNodes = await ref.watch(syllabusNodesProvider(current.syllabusId).future);
  final newNodes = draft == null
      ? oldNodes
      : await ref.watch(syllabusNodesProvider(draft.syllabusId).future);

  final oldSubjects = {
    for (final n in oldNodes)
      if (n.nodeType == 'subject') n.code: n,
  };
  final newSubjects = {
    for (final n in newNodes)
      if (n.nodeType == 'subject') n.code: n,
  };
  final codes = {...oldSubjects.keys, ...newSubjects.keys}.toList()
    ..sort(
      (a, b) => (newSubjects[a]?.sortOrder ?? oldSubjects[a]?.sortOrder ?? 0)
          .compareTo(
            newSubjects[b]?.sortOrder ?? oldSubjects[b]?.sortOrder ?? 0,
          ),
    );

  return [
    for (final code in codes)
      SyllabusSubject(
        id: code,
        name: newSubjects[code]?.name ?? oldSubjects[code]!.name,
        oldMarks: (oldSubjects[code]?.marks ?? 0).round(),
        newMarks: (newSubjects[code]?.marks ?? 0).round(),
      ),
  ];
});

/// For every question id across every published past paper, every edition
/// it appeared in — used to flag repeated questions on a paper's analysis.
final bcsQuestionEditionsProvider = FutureProvider<Map<String, Set<int>>>((
  ref,
) async {
  final ready = await ref.watch(bcsPapersReadyProvider.future);
  final papers = await Future.wait([
    for (final e in ready) ref.watch(bcsPaperProvider(e.number).future),
  ]);
  final editions = <String, Set<int>>{};
  for (final paper in papers) {
    for (final q in paper.questions) {
      editions.putIfAbsent(q.question.id, () => {}).add(paper.number);
    }
  }
  return editions;
});

/// A paper's analysis: everyone's average and hardest questions come from
/// the API once its sitting window has closed; the rest (my best, top
/// topics, repeats) is derived from data the app already fetches.
final bcsEditionAnalysisProvider = FutureProvider.family<EditionAnalysis, int>((
  ref,
  number,
) async {
  final paper = await ref.watch(bcsPaperProvider(number).future);
  final edition = await ref.watch(bcsEditionProvider(number).future);
  final questionEditions = await ref.watch(bcsQuestionEditionsProvider.future);

  final topTopics = [
    for (final subject in paper.subjects)
      if (subject.id != 'all')
        for (final (_, label, count) in subject.topics)
          ('${subject.label}: $label', count),
  ]..sort((a, b) => b.$2.compareTo(a.$2));

  final repeated = paper.questions
      .where((q) => (questionEditions[q.question.id]?.length ?? 1) > 1)
      .length;

  double? average;
  var hardest = const <HardQuestion>[];
  if (paper.examId != null) {
    try {
      final stats = await ref
          .read(_examApiProvider)
          .getExamStats(paper.examId!);
      average = stats.participants > 0 ? stats.average : null;
      hardest = [
        for (final h in stats.hardest)
          HardQuestion(h.questionText, h.correctPercent),
      ];
    } catch (_) {
      // Stats aren't open yet (exam still running) or the call failed;
      // the rest of the analysis still works without them.
    }
  }

  return EditionAnalysis(
    average: average,
    myBest: edition.bestScore,
    repeated: repeated,
    topTopics: topTopics.take(5).toList(),
    hardest: hardest,
  );
});
