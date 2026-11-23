import '../../exam/data/models/question_model.dart';

/// A job-exam category on the home grid (বিসিএস, ব্যাংক নিয়োগ, …).
class ExamCategory {
  final String id;
  final String name;
  final String status;
  final bool running;

  const ExamCategory({
    required this.id,
    required this.name,
    required this.status,
    this.running = false,
  });
}

enum EditionStatus { running, upcoming, completed }

/// One BCS sitting: a running preparation (৫২তম), an upcoming one (৫৩তম) or
/// a finished question paper (৪৪তম).
class BcsEdition {
  final int number;

  /// The API exam behind a past paper (bcs-44-pre). Null for the sample
  /// running/upcoming editions.
  final String? examId;
  final EditionStatus status;

  /// Completed editions: questions answered out of [totalQuestions] in the
  /// user's attempts. 0 means not started.
  final int answered;
  final int totalQuestions;

  /// Best score across all attempts, if the paper was finished at least once.
  final double? bestScore;

  /// First attempt's score and merit rank (only the first attempt counts).
  final double? firstScore;
  final int? firstRank;
  final int participants;

  final int? daysToPrelim;
  final int pendingMistakes;
  final int savedQuestions;

  /// A special BCS (only some cadres), and whom it was for (স্বাস্থ্য).
  final bool special;
  final String? specialLabel;
  final DateTime? prelimDate;
  final String? note;

  /// Whether the question paper has been published in the app.
  final bool hasPaper;

  const BcsEdition({
    required this.number,
    required this.status,
    this.examId,
    this.answered = 0,
    this.totalQuestions = 200,
    this.bestScore,
    this.firstScore,
    this.firstRank,
    this.participants = 0,
    this.daysToPrelim,
    this.pendingMistakes = 0,
    this.savedQuestions = 0,
    this.special = false,
    this.specialLabel,
    this.prelimDate,
    this.note,
    this.hasPaper = false,
  });

  BcsEdition copyWith({
    int? firstRank,
    int? participants,
    int? pendingMistakes,
  }) => BcsEdition(
    number: number,
    status: status,
    examId: examId,
    answered: answered,
    totalQuestions: totalQuestions,
    bestScore: bestScore,
    firstScore: firstScore,
    firstRank: firstRank ?? this.firstRank,
    participants: participants ?? this.participants,
    daysToPrelim: daysToPrelim,
    pendingMistakes: pendingMistakes ?? this.pendingMistakes,
    savedQuestions: savedQuestions,
    special: special,
    specialLabel: specialLabel,
    prelimDate: prelimDate,
    note: note,
    hasPaper: hasPaper,
  );

  String get id => '$number';
  bool get started => answered > 0 || bestScore != null;
  bool get finished => bestScore != null;
}

enum SlotState { missed, done, today, upcoming }

/// A scheduled live exam in a running edition.
class LiveSlot {
  final DateTime date;
  final String subject;
  final String? topics;
  final int questions;
  final int minutes;
  final double negative;
  final int materials;
  final SlotState state;
  final double? score;
  final double? fullMarks;
  final int? rank;

  const LiveSlot({
    required this.date,
    required this.subject,
    required this.questions,
    required this.minutes,
    required this.state,
    this.topics,
    this.negative = 0.5,
    this.materials = 0,
    this.score,
    this.fullMarks,
    this.rank,
  });
}

class MeritEntry {
  final int rank;
  final String name;
  final double score;
  final String time;
  final bool isMe;

  const MeritEntry({
    required this.rank,
    required this.name,
    required this.score,
    required this.time,
    this.isMe = false,
  });
}

class MeritBoard {
  final String label;
  final double fullMarks;
  final int participants;
  final MeritEntry me;
  final List<MeritEntry> top;

  const MeritBoard({
    required this.label,
    required this.fullMarks,
    required this.participants,
    required this.me,
    required this.top,
  });

  int get topPercent => ((me.rank / participants) * 100).ceil().clamp(1, 100);
}

class SyllabusSubject {
  final String id;
  final String name;
  final int oldMarks;
  final int newMarks;

  const SyllabusSubject({
    required this.id,
    required this.name,
    required this.oldMarks,
    required this.newMarks,
  });
}

class HardQuestion {
  final String text;
  final int correctPercent;

  const HardQuestion(this.text, this.correctPercent);
}

class EditionAnalysis {
  final double? average;
  final double? myBest;
  final int repeated;
  final List<(String, int)> topTopics;
  final List<HardQuestion> hardest;

  const EditionAnalysis({
    required this.average,
    required this.myBest,
    required this.repeated,
    required this.topTopics,
    required this.hardest,
  });
}

/// Subjects and topics a user can narrow a paper to in পড়ো ও শোনো /
/// অনুশীলন.
class PaperSubject {
  final String id;
  final String label;
  final int count;
  final List<(String id, String label, int count)> topics;

