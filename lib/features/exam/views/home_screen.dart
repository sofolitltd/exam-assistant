import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/responsive_wrapper.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../learning/widgets/learning_shortcuts.dart';
import '../controllers/exam_controller.dart';
import '../data/models/exam_model.dart';
import '../data/services/exam_api_service.dart';
import '../data/services/taxonomy_api_service.dart';

class _ExamWithCount {
  final ExamModel exam;
  final int questionCount;

  const _ExamWithCount(this.exam, this.questionCount);
}

final recentExamsProvider = FutureProvider<List<_ExamWithCount>>((ref) async {
  final service = ExamApiService(
    accountApi: ref.watch(accountApiServiceProvider),
  );
  final exams = await service.getRecentExams(5, publishedOnly: true);
  return exams.map((exam) => _ExamWithCount(exam, exam.questionCount)).toList();
});

final taxonomyProgramsProvider = FutureProvider((ref) {
  return TaxonomyApiService(
    accountApi: ref.watch(accountApiServiceProvider),
  ).getPrograms();
});

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String? _expandedExamId;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final examsAsync = ref.watch(recentExamsProvider);
    final programsAsync = ref.watch(taxonomyProgramsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F8F7),
      body: SafeArea(
        child: ResponsiveWrapper(
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildTopBar(context),
                    const SizedBox(height: 24),
                    _buildSectionHeader(
                      title: 'Find your exam',
                      subtitle: 'Choose a program to explore its syllabus.',
                      trailing: programsAsync.whenOrNull(
                        data: (programs) => _CountBadge(
                          count: programs.length,
                          label: 'programs',
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _buildSearchField(),
                    const SizedBox(height: 14),
                    const LearningShortcuts(),
                    const SizedBox(height: 14),
                    programsAsync.when(
                      data: (programs) {
                        final filteredPrograms = programs.where((program) {
                          final query = _searchQuery.trim().toLowerCase();
                          return query.isEmpty ||
                              program.code.toLowerCase().contains(query) ||
                              program.name.toLowerCase().contains(query);
                        }).toList();

                        if (programs.isEmpty) {
                          return _EmptyState(
                            icon: LucideIcons.bookOpen,
                            title: 'Exam programs are on the way',
                            message:
                                'There are no programs to explore right now.',
                          );
                        }
                        if (filteredPrograms.isEmpty) {
                          return _EmptyState(
                            icon: LucideIcons.search,
                            title: 'No matching exams',
                            message: 'Try another exam name or program code.',
                          );
                        }
                        return LayoutBuilder(
                          builder: (context, constraints) {
                            final columns = constraints.maxWidth >= 620 ? 2 : 1;
                            final rows = <Widget>[];
                            for (
                              var index = 0;
                              index < filteredPrograms.length;
                              index += columns
                            ) {
                              final rowPrograms = filteredPrograms
                                  .skip(index)
                                  .take(columns)
                                  .toList();
                              rows.add(
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    for (
                                      var itemIndex = 0;
                                      itemIndex < rowPrograms.length;
                                      itemIndex++
                                    ) ...[
                                      if (itemIndex > 0)
                                        const SizedBox(width: 12),
                                      Expanded(
                                        child: _ProgramCard(
                                          program: rowPrograms[itemIndex],
                                          index: index + itemIndex,
                                        ),
                                      ),
                                    ],
                                    if (rowPrograms.length < columns)
                                      const Spacer(),
                                  ],
                                ),
                              );
                              if (index + columns < filteredPrograms.length) {
                                rows.add(const SizedBox(height: 12));
                              }
                            }
                            return Column(children: rows);
                          },
                        );
                      },
                      loading: () => const _LoadingPanel(
                        label: 'Loading exam programs...',
                      ),
                      error: (error, _) => _ErrorPanel(
                        message: 'Could not load exam programs.',
                        onRetry: () => ref.invalidate(taxonomyProgramsProvider),
                      ),
                    ),
                    const SizedBox(height: 30),
                    _buildSectionHeader(
                      title: 'Latest exams',
                      subtitle: 'Review the details before you begin.',
                      trailing: TextButton(
                        onPressed: () => context.push('/all-exams'),
                        child: const Text('View all'),
                      ),
                    ),
                    const SizedBox(height: 14),
                    examsAsync.when(
                      data: (exams) {
                        if (exams.isEmpty) {
                          return _EmptyState(
                            icon: LucideIcons.fileQuestion,
                            title: 'No exams available yet',
                            message:
                                'Published exams will appear here when ready.',
                          );
                        }
                        return Column(
                          children: exams
                              .map(
                                (item) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _ExamCard(
                                    item: item,
                                    isExpanded:
                                        _expandedExamId == item.exam.examId,
                                    onTap: () => setState(
                                      () => _expandedExamId =
                                          _expandedExamId == item.exam.examId
                                          ? null
                                          : item.exam.examId,
                                    ),
                                    onStart: () =>
                                        _startExam(context, item.exam),
                                    onViewAnswerKey: () => context.push(
                                      '/exam/${item.exam.examId}/answers'
                                      '?title=${Uri.encodeQueryComponent(item.exam.title)}',
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        );
                      },
                      loading: () => const _LoadingPanel(
                        label: 'Loading the latest exams...',
                      ),
                      error: (error, _) => _ErrorPanel(
                        message: 'Could not load the latest exams.',
                        onRetry: () => ref.invalidate(recentExamsProvider),
                      ),
                    ),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            LucideIcons.graduationCap,
            color: Colors.white,
            size: 23,
          ),
        ),
        const SizedBox(width: 11),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'EXAM ASSISTANT',
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.15,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Your study space',
                style: TextStyle(
                  color: Color(0xFF687773),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Profile',
          onPressed: () => context.go('/profile'),
          style: IconButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: AppTheme.primaryColor,
            fixedSize: const Size(44, 44),
          ),
          icon: const Icon(LucideIcons.userRound, size: 20),
        ),
      ],
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required String subtitle,
    Widget? trailing,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF1E302C),
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Color(0xFF71807C),
                  fontSize: 12,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      onChanged: (value) => setState(() => _searchQuery = value),
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Search exam name or code',
        prefixIcon: const Icon(LucideIcons.search, size: 19),
        suffixIcon: _searchQuery.isEmpty
            ? null
            : IconButton(
                tooltip: 'Clear search',
                onPressed: () {
                  _searchController.clear();
                  setState(() => _searchQuery = '');
                },
                icon: const Icon(Icons.close, size: 18),
              ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Color(0xFFE3EAE7)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Color(0xFFE3EAE7)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(
            color: AppTheme.primaryColor,
            width: 1.5,
          ),
        ),
      ),
    );
  }

  Future<void> _startExam(BuildContext context, ExamModel exam) async {
    try {
      final questions = await ExamApiService(
        accountApi: ref.read(accountApiServiceProvider),
      ).getExamQuestions(exam.examId);
      if (!context.mounted) return;
      if (questions.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No questions in this exam')),
        );
        return;
      }
      ref.read(examControllerProvider.notifier).startExam(exam, questions);
      context.push('/exam/${exam.examId}');
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not start this exam: $error')),
      );
    }
  }
}

