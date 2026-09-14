import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/attendance_report_stats.dart';

/// Number of students present per calendar day across the selected report
/// range, built from real per-day presence — not a mock series.
class AttendanceRateChart extends StatelessWidget {
  const AttendanceRateChart({
    super.key,
    required this.points,
    required this.totalStudents,
  });

  final List<DailyRatePoint> points;

  /// Roster size — caps the y-axis so the line never has anywhere to
  /// overshoot above the real maximum.
  final int totalStudents;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.attendanceRateOverTime,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              height: 220,
              child: points.length < 2
                  ? Center(child: Text(l10n.notEnoughDataForRange))
                  : LineChart(_data(scheme, l10n)),
            ),
          ],
        ),
      ),
    );
  }

  LineChartData _data(ColorScheme scheme, AppLocalizations l10n) {
    final spots = [
      for (var i = 0; i < points.length; i++)
        FlSpot(i.toDouble(), points[i].presentCount.toDouble()),
    ];
    final labelEvery = (points.length / 6).ceil().clamp(1, points.length);
    final maxY = totalStudents <= 0 ? 1.0 : totalStudents.toDouble();
    final yInterval = (maxY / 4) < 1 ? 1.0 : maxY / 4;

    return LineChartData(
      minX: 0,
      maxX: (points.length - 1).toDouble(),
      minY: 0,
      maxY: maxY,
      // The data never exceeds [totalStudents], but a curved line can still
      // overshoot past its own endpoints during interpolation — clamp it back
      // to the chart's bounds so it never visually leaks above/below the card.
      clipData: const FlClipData.all(),
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
            interval: yInterval,
            getTitlesWidget: (value, meta) =>
                Text('${value.toInt()}', style: const TextStyle(fontSize: 10)),
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
              '$label\n${l10n.dashboardPresentCount(s.y.toInt())}',
              const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            );
          }).toList(),
        ),
      ),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          preventCurveOverShooting: true,
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
