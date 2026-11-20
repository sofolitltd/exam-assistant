import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/bangla_digits.dart';
import '../../../core/widgets/ds.dart';
import '../data/bcs_api.dart';
import '../data/bcs_models.dart';
import 'bcs_async.dart';
import 'bcs_format.dart';

/// Past BCS questions grouped by subject and topic, from every published
/// paper (real data, `bcsPyqIndexProvider`). Topics that appeared in more
/// BCS papers come first; a topic opens its questions from the question
/// bank.
class SubjectPyqScreen extends ConsumerStatefulWidget {
  final String? initialSubject;

  const SubjectPyqScreen({this.initialSubject, super.key});

  @override
  ConsumerState<SubjectPyqScreen> createState() => _SubjectPyqScreenState();
}

class _SubjectPyqScreenState extends ConsumerState<SubjectPyqScreen> {
  late String? _subject = widget.initialSubject;
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final index = ref.watch(bcsPyqIndexProvider);
    return BcsAsync(
      title: 'বিষয়ভিত্তিক বিগত প্রশ্ন',
      value: index,
      onRetry: () => ref.invalidate(bcsPaperExamsProvider),
      builder: (index) => index.subjects.isEmpty
          ? Scaffold(
              backgroundColor: AppColors.canvas,
              appBar: const DsHeader(title: 'বিষয়ভিত্তিক বিগত প্রশ্ন'),
              body: Center(
                child: Text(
                  'এখনো কোনো প্রশ্নপত্র যোগ করা হয়নি।',
                  style: dsText(14, color: AppColors.muted),
                ),
              ),
            )
          : _page(context, index),
    );
  }

  Widget _page(BuildContext context, PyqIndex index) {
    final subjects = index.subjects;
    final subject = subjects.firstWhere(
      (s) => s.label == _subject,
      orElse: () => subjects.first,
    );
    final all = subject.topics;
    final q = _query.toLowerCase();
    final topics = q.isEmpty
        ? all
        : all
              .where(
                (t) =>
                    t.name.toLowerCase().contains(q) ||
                    t.texts.any((x) => x.toLowerCase().contains(q)),
              )
              .toList();
    final editions = index.editions;
    final range = editions.length == 1
        ? '${bnOrdinal(editions.first)} বিসিএস'
        : '${bn(editions.first)}–${bnOrdinal(editions.last)} বিসিএস · '
              '${bn(editions.length)}টি প্রশ্নপত্র';
    final newest = editions.last;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: DsHeader(
        title: 'বিষয়ভিত্তিক বিগত প্রশ্ন',
        subtitle: range,
        bordered: false,
      ),
      body: Column(
        children: [
          Container(
            color: AppColors.paper,
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Column(
              children: [
                SizedBox(
                  height: 42,
                  child: TextField(
                    onChanged: (v) => setState(() => _query = v.trim()),
                    style: dsText(14),
                    decoration: InputDecoration(
                      hintText: 'প্রশ্ন বা topic খোঁজো',
                      hintStyle: dsText(14, color: AppColors.muted),
                      prefixIcon: const Icon(LucideIcons.search, size: 18),
                      filled: true,
                      fillColor: AppColors.sunken,
                      contentPadding: EdgeInsets.zero,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.brand),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 36,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: subjects.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 6),
                    itemBuilder: (_, i) => DsChip(
                      label: subjects[i].label,
                      selected: subjects[i].label == subject.label,
                      onTap: () => setState(() => _subject = subjects[i].label),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.line),
          Expanded(
            child: DsPage(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${bn(all.length)}টি topic · ${bn(subject.questions)} প্রশ্ন',
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
                  DsCard(
                    child: Text(
                      'এই খোঁজে কিছু পাওয়া যায়নি।',
                      style: dsText(14, color: AppColors.muted),
                    ),
                  )
                else
                  DsListCard(
                    children: [
                      for (final topic in topics)
                        _TopicRow(
                          topic: topic,
                          totalPapers: editions.length,
                          onTap: () => context.push(
                            '/taxonomy-questions/${topic.syllabusId}/${topic.nodeId}'
                            '?title=${Uri.encodeComponent(topic.name)}',
                          ),
                        ),
                    ],
                  ),
              ],
            ),
          ),
          Container(
            decoration: const BoxDecoration(
              color: AppColors.paper,
              border: Border(top: BorderSide(color: AppColors.line)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: DsGrid(
              children: [
                DsButton.secondary(
                  label: 'শুধু যেগুলো পারিনি',
                  onPressed: () => context.push('/practice/mistakes'),
                ),
                DsButton(
                  label: '${bnOrdinal(newest)} অনুশীলন',
                  fontSize: 14,
                  onPressed: () => context.push('/bcs/$newest/practice'),
                ),
              ],
            ),
          ),
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
