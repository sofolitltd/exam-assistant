import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/ds.dart';

/// Loading and error states for the BCS screens that read the API.
///
/// With [title] it renders a full page (header + body); without, just the
/// body, for use inside an existing layout.
class BcsAsync<T> extends StatelessWidget {
  final AsyncValue<T> value;
  final Widget Function(T data) builder;
  final VoidCallback? onRetry;
  final String? title;

  const BcsAsync({
    required this.value,
    required this.builder,
    this.onRetry,
    this.title,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return value.when(
      skipLoadingOnRefresh: true,
      data: builder,
      loading: () => _page(
        const Center(child: CircularProgressIndicator(color: AppColors.brand)),
      ),
      error: (error, _) => _page(
        Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  bcsErrorText(error),
                  textAlign: TextAlign.center,
                  style: dsText(14, color: AppColors.ink2, height: 1.5),
                ),
                if (onRetry != null) ...[
                  const SizedBox(height: 14),
                  DsSmallButton(label: 'আবার চেষ্টা করো', onPressed: onRetry!),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _page(Widget body) {
    if (title == null) return SizedBox(height: 220, child: body);
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: DsHeader(title: title!),
      body: body,
    );
  }
}

String bcsErrorText(Object error) {
  final text = error.toString();
  if (text.startsWith('এই')) return text;
  return 'তথ্য আনা যায়নি। ইন্টারনেট সংযোগ দেখে আবার চেষ্টা করো।';
}

/// No question matches the picked subject/topic (or no mistakes left).
class BcsEmptySelection implements Exception {
  const BcsEmptySelection();

  @override
  String toString() => 'এই বাছাইয়ে কোনো প্রশ্ন নেই।';
}
