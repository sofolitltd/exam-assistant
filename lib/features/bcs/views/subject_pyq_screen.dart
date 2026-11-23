import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/bangla_digits.dart';
import '../../../core/widgets/ds.dart';
import '../../../core/widgets/option_marker.dart';
import '../../exam/data/models/question_model.dart';
import '../../exam/services/question_tts_service.dart';
import '../../exam/widgets/question_playback_bar.dart';
import '../data/bcs_api.dart';
import '../data/bcs_models.dart';
import 'bcs_async.dart';
import 'bcs_format.dart';

/// Parses the `bcs` query param ("44,45") into the edition filter.
Set<int> parsePyqFilter(String? raw) => {
  for (final part in (raw ?? '').split(',')) ?int.tryParse(part.trim()),
};

String _filterQuery(Set<int> filter) =>
    filter.isEmpty ? '' : '&bcs=${(filter.toList()..sort()).join(',')}';

/// Past BCS questions from every published paper (real data,
/// `bcsPyqIndexProvider`), shown as a grid of subject cards. A card opens
/// [PyqSubjectScreen]; the search box finds topics across all subjects and
/// the filter keeps only some BCS editions. The edition page opens this
/// with its own edition already in the filter (`?bcs=44`).
class SubjectPyqScreen extends ConsumerStatefulWidget {
  final Set<int> initialFilter;

  const SubjectPyqScreen({this.initialFilter = const {}, super.key});

  @override
  ConsumerState<SubjectPyqScreen> createState() => _SubjectPyqScreenState();
}

class _SubjectPyqScreenState extends ConsumerState<SubjectPyqScreen> {
  String _query = '';
  late Set<int> _filter = widget.initialFilter;

  @override
  Widget build(BuildContext context) {
    final index = ref.watch(bcsPyqIndexProvider);
    return BcsAsync(
      title: 'বিষয়ভিত্তিক বিগত প্রশ্ন',
      value: index,
      onRetry: () => ref.invalidate(bcsPaperExamsProvider),
      builder: (index) => index.subjects.isEmpty
          ? const _EmptyPage(
              title: 'বিষয়ভিত্তিক বিগত প্রশ্ন',
              message: 'এখনো কোনো প্রশ্নপত্র যোগ করা হয়নি।',
            )
          : _page(context, index),
    );
  }

