import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/bangla_digits.dart';
import '../../../core/widgets/ds.dart';
import '../data/bcs_api.dart';
import '../data/bcs_models.dart';
import 'bcs_async.dart';

enum PaperMode { read, practice }

/// Bottom sheet that picks the mode, subject and topic before opening
/// পড়ো ও শোনো or অনুশীলন. Returns null when dismissed.
Future<(PaperMode, PaperSelection)?> showModeSheet(
  BuildContext context, {
  required int edition,
  PaperMode initialMode = PaperMode.practice,
}) {
  return showModalBottomSheet<(PaperMode, PaperSelection)>(
    context: context,
    isScrollControlled: true,
    showDragHandle: false,
    backgroundColor: AppColors.paper,
    barrierColor: const Color(0x73101216),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (_) => _ModeSheet(edition: edition, initialMode: initialMode),
  );
}

class _ModeSheet extends ConsumerStatefulWidget {
  final int edition;
  final PaperMode initialMode;

  const _ModeSheet({required this.edition, required this.initialMode});

  @override
  ConsumerState<_ModeSheet> createState() => _ModeSheetState();
}

class _ModeSheetState extends ConsumerState<_ModeSheet> {
  late PaperMode _mode = widget.initialMode;
  String _subject = 'all';
  String _topic = 'all';
  bool _wrongOnly = false;

  @override
  Widget build(BuildContext context) {
    final paper = ref.watch(bcsPaperProvider(widget.edition));
    return BcsAsync(
      value: paper,
      onRetry: () => ref.invalidate(bcsPaperProvider(widget.edition)),
      builder: (paper) =>
          SizedBox(width: double.infinity, child: _content(context, paper)),
    );
  }

  Widget _content(BuildContext context, BcsPaper paper) {
    final subjects = paper.subjects;
    final subject = subjects.firstWhere(
      (s) => s.id == _subject,
      orElse: () => subjects.first,
    );
    final mistakeIds = paper.examId == null
        ? const <String>{}
        : ref.watch(bcsMistakeIdsProvider(paper.examId!)).value ??
              const <String>{};
    final topics = [('all', 'সব topic', subject.count), ...subject.topics];
    final topic = topics.firstWhere(
      (t) => t.$1 == _topic,
      orElse: () => topics.first,
    );
    var count = topic.$3;
    if (_wrongOnly) {
      count = selectQuestions(
        paper,
        PaperSelection(
          subjectId: subject.id,
          subjectLabel: subject.label,
          topicId: topic.$1,
          topicLabel: topic.$2,
          wrongOnly: false,
          count: count,
        ),
      ).where((q) => mistakeIds.contains(q.question.id)).length;
    }

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFD6D8DC),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            DsSegmented<PaperMode>(
              height: 40,
              fontSize: 14,
              value: _mode,
              onChanged: (m) => setState(() => _mode = m),
              items: const [
                (PaperMode.read, 'পড়ো ও শোনো', null),
                (PaperMode.practice, 'অনুশীলন', null),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _mode == PaperMode.read
                  ? 'প্রশ্ন, option আর সঠিক উত্তর একসাথে। চাইলে শুনে শুনে পড়ো।'
                  : 'নিজে দাগাও, সাথে সাথে ঠিক/ভুল আর ব্যাখ্যা দেখবে।',
              style: dsText(13, color: AppColors.ink2),
            ),
            const SizedBox(height: 16),
            Text(
              'বিষয়',
              style: dsText(13, weight: FontWeight.w600, color: AppColors.ink2),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final s in subjects)
                  DsChip(
                    label: s.label,
                    selected: s.id == _subject,
                    onTap: () => setState(() {
                      _subject = s.id;
                      _topic = 'all';
                    }),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Topic',
              style: dsText(13, weight: FontWeight.w600, color: AppColors.ink2),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final t in topics)
                  DsChip(
                    label: t.$2,
                    selected: t.$1 == topic.$1,
                    onTap: () => setState(() => _topic = t.$1),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Material(
              color: AppColors.canvas,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => setState(() => _wrongOnly = !_wrongOnly),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 44),
                  child: Row(
                    children: [
                      Checkbox(
                        value: _wrongOnly,
                        activeColor: AppColors.brand,
                        onChanged: (v) =>
                            setState(() => _wrongOnly = v ?? false),
                      ),
                      Expanded(
                        child: Text(
                          'শুধু যেগুলো আগে ভুল করেছি',
                          style: dsText(14),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            DsButton(
              label: count == 0
                  ? 'এখানে কোনো প্রশ্ন নেই'
                  : 'শুরু করো · ${bn(count)}টি প্রশ্ন',
              height: 50,
              fontSize: 16,
              onPressed: count == 0
                  ? null
                  : () => Navigator.of(context).pop((
                      _mode,
                      PaperSelection(
                        subjectId: subject.id,
                        subjectLabel: subject.id == 'all'
                            ? 'সব বিষয়'
                            : subject.label,
                        topicId: topic.$1,
                        topicLabel: topic.$2,
                        wrongOnly: _wrongOnly,
                        count: count,
                      ),
                    )),
            ),
            const SizedBox(height: 8),
            Text(
              'এটা মেধাতালিকায় যাবে না, শুধু তোমার অগ্রগতিতে গোনা হবে',
              textAlign: TextAlign.center,
              style: dsText(12, color: AppColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}
