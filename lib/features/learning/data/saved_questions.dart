import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/models/paginated_list.dart';
import '../../../core/riverpod/paged_notifier.dart';
import '../../../core/riverpod/paged_state.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/controllers/auth_controller.dart';
import 'learning_models.dart';

/// Saved (bookmarked) questions: the ids drive the star on every question
/// card, the paged list drives the সংরক্ষিত page.
class SavedIdsNotifier extends AsyncNotifier<Set<String>> {
  @override
  Future<Set<String>> build() async {
    final json = await ref
        .read(accountApiServiceProvider)
        .getApiJson('/v1/users/me/saved/ids');
    final ids = (json as Map)['ids'] as List? ?? const [];
    return {for (final id in ids) id as String};
  }

  /// Flips the star at once and undoes it if the server says no. Returns
  /// false when it had to undo.
  Future<bool> toggle(String questionId) async {
    final current = {...?state.value};
    final wasSaved = current.contains(questionId);
    final next = {...current};
    wasSaved ? next.remove(questionId) : next.add(questionId);
    state = AsyncData(next);
    final api = ref.read(accountApiServiceProvider);
    final path = '/v1/users/me/saved/${Uri.encodeComponent(questionId)}';
    try {
      if (wasSaved) {
        await api.deleteApiJson(path);
      } else {
        await api.putApiJson(path, const {});
      }
      ref.invalidate(savedQuestionsProvider);
      return true;
    } catch (_) {
      state = AsyncData(current);
      return false;
    }
  }
}

final savedIdsProvider = AsyncNotifierProvider<SavedIdsNotifier, Set<String>>(
  SavedIdsNotifier.new,
);

class SavedQuestionsNotifier extends PagedNotifier<MistakeQuestion> {
  @override
  Future<PaginatedList<MistakeQuestion>> fetchPage(
    int limit,
    int offset,
  ) async {
    final json = await ref
        .read(accountApiServiceProvider)
        .getApiJson(
          '/v1/users/me/saved',
          query: {'limit': '$limit', 'offset': '$offset'},
        );
    return PaginatedList.fromJson(json, MistakeQuestion.fromJson);
  }
}

final savedQuestionsProvider =
    NotifierProvider<SavedQuestionsNotifier, PagedState<MistakeQuestion>>(
      SavedQuestionsNotifier.new,
    );

/// The bookmark next to a question's speaker button.
class SaveQuestionButton extends ConsumerWidget {
  final String questionId;

  const SaveQuestionButton({super.key, required this.questionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saved = ref.watch(savedIdsProvider).value?.contains(questionId);
    final isSaved = saved ?? false;
    return IconButton(
      visualDensity: VisualDensity.compact,
      tooltip: isSaved ? 'সংরক্ষণ থেকে সরাও' : 'প্রশ্নটা সংরক্ষণ করো',
      icon: Icon(
        isSaved ? Icons.bookmark : LucideIcons.bookmark,
        size: 22,
        color: isSaved ? AppColors.brand : AppColors.muted,
      ),
      onPressed: saved == null
          ? null
          : () async {
              final ok = await ref
                  .read(savedIdsProvider.notifier)
                  .toggle(questionId);
              if (!ok && context.mounted) {
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    const SnackBar(
                      content: Text('সংরক্ষণ করা যায়নি, আবার চেষ্টা করো'),
                    ),
                  );
              }
            },
    );
  }
}
