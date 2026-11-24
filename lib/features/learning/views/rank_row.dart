import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/bangla_digits.dart';
import '../../../core/widgets/ds.dart';

/// One row of a ranking list (overall and per-exam leaderboards): rank,
/// name with an optional detail line, and the score on the right. The
/// learner's own row is tinted blue.
class RankRow extends StatelessWidget {
  final int rank;
  final String name;
  final String? detail;
  final String score;
  final bool isYou;

  const RankRow({
    required this.rank,
    required this.name,
    required this.score,
    this.detail,
    this.isYou = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final top3 = rank <= 3;
    return Container(
      color: isYou ? AppColors.brandSoft : null,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: top3 ? AppColors.accentSoft : AppColors.sunken,
              shape: BoxShape.circle,
            ),
            child: Text(
              bn(rank),
              style: dsText(
                13,
                weight: FontWeight.w700,
                color: top3 ? AppColors.accent : AppColors.ink2,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isYou ? '$name (তুমি)' : name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: dsText(
                    15,
                    weight: isYou || top3 ? FontWeight.w600 : FontWeight.w500,
                    color: isYou ? AppColors.brandStrong : AppColors.ink,
                  ),
                ),
                if (detail != null)
                  Text(detail!, style: dsText(12, color: AppColors.muted)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            score,
            style: dsText(
              16,
              weight: FontWeight.w700,
              color: isYou ? AppColors.brandStrong : AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}

/// Centered icon + message (+ optional button) for empty and error states,
/// inside a scroll view so pull to refresh still works.
class RankMessage extends StatelessWidget {
  final IconData icon;
  final String text;
  final Widget? action;

  const RankMessage({
    required this.icon,
    required this.text,
    this.action,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 96, 24, 24),
      children: [
        Icon(icon, size: 40, color: AppColors.subtle),
        const SizedBox(height: 12),
        Text(
          text,
          textAlign: TextAlign.center,
          style: dsText(15, color: AppColors.muted),
        ),
        if (action != null) ...[
          const SizedBox(height: 14),
          Center(child: action!),
        ],
      ],
    );
  }
}