  const PaperSubject({
    required this.id,
    required this.label,
    required this.count,
    this.topics = const [],
  });
}

/// What the user picked in the mode sheet.
class PaperSelection {
  final String subjectId;
  final String subjectLabel;
  final String topicId;
  final String topicLabel;
  final bool wrongOnly;
  final int count;

  const PaperSelection({
    required this.subjectId,
    required this.subjectLabel,
    required this.topicId,
    required this.topicLabel,
    required this.wrongOnly,
    required this.count,
  });

  static const all = PaperSelection(
    subjectId: 'all',
    subjectLabel: 'সব বিষয়',
    topicId: 'all',
    topicLabel: 'সব topic',
    wrongOnly: false,
    count: 20,
  );
}

/// A paper question plus the BCS editions it has appeared in, and the
/// syllabus subject and part it is tagged to (used by the mode sheet's
/// subject/topic filter).
class PaperQuestion {
  final QuestionModel question;
  final List<int> appearedIn;
  final String subjectId;
  final String topicId;

  const PaperQuestion(
    this.question, {
    this.appearedIn = const [],
    this.subjectId = '',
    this.topicId = '',
  });
}

/// Everything a paper mode needs: the exam, its questions and the
/// subject/topic breakdown for the mode sheet.
class BcsPaper {
  final int number;
  final String? examId;
  final int? syllabusId;
  final int durationSeconds;
  final double negativeMarks;
  final List<PaperQuestion> questions;
  final List<PaperSubject> subjects;

  const BcsPaper({
    required this.number,
    required this.examId,
    this.syllabusId,
    required this.durationSeconds,
    required this.negativeMarks,
    required this.questions,
    required this.subjects,
  });
}

/// The paper questions matching [selection]. With `wrongOnly`, only the ids
/// in [mistakes] are kept.
List<PaperQuestion> selectQuestions(
  BcsPaper paper,
  PaperSelection selection, {
  Set<String> mistakes = const {},
}) {
  return [
    for (final q in paper.questions)
      if ((selection.subjectId == 'all' ||
              q.subjectId == selection.subjectId) &&
          (selection.topicId == 'all' || q.topicId == selection.topicId) &&
          (!selection.wrongOnly || mistakes.contains(q.question.id)))
        q,
  ];
}

/// The app's বিসিএস list, maintained in the admin console.
class BcsEditionList {
  final BcsEdition? running;
  final BcsEdition? upcoming;
  final List<BcsEdition> past;

  const BcsEditionList({
    required this.running,
    required this.upcoming,
    required this.past,
  });

  List<BcsEdition> get all => [?running, ?upcoming, ...past];

  BcsEdition? byNumber(int number) =>
      all.where((e) => e.number == number).firstOrNull;
}

/// One past question with the BCS edition it appeared in.
class PyqItem {
  final int edition;
  final QuestionModel question;

  const PyqItem(this.edition, this.question);
}

/// One syllabus topic in the subject-wise past questions: its questions and
/// the BCS editions they appeared in.
class PyqTopic {
  final int nodeId;
  final int syllabusId;
  final String name;

  /// Newest edition first.
  final List<PyqItem> items;

  const PyqTopic({
    required this.nodeId,
    required this.syllabusId,
    required this.name,
    required this.items,
  });

  int get questions => items.length;

  /// Distinct editions, newest first.
  List<int> get editions =>
      ({for (final i in items) i.edition}.toList()..sort((a, b) => b - a));

  /// Only the questions from [editions]; null when none are left.
  PyqTopic? only(Set<int> editions) {
    final kept = items.where((i) => editions.contains(i.edition)).toList();
    if (kept.isEmpty) return null;
    return PyqTopic(
      nodeId: nodeId,
      syllabusId: syllabusId,
      name: name,
      items: kept,
    );
  }
}

/// A syllabus subject with its topics, most frequent first.
class PyqSubject {
  final String label;
  final List<PyqTopic> topics;

  const PyqSubject({required this.label, required this.topics});

  int get questions => topics.fold(0, (sum, t) => sum + t.questions);
}

/// Subject-wise past questions across every published paper.
class PyqIndex {
  /// Every published edition, oldest first.
  final List<int> editions;
  final List<PyqSubject> subjects;

  const PyqIndex({required this.editions, required this.subjects});

  /// The index limited to [selected] editions. An empty set means all.
  /// [editions] stays the full list so the filter can still offer them.
  PyqIndex only(Set<int> selected) {
    if (selected.isEmpty) return this;
    return PyqIndex(
      editions: editions,
      subjects: [
        for (final s in subjects)
          if (s.topics.map((t) => t.only(selected)).nonNulls.toList()
              case final topics when topics.isNotEmpty)
            PyqSubject(label: s.label, topics: topics),
      ],
    );
  }
}
