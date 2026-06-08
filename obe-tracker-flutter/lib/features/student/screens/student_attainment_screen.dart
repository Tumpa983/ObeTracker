import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:obe_tracker/core/api/api_client.dart';
import 'package:obe_tracker/core/api/api_result.dart';
import 'package:obe_tracker/core/constants/app_constants.dart';
import 'package:obe_tracker/core/theme/app_theme.dart';
import 'package:obe_tracker/features/auth/providers/auth_provider.dart';
import 'package:obe_tracker/features/shared/widgets/app_scaffold.dart';
import 'package:obe_tracker/features/shared/widgets/attainment_badge.dart';
import 'package:obe_tracker/features/shared/widgets/loading_button.dart';
import 'package:url_launcher/url_launcher.dart';

const _studentNavItems = [
  NavItem(label: 'Dashboard', icon: Icons.dashboard_outlined, selectedIcon: Icons.dashboard, route: '/student/dashboard'),
  NavItem(label: 'Courses', icon: Icons.book_outlined, selectedIcon: Icons.book, route: '/student/courses'),
  NavItem(label: 'Attainment', icon: Icons.bar_chart_outlined, selectedIcon: Icons.bar_chart, route: '/student/attainment'),
];

final _programAttainmentProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final res = await ApiClient().get('/student/program-attainment');
  return List<Map<String, dynamic>>.from(res.data['data']);
});

class StudentAttainmentScreen extends ConsumerStatefulWidget {
  const StudentAttainmentScreen({super.key});
  @override
  ConsumerState<StudentAttainmentScreen> createState() => _StudentAttainmentScreenState();
}

class _StudentAttainmentScreenState extends ConsumerState<StudentAttainmentScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;
  bool _isRequestingTranscript = false;
  String? _transcriptUrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() { _tabCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final attainmentAsync = ref.watch(_programAttainmentProvider);
    final user = ref.watch(authProvider).user;

    return AppScaffold(
      title: 'My Attainment',
      navItems: _studentNavItems,
      currentRoute: '/student/attainment',
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: LoadingButton(
            isLoading: _isRequestingTranscript,
            label: _transcriptUrl != null ? 'Download' : 'Transcript',
            icon: _transcriptUrl != null ? Icons.download_outlined : Icons.receipt_long_outlined,
            onPressed: _transcriptUrl != null
                ? () => _openUrl(_transcriptUrl!, context)
                : _requestTranscript,
          ),
        ),
      ],
      body: Column(children: [
        TabBar(controller: _tabCtrl, tabs: const [
          Tab(icon: Icon(Icons.bar_chart_outlined, size: 18), text: 'Overview'),
          Tab(icon: Icon(Icons.radar_outlined, size: 18), text: 'Radar Chart'),
        ]),
        Expanded(child: attainmentAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (attainments) => attainments.isEmpty
              ? _EmptyAttainment()
              : TabBarView(controller: _tabCtrl, children: [
                  _OverviewTab(attainments: attainments),
                  _RadarTab(attainments: attainments),
                ]),
        )),
      ]),
    );
  }

  Future<void> _requestTranscript() async {
    setState(() => _isRequestingTranscript = true);
    try {
      final res = await ApiClient().post('/reports/transcript');
      final data = res.data['data'];
      setState(() {
        _transcriptUrl = '${AppConstants.baseUrl}${data['downloadUrl']}';
        _isRequestingTranscript = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transcript generated — tap Download!')));
    } catch (e) {
      setState(() => _isRequestingTranscript = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(parseApiError(e)), backgroundColor: AppTheme.error));
    }
  }

  Future<void> _openUrl(String url, BuildContext context) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Could not open: $url')));
    }
  }
}

// ── Overview Tab ─────────────────────────────────────────────
class _OverviewTab extends StatelessWidget {
  final List<Map<String, dynamic>> attainments;
  const _OverviewTab({required this.attainments});