  Widget _page(BuildContext context, PyqIndex full) {
    final index = full.only(_filter);
    final subjects = index.subjects;
    final q = _query.toLowerCase();

    final List<Widget> body;
    if (subjects.isEmpty) {
      body = [const _NothingFound()];
    } else if (q.isEmpty) {
      body = [
        Text(
          '${bn(subjects.length)}টি বিষয় · '
          '${bn(subjects.fold<int>(0, (sum, s) => sum + s.questions))} প্রশ্ন',
          style: dsText(13, weight: FontWeight.w600, color: AppColors.ink2),
        ),
        DsGrid(
          gap: 10,
          children: [
            for (final s in subjects)
              _SubjectCard(
                subject: s,
                onTap: () => context.push(
                  '/bcs/pyq/subject?name=${Uri.encodeComponent(s.label)}'
                  '${_filterQuery(_filter)}',
                ),
              ),
          ],
        ),
      ];
    } else {
      final groups = <(PyqSubject, List<PyqTopic>)>[
        for (final s in subjects)
          (s, s.topics.where((t) => _matches(t, q)).toList()),
      ].where((g) => g.$2.isNotEmpty).toList();
      body = groups.isEmpty
          ? [const _NothingFound()]
          : [
              for (final (s, topics) in groups) ...[
                Text(
                  s.label,
                  style: dsText(
                    13,
                    weight: FontWeight.w600,
                    color: AppColors.ink2,
                  ),
                ),
                _TopicList(
                  topics: topics,
                  totalPapers: _paperCount(full, _filter),
                  filter: _filter,
                ),
              ],
            ];
    }

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: DsHeader(
        title: 'বিষয়ভিত্তিক বিগত প্রশ্ন',
        subtitle: _subtitle(full.editions, _filter),
        bordered: false,
      ),
      body: Column(
        children: [
          _SearchBar(
            hint: 'প্রশ্ন বা topic খোঁজো',
            onChanged: (v) => setState(() => _query = v.trim()),
            editions: full.editions,
            filter: _filter,
            onFilter: (f) => setState(() => _filter = f),
          ),
          const Divider(height: 1, color: AppColors.line),
          Expanded(
            child: DsPage(
              children: [
                if (_filter.isNotEmpty) _PracticeCard(filter: _filter),
                ...body,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One subject's topics, most frequent first. A topic opens
/// [PyqTopicQuestionsScreen] with the same filter.
class PyqSubjectScreen extends ConsumerStatefulWidget {
  final String subject;
  final Set<int> initialFilter;

  const PyqSubjectScreen({
    required this.subject,
    this.initialFilter = const {},
    super.key,
  });

  @override
  ConsumerState<PyqSubjectScreen> createState() => _PyqSubjectScreenState();
}

class _PyqSubjectScreenState extends ConsumerState<PyqSubjectScreen> {
  String _query = '';
  late Set<int> _filter = widget.initialFilter;

  @override
  Widget build(BuildContext context) {
    final index = ref.watch(bcsPyqIndexProvider);
    return BcsAsync(
      title: widget.subject,
      value: index,
      onRetry: () => ref.invalidate(bcsPaperExamsProvider),
      builder: (index) {
        final exists = index.subjects.any((s) => s.label == widget.subject);
        if (!exists) {
          return _EmptyPage(
            title: widget.subject,
            message: 'এই বিষয়ে এখনো কোনো প্রশ্ন নেই।',
          );
        }
        return _page(context, index);
      },
    );
  }

  Widget _page(BuildContext context, PyqIndex full) {
    final subject = full
        .only(_filter)
        .subjects
        .where((s) => s.label == widget.subject)
        .firstOrNull;
    final all = subject?.topics ?? const <PyqTopic>[];
    final q = _query.toLowerCase();
    final topics = q.isEmpty ? all : all.where((t) => _matches(t, q)).toList();

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: DsHeader(
        title: widget.subject,
        subtitle: _subtitle(full.editions, _filter),
        bordered: false,
      ),
      body: Column(
        children: [
          _SearchBar(
            hint: 'এই বিষয়ে খোঁজো',
            onChanged: (v) => setState(() => _query = v.trim()),
            editions: full.editions,
            filter: _filter,
            onFilter: (f) => setState(() => _filter = f),
          ),
          const Divider(height: 1, color: AppColors.line),
          Expanded(
            child: DsPage(
              children: [
                if (_filter.isNotEmpty) _PracticeCard(filter: _filter),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${bn(all.length)}টি topic · '
                        '${bn(subject?.questions ?? 0)} প্রশ্ন',
                        style: dsText(
                          13,
                          weight: FontWeight.w600,
                          color: AppColors.ink2,
                        ),
                      ),
                    ),
                    Text(
                      'সাজানো: বেশি এসেছে আগে',
                      style: dsText(12, color: AppColors.muted),
                    ),
                  ],
                ),
                if (topics.isEmpty)
                  const _NothingFound()
                else
                  _TopicList(
                    topics: topics,
                    totalPapers: _paperCount(full, _filter),
                    filter: _filter,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A topic's past questions, limited to the BCS editions in [filter]
/// (all when empty), each tagged with its edition. Questions come from the
/// published papers already loaded for the index.
class PyqTopicQuestionsScreen extends ConsumerStatefulWidget {
  final int syllabusId;
  final int nodeId;
  final String title;
  final Set<int> filter;

  const PyqTopicQuestionsScreen({
    required this.syllabusId,
    required this.nodeId,
    required this.title,
    this.filter = const {},
    super.key,
  });

  @override
  ConsumerState<PyqTopicQuestionsScreen> createState() =>
      _PyqTopicQuestionsScreenState();
}

class _PyqTopicQuestionsScreenState
    extends ConsumerState<PyqTopicQuestionsScreen> {
  late final QuestionTtsService _tts;
  List<GlobalKey> _keys = const [];
  int? _active;

  @override
  void initState() {
    super.initState();
    _tts = ref.read(questionTtsServiceProvider);
  }

  @override
  void dispose() {
    // Stop reading aloud when leaving; nothing would be left to stop it.
    _tts.stop();
    super.dispose();
  }

  void _onActive(int? i) {
    if (!mounted) return;
    setState(() => _active = i);
    if (i == null || i >= _keys.length) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final c = _keys[i].currentContext;
      if (c != null) {
        Scrollable.ensureVisible(
          c,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          alignment: 0.1,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final index = ref.watch(bcsPyqIndexProvider);
    return BcsAsync(
      title: widget.title,
      value: index,
      onRetry: () => ref.invalidate(bcsPaperExamsProvider),
      builder: (index) {
        PyqTopic? topic;
        for (final s in index.only(widget.filter).subjects) {
          for (final t in s.topics) {
            if (t.nodeId == widget.nodeId &&
                t.syllabusId == widget.syllabusId) {
              topic = t;
            }
          }
        }
        final items = topic?.items ?? const <PyqItem>[];
        if (_keys.length != items.length) {
          _keys = List.generate(items.length, (_) => GlobalKey());
        }
        final questions = [for (final i in items) i.question];
        return Scaffold(
          backgroundColor: AppColors.canvas,
          appBar: DsHeader(
            title: widget.title,
            subtitle: widget.filter.isEmpty
                ? '${bn(items.length)} প্রশ্ন · সব বিসিএস'
                : '${bn(items.length)} প্রশ্ন · ${_filterLabel(widget.filter)}',
            bordered: false,
            trailing: questions.isEmpty
                ? null
                : QuestionPlaybackBar(
                    questions: questions,
                    onActiveIndexChanged: _onActive,
                  ),
          ),
          body: items.isEmpty
              ? Center(
                  child: Text(
                    'এই ফিল্টারে কোনো প্রশ্ন নেই।',
                    style: dsText(14, color: AppColors.muted),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (_, i) => _QuestionCard(
                    key: _keys[i],
                    number: i + 1,
                    item: items[i],
                    active: i == _active,
                  ),
                ),
        );
      },
    );
  }
}

class _QuestionCard extends StatelessWidget {
  final int number;
  final PyqItem item;
  final bool active;

  const _QuestionCard({
    required this.number,
    required this.item,
    required this.active,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final QuestionModel q = item.question;
    return DsCard(
      borderColor: active ? AppColors.brand : AppColors.line,
      borderWidth: active ? 2 : 1,
      padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '${bn(number)}.',
                style: dsText(
                  13,
                  weight: FontWeight.w600,
                  color: AppColors.muted,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.brandSoft,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  editionName(item.edition),
                  style: dsText(
                    11,
                    weight: FontWeight.w600,
                    color: AppColors.brand,
                  ),
                ),
              ),
              const Spacer(),
              QuestionSpeakButton(question: q),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8, top: 2),
            child: Text(
              q.questionText,
              style: dsText(15, weight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 8),
          for (final (i, option) in q.options.indexed)
            Padding(
              padding: const EdgeInsets.only(bottom: 6, right: 8),
              child: Row(
                children: [
                  OptionMarker(
                    index: i,
                    optionKey: option.key,
                    state: q.correctOptionKeys.contains(option.key)
                        ? OptionMarkerState.correct
                        : OptionMarkerState.neutral,
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(option.value, style: dsText(14))),
                ],
              ),
            ),
          if (q.explanation?.isNotEmpty ?? false) ...[
            const Divider(color: AppColors.line),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                q.explanation!,
                style: dsText(13, color: AppColors.ink2),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

bool _matches(PyqTopic t, String q) =>
    t.name.toLowerCase().contains(q) ||
    t.items.any((i) => i.question.questionText.toLowerCase().contains(q));

/// How many papers the "every paper" badge compares against.
int _paperCount(PyqIndex full, Set<int> filter) =>
    filter.isEmpty ? full.editions.length : filter.length;

String _filterLabel(Set<int> filter) {
  final sorted = filter.toList()..sort((a, b) => b - a);
  return sorted.length == 1
      ? editionName(sorted.first)
      : '${sorted.map(bn).join(', ')}তম বিসিএস';
}

String _subtitle(List<int> editions, Set<int> filter) {
  if (filter.isNotEmpty) return 'ফিল্টার: ${_filterLabel(filter)}';
  return editions.length == 1
      ? editionName(editions.first)
      : '${bn(editions.first)}–${bnOrdinal(editions.last)} বিসিএস · '
            '${bn(editions.length)}টি প্রশ্নপত্র';
}

class _NothingFound extends StatelessWidget {
  const _NothingFound();

  @override
  Widget build(BuildContext context) {
    return DsCard(
      child: Text(
        'এই খোঁজে কিছু পাওয়া যায়নি।',
        style: dsText(14, color: AppColors.muted),
      ),
    );
  }
}

class _EmptyPage extends StatelessWidget {
  final String title;
  final String message;

  const _EmptyPage({required this.title, required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: DsHeader(title: title),
      body: Center(
        child: Text(message, style: dsText(14, color: AppColors.muted)),
      ),
    );
  }
}

/// Search box with the BCS filter button beside it, and a line naming the
/// active filter under it.
class _SearchBar extends StatelessWidget {
  final String hint;
  final ValueChanged<String> onChanged;
  final List<int> editions;
  final Set<int> filter;
  final ValueChanged<Set<int>> onFilter;

  const _SearchBar({
    required this.hint,
    required this.onChanged,
    required this.editions,
    required this.filter,
    required this.onFilter,
  });

  @override
  Widget build(BuildContext context) {
    final none = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    );
    final active = filter.isNotEmpty;
    return Container(
      color: AppColors.paper,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 42,
                  child: TextField(
                    onChanged: onChanged,
                    style: dsText(14),
                    decoration: InputDecoration(
                      hintText: hint,
                      hintStyle: dsText(14, color: AppColors.muted),
                      prefixIcon: const Icon(LucideIcons.search, size: 18),
                      filled: true,
                      fillColor: AppColors.sunken,
                      contentPadding: EdgeInsets.zero,
                      border: none,
                      enabledBorder: none,
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.brand),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Material(
                color: active ? AppColors.brand : AppColors.sunken,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () async {
                    final picked = await _showFilterSheet(
                      context,
                      editions,
                      filter,
                    );
                    if (picked != null) onFilter(picked);
                  },
                  child: SizedBox(
                    width: 42,
                    height: 42,
                    child: Icon(
                      LucideIcons.slidersHorizontal,
                      size: 18,
                      color: active ? Colors.white : AppColors.ink,
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (active) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'শুধু ${_filterLabel(filter)}-এর প্রশ্ন',
                    style: dsText(
                      12,
                      weight: FontWeight.w600,
                      color: AppColors.brand,
                    ),
                  ),
                ),
                InkWell(
                  onTap: () => onFilter(const {}),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 2,
                    ),
                    child: Text(
                      'ফিল্টার মুছো',
                      style: dsText(12, color: AppColors.muted),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

Future<Set<int>?> _showFilterSheet(
  BuildContext context,
  List<int> editions,
  Set<int> current,
) {
  return showModalBottomSheet<Set<int>>(
    context: context,
    backgroundColor: AppColors.paper,
    showDragHandle: true,
    builder: (_) => _FilterSheet(editions: editions, current: current),
  );
}

/// Tapping a BCS applies it at once and closes the sheet.
class _FilterSheet extends StatelessWidget {
  final List<int> editions;
  final Set<int> current;

  const _FilterSheet({required this.editions, required this.current});

  @override
  Widget build(BuildContext context) {
    void pick(Set<int> f) => Navigator.of(context).pop(f);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'বিসিএস বাছাই করো',
              style: dsText(17, weight: FontWeight.w700),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                DsChip(
                  label: 'সব বিসিএস',
                  selected: current.isEmpty,
                  onTap: () => pick(const {}),
                ),
                for (final n in editions.reversed)
                  DsChip(
                    label: editionName(n),
                    selected: current.length == 1 && current.contains(n),
                    onTap: () => pick({n}),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SubjectCard extends StatelessWidget {
  final PyqSubject subject;
  final VoidCallback onTap;

  const _SubjectCard({required this.subject, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return DsCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const IconSquare(LucideIcons.bookOpen, size: 36),
          const SizedBox(height: 10),
          Text(
            subject.label,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: dsText(15, weight: FontWeight.w600),
          ),
          const Spacer(),
          const SizedBox(height: 8),
          Text(
            '${bn(subject.topics.length)}টি topic · ${bn(subject.questions)} প্রশ্ন',
            style: dsText(12, color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}

class _TopicList extends StatelessWidget {
  final List<PyqTopic> topics;
  final int totalPapers;
  final Set<int> filter;

  const _TopicList({
    required this.topics,
    required this.totalPapers,
    required this.filter,
  });

  @override
  Widget build(BuildContext context) {
    return DsListCard(
      children: [
        for (final topic in topics)
          _TopicRow(
            topic: topic,
            totalPapers: totalPapers,
            onTap: () => context.push(
              '/bcs/pyq/topic?syllabus=${topic.syllabusId}'
              '&node=${topic.nodeId}'
              '&title=${Uri.encodeComponent(topic.name)}'
              '${_filterQuery(filter)}',
            ),
          ),
      ],
    );
  }
}

/// Shown at the top of the list when a BCS filter is on: one row per
/// filtered edition that opens its full-paper practice.
class _PracticeCard extends StatelessWidget {
  final Set<int> filter;

  const _PracticeCard({required this.filter});

  @override
  Widget build(BuildContext context) {
    final editions = filter.toList()..sort((a, b) => b - a);
    return Material(
      color: AppColors.brandSoft,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.brandLine),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (final (i, n) in editions.indexed) ...[
            if (i > 0) const Divider(height: 1, color: AppColors.brandLine),
            InkWell(
              onTap: () => context.push('/bcs/$n/practice'),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: AppColors.brand,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        LucideIcons.pencilLine,
                        size: 18,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${editionName(n)} অনুশীলন',
                            style: dsText(
                              15,
                              weight: FontWeight.w700,
                              color: AppColors.brandStrong,
                            ),
                          ),
                          Text(
                            'পুরো প্রশ্নপত্র একসাথে অনুশীলন করো',
                            style: dsText(12, color: AppColors.brandInk2),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      LucideIcons.chevronRight,
                      size: 18,
                      color: AppColors.brand,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TopicRow extends StatelessWidget {
  final PyqTopic topic;
  final int totalPapers;
  final VoidCallback onTap;

  const _TopicRow({
    required this.topic,
    required this.totalPapers,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final everyPaper = totalPapers > 1 && topic.editions.length == totalPapers;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(topic.name, style: dsText(15, weight: FontWeight.w600)),
                  Text(
                    everyPaper
                        ? '${bn(topic.questions)} প্রশ্ন · প্রতিটা প্রশ্নপত্রে এসেছে'
                        : '${bn(topic.questions)} প্রশ্ন · ${bn(topic.editions.length)}টি বিসিএস-এ',
                    style: dsText(12, color: AppColors.muted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text(
              topic.editions.map(bn).join(', '),
              style: dsText(
                12,
                weight: FontWeight.w600,
                color: AppColors.brand,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              LucideIcons.chevronRight,
              size: 16,
              color: AppColors.muted,
            ),
          ],
        ),
      ),
    );
  }
}
