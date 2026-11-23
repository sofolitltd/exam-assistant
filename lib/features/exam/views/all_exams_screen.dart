import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/bangla_digits.dart';
import '../../../core/widgets/ds.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../bcs/views/bcs_format.dart';
import '../controllers/exam_controller.dart';
import '../data/models/exam_model.dart';
import '../data/services/exam_api_service.dart';

/// Every published exam the admin has made (job solutions, model tests).
final allExamsProvider = FutureProvider<List<ExamModel>>((ref) async {
  final service = ExamApiService(
    accountApi: ref.watch(accountApiServiceProvider),
  );
  return service.getExams(publishedOnly: true);
});

/// জব সল্যুশন: the list of published exams; a tap opens a sheet to start the
/// exam or, once it has ended, to read the answer key.
class AllExamsScreen extends ConsumerWidget {
  const AllExamsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final examsAsync = ref.watch(allExamsProvider);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: const DsHeader(
        title: 'জব সল্যুশন',
        subtitle: 'সব নিয়োগ পরীক্ষা',
      ),
      body: examsAsync.when(
        data: (exams) {
          if (exams.isEmpty) {
            return const _Message(
              icon: LucideIcons.fileText,
              text: 'এখনো কোনো পরীক্ষা প্রকাশ হয়নি',
            );
          }
          return RefreshIndicator(
            onRefresh: () => ref.refresh(allExamsProvider.future),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
              children: [
                SectionLabel('${bn(exams.length)}টি পরীক্ষা'),
                const SizedBox(height: 8),
                DsListCard(
                  children: [for (final e in exams) _ExamRow(exam: e)],
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => _Message(
          icon: LucideIcons.wifiOff,
          text: 'পরীক্ষার তালিকা আনা যায়নি',
          action: DsSmallButton(
            label: 'আবার চেষ্টা করো',
            onPressed: () => ref.invalidate(allExamsProvider),
          ),
        ),
      ),
    );
  }
}

String _duration(int seconds) {
  final minutes = seconds ~/ 60;
  final h = minutes ~/ 60;
  final m = minutes % 60;
  if (h == 0) return '${bn(m)} মিনিট';
  if (m == 0) return '${bn(h)} ঘণ্টা';
  return '${bn(h)} ঘণ্টা ${bn(m)} মিনিট';
}

String _meta(ExamModel exam) {
  final date = exam.heldOn ?? exam.scheduledDate ?? exam.createdAt;
  return '${bnDayMonth(date)} ${bn(date.year)} · '
      '${bn(exam.questionCount)}টি প্রশ্ন · ${_duration(exam.durationSeconds)}';
}

class _ExamRow extends ConsumerWidget {
  final ExamModel exam;

  const _ExamRow({required this.exam});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      onTap: () => _openSheet(context, ref, exam),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            const IconSquare(LucideIcons.fileText),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exam.title.isNotEmpty ? exam.title : 'নামহীন পরীক্ষা',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: dsText(15, weight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _meta(exam),
                    style: dsText(12, color: AppColors.muted),
                  ),
                ],
              ),
            ),
            if (!exam.hasEnded) ...[
              const SizedBox(width: 8),
              const LivePill('চলছে'),
            ],
            const SizedBox(width: 4),
            const Icon(
              LucideIcons.chevronRight,
              size: 18,
              color: AppColors.muted,
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _openSheet(
  BuildContext context,
  WidgetRef ref,
  ExamModel exam,
) async {
  final action = await showModalBottomSheet<String>(
    context: context,
    useSafeArea: true,
    backgroundColor: AppColors.paper,
    barrierColor: const Color(0x73101216),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (ctx) => _ExamSheet(exam: exam),
  );
  if (action == null || !context.mounted) return;

  if (action == 'answers') {
    context.push(
      '/exam/${exam.examId}/answers'
      '?title=${Uri.encodeQueryComponent(exam.title)}',
    );
    return;
  }

  final service = ExamApiService(
    accountApi: ref.read(accountApiServiceProvider),
  );
  final messenger = ScaffoldMessenger.of(context);
  try {
    final questions = await service.getExamQuestions(exam.examId);
    if (!context.mounted) return;
    if (questions.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('এই পরীক্ষায় এখনো প্রশ্ন নেই')),
      );
      return;
    }
    ref.read(examControllerProvider.notifier).startExam(exam, questions);
    context.go('/exam/${exam.examId}');
  } catch (_) {
    messenger.showSnackBar(
      const SnackBar(content: Text('প্রশ্ন আনা যায়নি। আবার চেষ্টা করো')),
    );
  }
}

class _ExamSheet extends StatelessWidget {
  final ExamModel exam;

  const _ExamSheet({required this.exam});

  @override
  Widget build(BuildContext context) {
    final negative = exam.negativeMarks == 0
        ? 'নেই'
        : '${bnScore(exam.negativeMarks)} করে';
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            exam.title.isNotEmpty ? exam.title : 'নামহীন পরীক্ষা',
            style: dsText(18, weight: FontWeight.w700, height: 1.3),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: StatBox(
                  label: 'প্রশ্ন',
                  value: bn(exam.questionCount),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: StatBox(
                  label: 'সময়',
                  value: _duration(exam.durationSeconds),
                  valueSize: 15,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: StatBox(
                  label: 'নেগেটিভ',
                  value: negative,
                  valueSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          DsButton(
            label: exam.hasEnded ? 'আবার দাও' : 'পরীক্ষা শুরু করো',
            onPressed: () => Navigator.pop(context, 'start'),
          ),
          if (exam.hasEnded) ...[
            const SizedBox(height: 8),
            DsButton.secondary(
              label: 'উত্তরপত্র দেখো',
              onPressed: () => Navigator.pop(context, 'answers'),
            ),
          ],
        ],
      ),
    );
  }
}

class _Message extends StatelessWidget {
  final IconData icon;
  final String text;
  final Widget? action;

  const _Message({required this.icon, required this.text, this.action});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: AppColors.subtle),
            const SizedBox(height: 12),
            Text(
              text,
              textAlign: TextAlign.center,
              style: dsText(15, color: AppColors.muted),
            ),
            if (action != null) ...[const SizedBox(height: 14), action!],
          ],
        ),
      ),
    );
  }
}
