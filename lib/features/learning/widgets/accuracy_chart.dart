import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/ds.dart';

/// Line of exam accuracy (0–100) per exam, oldest first, with a dashed 50%
/// line. Tapping a point selects it when [onSelect] is set.
class AccuracyChart extends StatelessWidget {
  final List<double> values;
  final int? selected;
  final ValueChanged<int>? onSelect;
  final double height;

  const AccuracyChart({
    required this.values,
    this.selected,
    this.onSelect,
    this.height = 150,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) {
      return SizedBox(
        height: height,
        child: Center(
          child: Text(
            'এখনো কোনো পরীক্ষা দাওনি',
            style: dsText(13, color: AppColors.muted),
          ),
        ),
      );
    }
    final lo = values.reduce((a, b) => a < b ? a : b);
    final hi = values.reduce((a, b) => a > b ? a : b);
    final minY = ((lo < 50 ? lo : 50) - 10).clamp(0, 100).toDouble();
    final maxY = ((hi > 50 ? hi : 50) + 10).clamp(0, 100).toDouble();

    return SizedBox(
      height: height,
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: values.length == 1 ? 1 : (values.length - 1).toDouble(),
          minY: minY,
          maxY: maxY,
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: const FlTitlesData(show: false),
          extraLinesData: ExtraLinesData(
            horizontalLines: [
              HorizontalLine(
                y: 50,
                color: const Color(0xFFC4C8CE),
                strokeWidth: 1,
                dashArray: [4, 4],
                label: HorizontalLineLabel(
                  show: true,
                  alignment: Alignment.topRight,
                  style: dsText(11, color: AppColors.muted),
                  labelResolver: (_) => '৫০%',
                ),
              ),
            ],
          ),
          lineTouchData: LineTouchData(
            enabled: onSelect != null,
            handleBuiltInTouches: false,
            touchCallback: (event, response) {
              if (onSelect == null || event is! FlTapUpEvent) return;
              final spots = response?.lineBarSpots;
              if (spots != null && spots.isNotEmpty) {
                onSelect!(spots.first.spotIndex);
              }
            },
          ),
          lineBarsData: [
            LineChartBarData(
              spots: [
                for (var i = 0; i < values.length; i++)
                  FlSpot(i.toDouble(), values[i]),
              ],
              color: AppColors.brand,
              barWidth: 2.5,
              isCurved: false,
              belowBarData: BarAreaData(
                show: true,
                color: AppColors.brand.withValues(alpha: 0.08),
              ),
              dotData: FlDotData(
                getDotPainter: (spot, _, _, index) => FlDotCirclePainter(
                  radius: index == selected ? 6 : 3.5,
                  color: AppColors.brand,
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