  @override
  Widget build(BuildContext context) {
    // Group by L3/L2/L1/L0
    final byLevel = <String, int>{'L3': 0, 'L2': 0, 'L1': 0, 'L0': 0};
    for (final po in attainments) {
      final pct = (po['averagePercentage'] as num).toDouble();
      final level = pct >= 70 ? 'L3' : pct >= 60 ? 'L2' : pct >= 50 ? 'L1' : 'L0';
      byLevel[level] = (byLevel[level] ?? 0) + 1;
    }

    return RefreshIndicator(
      onRefresh: () async {},
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Summary strip
          Row(children: [
            _LevelSummaryCard(level: 'L3', count: byLevel['L3']!, total: attainments.length),
            const SizedBox(width: 8),
            _LevelSummaryCard(level: 'L2', count: byLevel['L2']!, total: attainments.length),
            const SizedBox(width: 8),
            _LevelSummaryCard(level: 'L1', count: byLevel['L1']!, total: attainments.length),
            const SizedBox(width: 8),
            _LevelSummaryCard(level: 'L0', count: byLevel['L0']!, total: attainments.length),
          ]),
          const SizedBox(height: 20),

          // Bar chart
          Text('Program Outcome Scores', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text('Average % across all courses where this PO was mapped.',
              style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 12),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                maxY: 100,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, _, rod, __) {
                      final po = attainments[group.x];
                      return BarTooltipItem(
                        '${po['code']}\n${rod.toY.toStringAsFixed(1)}%',
                        const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (v, _) {
                      final i = v.toInt();
                      if (i >= attainments.length) return const SizedBox();
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(attainments[i]['code'] ?? '',
                            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600)),
                      );
                    },
                  )),
                  leftTitles: AxisTitles(sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 34,
                    getTitlesWidget: (v, _) => Text('${v.toInt()}%',
                        style: const TextStyle(fontSize: 9, color: Color(0xFF9CA3AF))),
                  )),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  drawVerticalLine: false,
                  horizontalInterval: 25,
                  getDrawingHorizontalLine: (_) =>
                      const FlLine(color: Color(0xFFE5E7EB), strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(attainments.length, (i) {
                  final pct = (attainments[i]['averagePercentage'] as num).toDouble();
                  final level = pct >= 70 ? 'L3' : pct >= 60 ? 'L2' : pct >= 50 ? 'L1' : 'L0';
                  return BarChartGroupData(x: i, barRods: [
                    BarChartRodData(
                      toY: pct,
                      color: AppTheme.attainmentColor(level),
                      width: 18,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                    ),
                  ]);
                }),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Threshold lines legend
          _ThresholdLegend(),
          const SizedBox(height: 20),

          // Detailed list
          Text('Detailed Breakdown', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          ...attainments.map((po) {
            final pct = (po['averagePercentage'] as num).toDouble();
            final level = pct >= 70 ? 'L3' : pct >= 60 ? 'L2' : pct >= 50 ? 'L1' : 'L0';
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(children: [
                  Container(
                    width: 52, height: 52,
                    decoration: BoxDecoration(
                      color: AppTheme.attainmentColor(level).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text(po['code'] ?? '',
                          style: TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 11,
                              color: AppTheme.attainmentColor(level))),
                      Text('${pct.toStringAsFixed(0)}%',
                          style: TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 14,
                              color: AppTheme.attainmentColor(level))),
                    ]),
                  ),
                  const SizedBox(width: 14),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(po['title'] ?? '',
                        style: Theme.of(context).textTheme.titleMedium,
                        maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 6),
                    LinearProgressIndicator(
                      value: pct / 100,
                      backgroundColor: const Color(0xFFE5E7EB),
                      color: AppTheme.attainmentColor(level),
                      minHeight: 6,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ])),
                  const SizedBox(width: 12),
                  AttainmentBadge(level: level, showPercentage: false),
                ]),
              ),
            );
          }),
        ]),
      ),
    );
  }
}

// ── Radar Tab ────────────────────────────────────────────────
class _RadarTab extends StatelessWidget {
  final List<Map<String, dynamic>> attainments;
  const _RadarTab({required this.attainments});

