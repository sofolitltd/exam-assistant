import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/bangla_digits.dart';
import '../../../core/widgets/responsive_wrapper.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../dashboard/controllers/stats_controller.dart';
import '../../learning/controllers/learning_providers.dart';
import '../../learning/data/learning_models.dart';
import '../../learning/widgets/review_question_card.dart';
import '../controllers/exam_controller.dart';
import '../data/models/question_model.dart';
import '../data/services/exam_api_service.dart';
import '../services/question_tts_service.dart';
import '../widgets/question_playback_bar.dart';

/// Shows the server-graded result of the exam just finished. Correct answers
/// arrive only from the server — the live exam never receives them — so the
/// review section loads the answer key once the exam's window has closed.
class ResultScreen extends ConsumerStatefulWidget {
  const ResultScreen({super.key});

  @override
  ConsumerState<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends ConsumerState<ResultScreen> {
  ExamSubmission? _submission;
  String? _submitError;
  bool _submitting = false;
  List<QuestionModel>? _review;
  String? _reviewError;
  String _selectedSubject = 'All';
  List<GlobalKey> _itemKeys = const [];
  int? _activeIndex;

  late final QuestionTtsService _tts;

  @override
  void initState() {
    super.initState();
    _tts = ref.read(questionTtsServiceProvider);
    Future.microtask(_submit);
  }

  Future<void> _submit() async {
    final quizState = ref.read(examControllerProvider);
    final exam = quizState.currentExam;
    final questions = quizState.questions;
    if (exam == null || questions == null || _submitting) return;

    setState(() {
      _submitting = true;
      _submitError = null;
    });
    final answers = <String, String>{};
    for (var index = 0; index < questions.length; index++) {
      final answer = quizState.selectedOptions[index];
      if (answer != null) answers[questions[index].id] = answer;
    }
    try {
      final json = await ref
          .read(accountApiServiceProvider)
          .submitExamResult(examId: exam.examId, answers: answers);
      ref.invalidate(userExamResultsProvider);
      ref.invalidate(userProfileProvider);
      if (mounted) {
        refreshLearningData(ProviderScope.containerOf(context, listen: false));
      }
      if (!mounted) return;
      final submission = ExamSubmission.fromJson(json);
      setState(() => _submission = submission);
      if (submission.answersAvailable) await _loadReview(exam.examId);
    } catch (error) {
      if (mounted) setState(() => _submitError = '$error');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _loadReview(String examId) async {
    try {
      final review = await ExamApiService(
        accountApi: ref.read(accountApiServiceProvider),
      ).getExamAnswerKey(examId);
      if (mounted) setState(() => _review = review);
    } catch (error) {
      if (mounted) setState(() => _reviewError = '$error');
    }
  }

  @override
  void dispose() {
    // Stop reading aloud when leaving the screen; otherwise playback
    // continues with no control left to stop it.
    _tts.stop();
    super.dispose();
  }

  void _handleActiveIndexChanged(int? index) {
    if (!mounted) return;
    setState(() => _activeIndex = index);
    if (index == null || index >= _itemKeys.length) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final itemContext = _itemKeys[index].currentContext;
      if (itemContext != null) {
        Scrollable.ensureVisible(
          itemContext,
          duration: const Duration(milliseconds: 300),
          alignment: 0.1,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final quizState = ref.watch(examControllerProvider);
    final exam = quizState.currentExam;
    final questions = quizState.questions;
    if (exam == null || questions == null) {
      return const Scaffold(body: Center(child: Text('No Data')));
    }

    final selectedById = <String, String>{
      for (var i = 0; i < questions.length; i++)
        if (quizState.selectedOptions[i] != null)
          questions[i].id: quizState.selectedOptions[i]!,
    };
    final review = _review ?? const <QuestionModel>[];
    final subjects = <String>{
      'All',
      for (final q in review)
        if (q.subject.isNotEmpty) q.subject,
    }.toList()..sort();
    final displayed = _selectedSubject == 'All'
        ? review
        : review.where((q) => q.subject == _selectedSubject).toList();
    if (_itemKeys.length != displayed.length) {
      _itemKeys = List.generate(displayed.length, (_) => GlobalKey());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('পরীক্ষার ফলাফল'),
        actions: [
          if (displayed.isNotEmpty)
            QuestionPlaybackBar(
              questions: displayed,
              onActiveIndexChanged: _handleActiveIndexChanged,
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: ResponsiveWrapper(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_submission == null && _submitError == null)
                  const _StatusCard(
                    icon: Icons.hourglass_top,
                    message: 'তোমার রেজাল্ট হিসাব হচ্ছে...',
                    loading: true,
                  )
                else if (_submission == null)
                  _StatusCard(
                    icon: Icons.cloud_off,
                    message: 'রেজাল্ট সেভ করা যায়নি: $_submitError',
                    action: TextButton(
                      onPressed: _submitting ? null : _submit,
                      child: const Text('আবার চেষ্টা করো'),
                    ),
                  )
                else ...[
                  _ScoreCard(
                    submission: _submission!,
                    negativeMarks: exam.negativeMarks,
                    secondsTaken:
                        exam.durationSeconds - quizState.remainingSeconds,
                  ),
                  if (_submission!.rank != null) ...[
                    const SizedBox(height: 14),
                    _RankCard(
                      rank: _submission!.rank!,
                      onOpenLeaderboard: () => context.push(
                        '/exam/${exam.examId}/leaderboard'
                        '?title=${Uri.encodeQueryComponent(exam.title)}',
                      ),
                    ),
                  ],
                  const SizedBox(height: 22),
                  if (!_submission!.answersAvailable)
                    _StatusCard(
                      icon: Icons.lock_clock,
                      message:
                          'পরীক্ষার সময় এখনো চলছে, তাই সঠিক উত্তর ও ব্যাখ্যা '
                          '${_formatTime(_submission!.answersAvailableAt)} এর পর দেখা যাবে।',
                    )
                  else if (_reviewError != null)
                    _StatusCard(
                      icon: Icons.error_outline,
                      message: 'উত্তরপত্র লোড করা যায়নি: $_reviewError',
                    )
                  else if (_review == null)
                    const _StatusCard(
                      icon: Icons.hourglass_top,
                      message: 'উত্তরপত্র লোড হচ্ছে...',
                      loading: true,
                    )
                  else ...[
                    if (_submission!.wrongCount + _submission!.skippedCount > 0)
                      FilledButton.icon(
                        onPressed: () => context.push(
                          '/practice/mistakes?examId='
                          '${Uri.encodeQueryComponent(exam.examId)}'
                          '&title=${Uri.encodeQueryComponent(exam.title)}',
                        ),
                        icon: const Icon(Icons.replay),
                        label: const Text('ভুল প্রশ্নগুলো প্র্যাকটিস করো'),
                      ),
                    const SizedBox(height: 18),
                    Text(
                      'উত্তর পর্যালোচনা',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 40,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          for (final subject in subjects)
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(subject == 'All' ? 'সব' : subject),
                                selected: subject == _selectedSubject,
                                onSelected: (_) => setState(() {
                                  _selectedSubject = subject;
                                  _activeIndex = null;
                                }),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    for (var i = 0; i < displayed.length; i++)
                      ReviewQuestionCard(
                        key: _itemKeys[i],
                        question: displayed[i],
                        index: i,
                        selectedKey: selectedById[displayed[i].id],
                        showSelection: true,
                        isActive: i == _activeIndex,
                      ),
                  ],
                ],
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: () => context.go('/home'),
                  child: const Text('হোমে ফিরে যাও'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _formatTime(DateTime? time) {
    if (time == null) return 'পরীক্ষা শেষ হওয়ার';
    final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour < 12 ? 'AM' : 'PM';
    return '${time.day}/${time.month} $hour:$minute $period';
  }
}

class _ScoreCard extends StatelessWidget {
  final ExamSubmission submission;
  final double negativeMarks;
  final int secondsTaken;

  const _ScoreCard({
    required this.submission,
    required this.negativeMarks,
    required this.secondsTaken,
  });

  @override
  Widget build(BuildContext context) {
    final negative = submission.wrongCount * negativeMarks;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.heroSoft, AppColors.hero],
        ),
        borderRadius: BorderRadius.circular(AppRadii.xl),
      ),
      child: Column(
        children: [
          Text(
            'মোট নম্বর',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
          ),
          const SizedBox(height: 4),
          Text(
            submission.score.toStringAsFixed(2),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 44,
              fontWeight: FontWeight.w700,
              height: 1.1,
            ),
          ),
          Text(
            '${toBanglaNumber(submission.totalQuestions)} প্রশ্নের মধ্যে',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _Stat(
                'সঠিক',
                '${submission.correctCount}',
                const Color(0xFF7BE0B5),
              ),
              _Stat('ভুল', '${submission.wrongCount}', const Color(0xFFFF9A93)),
              _Stat('বাদ', '${submission.skippedCount}', Colors.white70),
              _Stat(
                'নেগেটিভ',
                '-${negative.toStringAsFixed(2)}',
                AppColors.accent,
              ),
              _Stat(
                'সময়',
                '${secondsTaken ~/ 60}m ${secondsTaken % 60}s',
                Colors.white70,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _Stat(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _RankCard extends StatelessWidget {
  final ExamRankInfo rank;
  final VoidCallback onOpenLeaderboard;

  const _RankCard({required this.rank, required this.onOpenLeaderboard});

  @override
  Widget build(BuildContext context) {
    final notes = <String>[
      if (rank.provisional) 'পরীক্ষা এখনো চলছে, তাই র‍্যাঙ্ক বদলাতে পারে।',
      if (!rank.isFirstAttempt)
        'র‍্যাঙ্ক হিসাব হয় প্রথমবারের রেজাল্ট দিয়ে (নম্বর: ${rank.score.toStringAsFixed(2)})।',
    ];
    return Container(
      padding: const EdgeInsets.all(16),
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
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.accentSoft,
                  borderRadius: BorderRadius.circular(AppRadii.md),
                ),
                child: Text(
                  '#${toBanglaNumber(rank.rank)}',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFB4730F),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${toBanglaNumber(rank.participants)} জনের মধ্যে',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      rank.participants > 1
                          ? 'তুমি ${toBanglaNumber(rank.percentile.round())}% পরীক্ষার্থীর চেয়ে ভালো করেছো'
                          : 'এখন পর্যন্ত তুমিই একমাত্র পরীক্ষার্থী',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          for (final note in notes) ...[
            const SizedBox(height: 8),
            Text(note, style: Theme.of(context).textTheme.bodySmall),
          ],
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onOpenLeaderboard,
              icon: const Icon(Icons.leaderboard_outlined, size: 18),
              label: const Text('লিডারবোর্ড দেখো'),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final IconData icon;
  final String message;
  final bool loading;
  final Widget? action;

  const _StatusCard({
    required this.icon,
    required this.message,
    this.loading = false,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        children: [
          Row(
            children: [
              if (loading)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Icon(icon, color: AppColors.muted),
              const SizedBox(width: 12),
              Expanded(child: Text(message)),
            ],
          ),
          ?action,
        ],
      ),
    );
  }
}
