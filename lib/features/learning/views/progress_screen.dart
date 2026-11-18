import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/bangla_digits.dart';
import '../../../core/widgets/responsive_wrapper.dart';
import '../controllers/learning_providers.dart';
import '../data/learning_models.dart';

/// Subject-by-subject exam accuracy over the last 30 days, weakest first,
/// with one-tap practice and listen-mode for each subject.
class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final performanceAsync = ref.watch(subjectPerformanceProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('আমার অগ্রগতি')),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(subjectPerformanceProvider.future),
        child: ResponsiveWrapper(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  Expanded(
                    child: _ActionTile(
                      icon: Icons.replay,
                      label: 'ভুলগুলো প্র্যাকটিস',
                      onTap: () => context.push('/practice/mistakes'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ActionTile(
                      icon: Icons.headphones_outlined,
                      label: 'ভুলগুলো শোনো',
                      onTap: () => context.push('/listen'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'বিষয়ভিত্তিক পারফরম্যান্স',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              Text(
                'গত ৩০ দিনের শেষ হওয়া পরীক্ষা থেকে — সবচেয়ে দুর্বল বিষয় আগে।',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              performanceAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, _) => Text('লোড করা যায়নি: $error'),
                data: (subjects) {
                  if (subjects.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Text(
                        'এখনো যথেষ্ট ডেটা নেই। কয়েকটা পরীক্ষা দাও — '
                        'সিলেবাসের বিষয় অনুযায়ী তোমার দুর্বলতা এখানে দেখা যাবে।',
                      ),
                    );
                  }
                  return Column(
                    children: [
                      for (final subject in subjects)
                        _SubjectTile(subject: subject),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.paper,
      borderRadius: BorderRadius.circular(AppRadii.lg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.lg),
            border: Border.all(color: AppColors.line),
          ),
          child: Row(
            children: [
              Icon(icon, color: AppColors.brand),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SubjectTile extends StatelessWidget {
  final SubjectPerformance subject;

  const _SubjectTile({required this.subject});

  @override
  Widget build(BuildContext context) {
    final percent = (subject.accuracy * 100).round();
    final color = subject.accuracy >= 0.75
        ? AppColors.success
        : subject.accuracy >= 0.5
        ? const Color(0xFFB4730F)
        : AppColors.danger;
    final title = Uri.encodeQueryComponent(subject.name);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  subject.name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text(
                  '${toBanglaNumber(percent)}%',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: subject.accuracy,
                minHeight: 6,
                color: color,
                backgroundColor: AppColors.sunken,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${toBanglaNumber(subject.attempted)} প্রশ্ন · সঠিক ${toBanglaNumber(subject.correct)} · '
            'ভুল ${toBanglaNumber(subject.wrong)} · বাদ ${toBanglaNumber(subject.skipped)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () => context.push(
                  '/listen?syllabusId=${subject.syllabusId}'
                  '&nodeId=${subject.nodeId}&title=$title',
                ),
                icon: const Icon(Icons.headphones_outlined, size: 18),
                label: const Text('শোনো'),
              ),
              TextButton.icon(
                onPressed: () => context.push(
                  '/taxonomy-questions/${subject.syllabusId}/${subject.nodeId}'
                  '?title=$title',
                ),
                icon: const Icon(Icons.edit_note, size: 18),
                label: const Text('প্র্যাকটিস'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
