import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// The "EA" tile with a marigold base — same as `.brand-mark` on the web.
class BrandMark extends StatelessWidget {
  final double size;

  const BrandMark({super.key, this.size = 36});

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(size / 3);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: const [
          BoxShadow(
            color: Color(0x420A5448),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF14866F), AppColors.brandStrong],
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Text(
                'EA',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: size * 0.32,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: size / 12,
                child: const ColoredBox(color: AppColors.accent),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Brand mark + wordmark, light variant for use on the emerald hero.
class BrandLockup extends StatelessWidget {
  final bool light;

  const BrandLockup({super.key, this.light = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const BrandMark(),
        const SizedBox(width: 11),
        Text(
          'Exam Assistant',
          style: TextStyle(
            color: light ? Colors.white : AppColors.ink,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }
}
