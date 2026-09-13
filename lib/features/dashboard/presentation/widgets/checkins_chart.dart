import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/dashboard_stats.dart';

/// Cumulative check-ins over the day, built from real attendance timestamps.
class CheckInsChart extends StatelessWidget {
  const CheckInsChart({super.key, required this.points});

  final List<CheckInPoint> points;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Check-ins over time',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              height: 200,
              child: points.isEmpty
                  ? const Center(child: Text('No check-ins for this day.'))
                  : LineChart(_data(scheme)),
            ),
          ],
        ),
      ),
    );
  }

  LineChartData _data(ColorScheme scheme) {
    final spots = points
        .map((p) => FlSpot(p.minutesOfDay, p.cumulative.toDouble()))
        .toList();
    final maxY = points.last.cumulative.toDouble();
    final minX = spots.first.x;
    final maxX = spots.last.x;

    return LineChartData(
      minX: minX,
      maxX: maxX == minX ? minX + 60 : maxX,
      minY: 0,
      maxY: maxY + 1,
      gridData: const FlGridData(show: true, drawVerticalLine: false),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        leftTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: true, reservedSize: 28),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 24,
            interval: 120,
            getTitlesWidget: (value, meta) {
              final h = (value ~/ 60).clamp(0, 23);
              return Text('$h:00', style: const TextStyle(fontSize: 10));
            },
          ),
        ),
      ),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: false,
          color: scheme.primary,
          barWidth: 3,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            color: scheme.primary.withValues(alpha: 0.12),
          ),
        ),
      ],
    );
  }
}