  @override
  Widget build(BuildContext context) {
    // fl_chart RadarChart needs at least 3 data points
    if (attainments.length < 3) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text('Need at least 3 mapped POs to render a radar chart.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF6B7280))),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(children: [
        Text('Outcome Radar', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 4),
        Text('Your attainment across all Program Outcomes',
            style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 24),

        // Radar chart
        SizedBox(
          height: 340,
          child: RadarChart(
            RadarChartData(
              radarShape: RadarShape.polygon,
              tickCount: 4,
              ticksTextStyle: const TextStyle(fontSize: 0), // hide tick text, use gridlines
              radarBorderData: const BorderSide(color: Color(0xFFE5E7EB), width: 1),
              gridBorderData: const BorderSide(color: Color(0xFFE5E7EB), width: 1),
              tickBorderData: const BorderSide(color: Color(0xFFE5E7EB), width: 1),
              getTitle: (index, angle) => RadarChartTitle(
                text: attainments[index]['code'] ?? '',
                angle: 0,
              ),
              titleTextStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
              titlePositionPercentageOffset: 0.2,
              dataSets: [
                RadarDataSet(
                  dataEntries: attainments
                      .map((po) => RadarEntry(
                          value: (po['averagePercentage'] as num).toDouble()))
                      .toList(),
                  borderColor: AppTheme.primaryGreen,
                  fillColor: AppTheme.primaryGreen.withOpacity(0.18),
                  borderWidth: 2.5,
                  entryRadius: 4,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Labels key
        Wrap(
          spacing: 10,
          runSpacing: 6,
          children: attainments.map((po) {
            final pct = (po['averagePercentage'] as num).toDouble();
            final level = pct >= 70 ? 'L3' : pct >= 60 ? 'L2' : pct >= 50 ? 'L1' : 'L0';
            return Chip(
              avatar: CircleAvatar(
                backgroundColor: AppTheme.attainmentColor(level),
                child: Text(
                  po['code'] ?? '',
                  style: const TextStyle(fontSize: 8, color: Colors.white,
                      fontWeight: FontWeight.w700),
                ),
              ),
              label: Text('${pct.toStringAsFixed(0)}%  $level',
                  style: const TextStyle(fontSize: 11)),
              backgroundColor: AppTheme.attainmentColor(level).withOpacity(0.08),
              side: BorderSide(color: AppTheme.attainmentColor(level).withOpacity(0.3)),
              visualDensity: VisualDensity.compact,
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        _ThresholdLegend(),
      ]),
    );
  }
}

class _LevelSummaryCard extends StatelessWidget {
  final String level;
  final int count;
  final int total;
  const _LevelSummaryCard({required this.level, required this.count, required this.total});

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.attainmentColor(level);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Column(children: [
          Text('$count', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color)),
          Text(level, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
          Text('/ $total', style: const TextStyle(fontSize: 10, color: Color(0xFF9CA3AF))),
        ]),
      ),
    );
  }
}

class _ThresholdLegend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const levels = [
      ('L3', '≥ 70%', AppTheme.l3Color),
      ('L2', '60–69%', AppTheme.l2Color),
      ('L1', '50–59%', AppTheme.l1Color),
      ('L0', '< 50%', AppTheme.l0Color),
    ];
    return Wrap(
      spacing: 10,
      runSpacing: 6,
      children: levels.map((item) => Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 10, height: 10,
          decoration: BoxDecoration(color: item.$3, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text('${item.$1} ${item.$2}',
            style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
      ])).toList(),
    );
  }
}

class _EmptyAttainment extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.bar_chart_outlined, size: 44,
                color: AppTheme.primaryGreen.withOpacity(0.5)),
          ),
          const SizedBox(height: 20),
          Text('No attainment data yet',
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 10),
          Text(
            'Your attainment will appear once your faculty:\n'
            '1. Defines course outcomes and CO–PO mappings\n'
            '2. Creates assessments and enters your marks',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF6B7280)),
          ),
        ]),
      ),
    );
  }
}
