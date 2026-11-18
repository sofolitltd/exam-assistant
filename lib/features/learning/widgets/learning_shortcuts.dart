import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';

/// Home-screen entry points to progress, mistake practice and listen mode.
class LearningShortcuts extends StatelessWidget {
  const LearningShortcuts({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Shortcut(
          icon: Icons.insights_outlined,
          label: 'অগ্রগতি',
          onTap: () => context.push('/progress'),
        ),
        const SizedBox(width: 10),
        _Shortcut(
          icon: Icons.replay,
          label: 'ভুলগুলো',
          onTap: () => context.push('/practice/mistakes'),
        ),
        const SizedBox(width: 10),
        _Shortcut(
          icon: Icons.headphones_outlined,
          label: 'শুনে পড়ো',
          onTap: () => context.push('/listen'),
        ),
      ],
    );
  }
}

class _Shortcut extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _Shortcut({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadii.lg),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadii.lg),
              border: Border.all(color: AppColors.line),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: AppColors.brandSoft,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: AppColors.brandStrong, size: 20),
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