class _ProgramCard extends StatelessWidget {
  final ExamProgram program;
  final int index;

  const _ProgramCard({required this.program, required this.index});

  static const _colors = [
    Color(0xFFEAF4EF),
    Color(0xFFEEF0FA),
    Color(0xFFFFF3E7),
    Color(0xFFE9F3F6),
  ];

  @override
  Widget build(BuildContext context) {
    final color = _colors[index % _colors.length];
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => context.push('/program/${program.programId}'),
        child: Container(
          constraints: const BoxConstraints(minHeight: 92),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE8EEEB)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  LucideIcons.bookOpen,
                  color: AppTheme.primaryColor,
                  size: 21,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      program.code,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF273A35),
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      program.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF76827F),
                        fontSize: 12,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 5),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: Color(0xFF91A09B),
                size: 15,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExamCard extends StatelessWidget {
  final _ExamWithCount item;
  final bool isExpanded;
  final VoidCallback onTap;
  final VoidCallback onStart;
  final VoidCallback onViewAnswerKey;

  const _ExamCard({
    required this.item,
    required this.isExpanded,
    required this.onTap,
    required this.onStart,
    required this.onViewAnswerKey,
  });

  @override
  Widget build(BuildContext context) {
    final exam = item.exam;
    final durationMinutes = exam.durationSeconds ~/ 60;
    final duration = durationMinutes >= 60
        ? '${durationMinutes ~/ 60}h ${durationMinutes % 60}m'
        : '$durationMinutes min';

    return AnimatedSize(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOut,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE6ECE9)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF4EF),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        LucideIcons.fileText,
                        color: AppTheme.primaryColor,
                        size: 21,
                      ),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            exam.title.isEmpty ? 'Untitled exam' : exam.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF253631),
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 7),
                          Wrap(
                            spacing: 12,
                            runSpacing: 5,
                            children: [
                              _InlineInfo(
                                icon: LucideIcons.clock3,
                                label: duration,
                              ),
                              _InlineInfo(
                                icon: LucideIcons.listChecks,
                                label: '${item.questionCount} questions',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    AnimatedRotation(
                      turns: isExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 180),
                      child: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: Color(0xFF75847F),
                      ),
                    ),
                  ],
                ),
                if (isExpanded) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Divider(height: 1, color: Color(0xFFEDF1EF)),
                  ),
                  _DetailRow(
                    icon: LucideIcons.timer,
                    label: 'Time limit',
                    value: '$durationMinutes minutes',
                  ),
                  const SizedBox(height: 11),
                  _DetailRow(
                    icon: LucideIcons.circleHelp,
                    label: 'Questions',
                    value: '${item.questionCount}',
                  ),
                  const SizedBox(height: 11),
                  _DetailRow(
                    icon: LucideIcons.circleMinus,
                    label: 'Negative marking',
                    value: '${exam.negativeMarks} per wrong answer',
                  ),
                  if (exam.scheduledDate != null) ...[
                    const SizedBox(height: 11),
                    _DetailRow(
                      icon: LucideIcons.calendarDays,
                      label: 'Scheduled',
                      value: _formatDate(exam.scheduledDate!),
                    ),
                  ],
                  const SizedBox(height: 16),
                  if (exam.hasEnded) ...[
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: onViewAnswerKey,
                        icon: const Icon(LucideIcons.bookOpenCheck, size: 17),
                        label: const Text('View full answer key'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(13),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: onStart,
                        icon: const Icon(LucideIcons.play, size: 17),
                        label: const Text('Retake exam'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.primaryColor,
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(13),
                          ),
                        ),
                      ),
                    ),
                  ] else
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: onStart,
                        icon: const Icon(LucideIcons.play, size: 17),
                        label: const Text('Start exam'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(13),
                          ),
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';
}

class _InlineInfo extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InlineInfo({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: const Color(0xFF82908C)),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Color(0xFF71807B)),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 17, color: AppTheme.primaryColor),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, color: Color(0xFF687772)),
          ),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF33443F),
            ),
          ),
        ),
      ],
    );
  }
}

class _CountBadge extends StatelessWidget {
  final int count;
  final String label;

  const _CountBadge({required this.count, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF2EE),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        '$count $label',
        style: const TextStyle(
          color: AppTheme.primaryColor,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8EEEB)),
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF80918B), size: 25),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF33443F),
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF788681),
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingPanel extends StatelessWidget {
  final String label;

  const _LoadingPanel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: const TextStyle(color: Color(0xFF73817D), fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _ErrorPanel extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorPanel({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8EEEB)),
      ),
      child: Row(
        children: [
          const Icon(
            LucideIcons.circleAlert,
            color: Color(0xFFB85444),
            size: 21,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Color(0xFF5E6C67), fontSize: 13),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
