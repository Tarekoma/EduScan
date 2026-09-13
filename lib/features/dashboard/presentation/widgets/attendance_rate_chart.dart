import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/attendance_report_stats.dart';

/// Attendance rate (0-100%) per calendar day across the selected report
/// range, built from real per-day presence — not a mock series.
class AttendanceRateChart extends StatelessWidget {
  const AttendanceRateChart({super.key, required this.points});

  final List<DailyRatePoint> points;

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
              'Attendance rate over time',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              height: 220,
              child: points.length < 2
                  ? const Center(child: Text('Not enough data for this range.'))
                  : LineChart(_data(scheme)),
            ),
          ],
        ),
      ),
    );
  }

  LineChartData _data(ColorScheme scheme) {
    final spots = [
      for (var i = 0; i < points.length; i++)
        FlSpot(i.toDouble(), points[i].rate * 100),
    ];
    final labelEvery = (points.length / 6).ceil().clamp(1, points.length);

    return LineChartData(
      minX: 0,
      maxX: (points.length - 1).toDouble(),
      minY: 0,
      maxY: 100,
      gridData: const FlGridData(show: true, drawVerticalLine: false),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 36,
            interval: 25,
            getTitlesWidget: (value, meta) =>
                Text('${value.toInt()}%', style: const TextStyle(fontSize: 10)),
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 24,
            interval: labelEvery.toDouble(),
            getTitlesWidget: (value, meta) {
              final i = value.toInt();
              if (i < 0 || i >= points.length) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  DateFormat('d MMM').format(points[i].date),
                  style: const TextStyle(fontSize: 10),
                ),
              );
            },
          ),
        ),
      ),
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipItems: (spots) => spots.map((s) {
            final i = s.x.toInt();
            final label = i >= 0 && i < points.length
                ? DateFormat('EEE, d MMM').format(points[i].date)
                : '';
            return LineTooltipItem(
              '$label\n${s.y.toStringAsFixed(1)}%',
              const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            );
          }).toList(),
        ),
      ),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: scheme.primary,
          barWidth: 3,
          dotData: FlDotData(show: points.length <= 14),
          belowBarData: BarAreaData(
            show: true,
            color: scheme.primary.withValues(alpha: 0.12),
          ),
        ),
      ],
    );
  }
}
