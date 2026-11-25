import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/bangla_digits.dart';
import '../../../core/widgets/ds.dart';
import '../controllers/learning_providers.dart';
import '../data/learning_models.dart';

/// আজকের রিভিশন: wrong answers that are due again, one question at a time.
/// The learner commits to an answer first; the server then grades it and
/// reschedules the card (1, 3, 7, 15, 30 days; a wrong answer starts over).
class ReviewScreen extends ConsumerStatefulWidget {
  const ReviewScreen({super.key});

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  int _index = 0;
  int _right = 0;
  int _answered = 0;
  String? _picked;
  ReviewAnswerResult? _result;
  bool _saving = false;
  String? _error;
  ProviderContainer? _container;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _container = ProviderScope.containerOf(context, listen: false);
  }

  @override
  void dispose() {
    // Review answers count in mistakes and stats too.
    if (_answered > 0 && _container != null) refreshLearningData(_container!);
    super.dispose();
  }

  Future<void> _pick(ReviewQuestion q, String key) async {
    if (_saving || _result != null) return;
    setState(() {
      _picked = key;
      _saving = true;
      _error = null;
    });
    try {
      final result = await ref
          .read(learningApiServiceProvider)
          .answerReview(questionId: q.id, selectedKey: key);
      if (!mounted) return;
      setState(() {
        _result = result;
        _saving = false;
        _answered++;
        if (result.isCorrect) _right++;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _picked = null;
        _saving = false;
        _error = 'সংরক্ষণ করা যায়নি। আবার চেষ্টা করো।';
      });
    }
  }

  void _next() => setState(() {
    _index++;
    _picked = null;
    _result = null;
  });

  OptionState _stateOf(String key) {
    final result = _result;
    if (result == null) {
      return key == _picked ? OptionState.picked : OptionState.idle;
    }
    if (result.correctOptionKeys.contains(key)) return OptionState.correct;
    if (key == _picked) return OptionState.wrong;
    return OptionState.dimmed;
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(dueReviewsProvider);
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: const DsHeader(title: 'আজকের রিভিশন'),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(
          child: DsButton(
            label: 'আবার চেষ্টা করো',
            onPressed: () => ref.invalidate(dueReviewsProvider),
          ),
        ),
        data: _body,
      ),
    );
  }

  Widget _body(DueReviews data) {
    final items = data.items;
    if (items.isEmpty || _index >= items.length) {
      return _finished(data);
    }
    final q = items[_index];
    final result = _result;
    return DsPage(
      children: [
        Text(
          'প্রশ্ন ${bn(_index + 1)} / ${bn(items.length)}'
          ' · বক্স ${bn(q.box + 1)}',
          style: dsText(12, color: AppColors.muted),
        ),
        DsCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(q.questionText, style: dsText(16, height: 1.5)),
              const SizedBox(height: 14),
              for (final o in q.options) ...[
                OptionTile(
                  badge: o.key,
                  label: o.value,
                  state: _stateOf(o.key),
                  onTap: () => _pick(q, o.key),
                ),
                const SizedBox(height: 8),
              ],
            ],
          ),
        ),
        if (_error != null)
          Text(_error!, style: dsText(13, color: AppColors.danger)),
        if (result != null) ...[
          DsCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result.isCorrect ? 'ঠিক হয়েছে' : 'ভুল হয়েছে',
                  style: dsText(
                    15,
                    weight: FontWeight.w700,
                    color: result.isCorrect
                        ? AppColors.success
                        : AppColors.danger,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  result.mastered
                      ? 'প্রশ্নটা তোমার আয়ত্তে। আর দেখানো হবে না।'
                      : result.isCorrect
                      ? 'আবার আসবে ${_inDays(result.nextDueAt)}।'
                      : 'শুরু থেকে আবার আসবে ${_inDays(result.nextDueAt)}।',
                  style: dsText(13, color: AppColors.muted),
                ),
                if (result.explanation?.isNotEmpty ?? false) ...[
                  const SizedBox(height: 8),
                  Text(
                    result.explanation!,
                    style: dsText(14, height: 1.55, color: AppColors.ink2),
                  ),
                ],
              ],
            ),
          ),
          DsButton(
            label: _index + 1 < items.length ? 'পরের প্রশ্ন' : 'শেষ করো',
            onPressed: _next,
          ),
        ],
      ],
    );
  }

  String _inDays(DateTime? due) {
    if (due == null) return '';
    final days = due.difference(DateTime.now()).inHours / 24;
    final rounded = days < 1 ? 1 : days.round();
    return '${bn(rounded)} দিন পর';
  }

  Widget _finished(DueReviews data) {
    final remaining = data.summary.due - _answered;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _answered == 0 ? 'আজ রিভিশনের কিছু বাকি নেই' : 'আজকের রিভিশন শেষ',
              style: dsText(18, weight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            if (_answered > 0)
              Text(
                '${bn(_right)} / ${bn(_answered)}টি ঠিক হয়েছে',
                style: dsText(14, color: AppColors.ink2),
              ),
            if (remaining > 0) ...[
              const SizedBox(height: 6),
              Text(
                'আরও ${bn(remaining)}টি বাকি আছে',
                style: dsText(13, color: AppColors.muted),
              ),
            ],
            const SizedBox(height: 16),
            if (remaining > 0)
              DsButton(
                label: 'আরও রিভিশন করো',
                onPressed: () {
                  setState(() {
                    _index = 0;
                    _picked = null;
                    _result = null;
                  });
                  ref.invalidate(dueReviewsProvider);
                },
              )
            else
              DsButton(label: 'ফিরে যাও', onPressed: () => context.pop()),
          ],
        ),
      ),
    );
  }
}
