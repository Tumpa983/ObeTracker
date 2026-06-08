import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:obe_tracker/core/theme/app_theme.dart';
import 'package:obe_tracker/features/shared/widgets/attainment_badge.dart';
import '../providers/faculty_providers.dart';

class AttainmentScreen extends ConsumerWidget {
  final String courseId;
  const AttainmentScreen({super.key, required this.courseId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attAsync = ref.watch(courseAttainmentProvider(courseId));

    return attAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (att) {
        if (att.coAttainments.isEmpty && att.poAttainments.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.bar_chart_outlined, size: 48, color: Color(0xFF9CA3AF)),
                SizedBox(height: 16),
                Text('No attainment data yet',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                SizedBox(height: 8),
                Text('Enter student marks and define the CO–PO mapping to compute attainment.',
                    textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF6B7280))),
              ]),
            ),
          );
        }

        // Aggregate by CO (average across students)
        final coMap = <String, List<double>>{};
        final coLabels = <String, Map<String, dynamic>>{};
        for (final att in att.coAttainments) {
          final coId = att['courseOutcomeId'];
          coMap.putIfAbsent(coId, () => []).add((att['percentage'] as num).toDouble());
          coLabels[coId] = att['courseOutcome'];
        }

        final poMap = <String, List<double>>{};
        final poLabels = <String, Map<String, dynamic>>{};
        for (final att in att.poAttainments) {
          final poId = att['programOutcomeId'];
          poMap.putIfAbsent(poId, () => []).add((att['percentage'] as num).toDouble());
          poLabels[poId] = att['programOutcome'];
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // CO Attainment
              Text('Course Outcome Attainment',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 4),
              Text('Average attainment across enrolled students',
                  style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 16),

              if (coMap.isNotEmpty)
                _AttainmentBarChart(
                  items: coMap.entries.map((e) {
                    final avg = e.value.reduce((a, b) => a + b) / e.value.length;
                    return _AttainmentItem(
                      label: coLabels[e.key]?['code'] ?? '',
                      tooltip: coLabels[e.key]?['title'] ?? '',
                      percentage: avg,
                    );
                  }).toList(),
                ),

              const SizedBox(height: 8),
              ...coMap.entries.map((e) {
                final avg = e.value.reduce((a, b) => a + b) / e.value.length;
                final level = _levelFromPct(avg);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(children: [
                    SizedBox(
                      width: 60,
                      child: Text(coLabels[e.key]?['code'] ?? '',
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    ),
                    Expanded(
                      child: Text(coLabels[e.key]?['title'] ?? '',
                          style: Theme.of(context).textTheme.bodySmall,
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                    const SizedBox(width: 8),
                    AttainmentBadge(level: level, percentage: avg),
                  ]),
                );
              }),

              const Divider(height: 32),

              // PO Attainment
              Text('Program Outcome Attainment',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),

              if (poMap.isNotEmpty)
                _AttainmentBarChart(
                  items: poMap.entries.map((e) {
                    final avg = e.value.reduce((a, b) => a + b) / e.value.length;
                    return _AttainmentItem(
                      label: poLabels[e.key]?['code'] ?? '',
                      tooltip: poLabels[e.key]?['title'] ?? '',
                      percentage: avg,
                    );
                  }).toList(),
                ),

              const SizedBox(height: 8),
              ...poMap.entries.map((e) {
                final avg = e.value.reduce((a, b) => a + b) / e.value.length;
                final level = _levelFromPct(avg);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(children: [
                    SizedBox(
                      width: 60,
                      child: Text(poLabels[e.key]?['code'] ?? '',
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    ),
                    Expanded(
                      child: Text(poLabels[e.key]?['title'] ?? '',
                          style: Theme.of(context).textTheme.bodySmall,
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                    const SizedBox(width: 8),
                    AttainmentBadge(level: level, percentage: avg),
                  ]),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  String _levelFromPct(double pct) {
    if (pct >= 70) return 'L3';
    if (pct >= 60) return 'L2';
    if (pct >= 50) return 'L1';
    return 'L0';
  }
}

class _AttainmentItem {
  final String label;
  final String tooltip;
  final double percentage;
  const _AttainmentItem({required this.label, required this.tooltip, required this.percentage});
}

class _AttainmentBarChart extends StatelessWidget {
  final List<_AttainmentItem> items;
  const _AttainmentBarChart({required this.items});

  Color _barColor(double pct) {
    if (pct >= 70) return AppTheme.l3Color;
    if (pct >= 60) return AppTheme.l2Color;
    if (pct >= 50) return AppTheme.l1Color;
    return AppTheme.l0Color;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      child: BarChart(
        BarChartData(
          maxY: 100,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, _, rod, __) => BarTooltipItem(
                '${items[group.x].label}\n${rod.toY.toStringAsFixed(1)}%',
                const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, _) => Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(items[v.toInt()].label,
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
                ),
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 36,
                getTitlesWidget: (v, _) => Text('${v.toInt()}%',
                    style: const TextStyle(fontSize: 10, color: Color(0xFF9CA3AF))),
              ),
            ),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(
            drawVerticalLine: false,
            horizontalInterval: 25,
            getDrawingHorizontalLine: (_) => const FlLine(color: Color(0xFFE5E7EB), strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(
            items.length,
            (i) => BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: items[i].percentage,
                  color: _barColor(items[i].percentage),
                  width: 20,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
