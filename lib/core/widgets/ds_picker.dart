import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/bangla_digits.dart';
import 'ds.dart';

/// A labelled row showing the current choice, its count and a chevron;
/// tapping it opens a list (see [showDsPicker]). [hint] replaces the value
/// when the row can't be used yet.
class DsPickerRow extends StatelessWidget {
  final String label;
  final String value;
  final int count;
  final String? hint;
  final VoidCallback? onTap;

  const DsPickerRow({
    required this.label,
    required this.value,
    required this.count,
    this.hint,
    this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: dsText(13, weight: FontWeight.w600, color: AppColors.ink2),
        ),
        const SizedBox(height: 6),
        Material(
          color: enabled ? AppColors.paper : AppColors.canvas,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppColors.lineStrong),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 50),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        hint ?? value,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: dsText(
                          15,
                          weight: hint == null
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: hint == null ? AppColors.ink : AppColors.muted,
                        ),
                      ),
                    ),
                    if (hint == null) ...[
                      const SizedBox(width: 8),
                      Text(
                        '${bn(count)}টি',
                        style: dsText(13, color: AppColors.muted),
                      ),
                    ],
                    if (enabled) ...[
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.chevron_right,
                        size: 22,
                        color: AppColors.muted,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Bottom sheet listing (id, label, count) choices with a check on
/// [selected]. Returns the picked id, or null when dismissed.
Future<String?> showDsPicker(
  BuildContext context, {
  required String title,
  required String selected,
  required List<(String, String, int)> items,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    constraints: BoxConstraints(
      maxHeight: MediaQuery.sizeOf(context).height * 0.75,
    ),
    backgroundColor: AppColors.paper,
    barrierColor: const Color(0x40101216),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (context) => SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
            child: Text(title, style: dsText(17, weight: FontWeight.w700)),
          ),
          const Divider(height: 1, color: AppColors.line),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 4),
              itemCount: items.length,
              separatorBuilder: (_, _) => const Divider(
                height: 1,
                indent: 16,
                endIndent: 16,
                color: AppColors.line,
              ),
              itemBuilder: (context, i) {
                final (id, label, count) = items[i];
                final on = id == selected;
                return InkWell(
                  onTap: () => Navigator.of(context).pop(id),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 52),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              label,
                              style: dsText(
                                15,
                                weight: on ? FontWeight.w700 : FontWeight.w400,
                                color: on ? AppColors.brand : AppColors.ink,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${bn(count)}টি',
                            style: dsText(13, color: AppColors.muted),
                          ),
                          SizedBox(
                            width: 30,
                            child: on
                                ? const Icon(
                                    Icons.check,
                                    size: 20,
                                    color: AppColors.brand,
                                  )
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    ),
  );
}
