import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

const _optionMarkers = ['ক', 'খ', 'গ', 'ঘ', 'ঙ', 'চ', 'ছ', 'জ'];

/// The option's Bangla letter by position (ক, খ, গ, ঘ…), falling back to
/// its key — same rule as the website's `optionMarker`.
String optionMarkerLabel(int index, String key) {
  return index < _optionMarkers.length ? _optionMarkers[index] : key;
}

enum OptionMarkerState { neutral, selected, correct, wrong }

/// A lettered circle in front of an MCQ option.
class OptionMarker extends StatelessWidget {
  final int index;
  final String optionKey;
  final OptionMarkerState state;
  final double size;

  const OptionMarker({
    super.key,
    required this.index,
    required this.optionKey,
    this.state = OptionMarkerState.neutral,
    this.size = 26,
  });

  @override
  Widget build(BuildContext context) {
    final fill = switch (state) {
      OptionMarkerState.neutral => null,
      OptionMarkerState.selected => AppColors.brand,
      OptionMarkerState.correct => AppColors.success,
      OptionMarkerState.wrong => AppColors.danger,
    };
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: fill,
        border: Border.all(color: fill ?? AppColors.lineStrong, width: 1.5),
      ),
      child: Text(
        optionMarkerLabel(index, optionKey),
        style: TextStyle(
          fontSize: size * 0.5,
          height: 1.1,
          fontWeight: FontWeight.w600,
          color: fill == null ? AppColors.ink2 : Colors.white,
        ),
      ),
    );
  }
}
