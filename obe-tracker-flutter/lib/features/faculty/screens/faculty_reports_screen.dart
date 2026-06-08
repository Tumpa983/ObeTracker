import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:obe_tracker/core/api/api_client.dart';
import 'package:obe_tracker/core/api/api_result.dart';
import 'package:obe_tracker/core/constants/app_constants.dart';
import 'package:obe_tracker/core/theme/app_theme.dart';
import 'package:obe_tracker/features/shared/widgets/app_scaffold.dart';
import 'package:obe_tracker/features/shared/widgets/loading_button.dart';
import 'package:obe_tracker/features/admin/models/admin_models.dart';
import 'package:obe_tracker/features/faculty/providers/faculty_providers.dart';

const _facultyNavItems = [
  NavItem(label: 'Dashboard', icon: Icons.dashboard_outlined, selectedIcon: Icons.dashboard, route: '/faculty/dashboard'),
  NavItem(label: 'Courses', icon: Icons.book_outlined, selectedIcon: Icons.book, route: '/faculty/courses'),
  NavItem(label: 'Reports', icon: Icons.assessment_outlined, selectedIcon: Icons.assessment, route: '/faculty/reports'),
];

// Local state: generated report history for this session
class _ReportRecord {
  final String courseCode;
  final String courseName;
  final String format;
  final String reportId;
  final String downloadUrl;
  final DateTime generatedAt;
  _ReportRecord({
    required this.courseCode, required this.courseName, required this.format,
    required this.reportId, required this.downloadUrl, required this.generatedAt,
  });
}

final _reportsHistoryProvider =
    StateProvider<List<_ReportRecord>>((ref) => []);

class FacultyReportsScreen extends ConsumerStatefulWidget {
  const FacultyReportsScreen({super.key});
  @override
  ConsumerState<FacultyReportsScreen> createState() => _FacultyReportsScreenState();
}

class _FacultyReportsScreenState extends ConsumerState<FacultyReportsScreen> {
  Course? _selectedCourse;
  String _format = 'PDF';
  bool _isGenerating = false;

  @override
  Widget build(BuildContext context) {
    final coursesAsync = ref.watch(facultyCoursesProvider);
    final history = ref.watch(_reportsHistoryProvider);

    return AppScaffold(
      title: 'Reports',
      navItems: _facultyNavItems,
      currentRoute: '/faculty/reports',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // ── Generate Report Card ──────────────────────────────
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.insert_chart_outlined,
                        color: AppTheme.primaryGreen, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Text('Generate Course Report',
                      style: Theme.of(context).textTheme.titleLarge),
                ]),
                const SizedBox(height: 20),

                // Course selector
                Text('Select Course', style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 8),
                coursesAsync.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => Text('Error: $e',
                      style: const TextStyle(color: AppTheme.error)),
                  data: (courses) => DropdownButtonFormField<Course>(
                    value: _selectedCourse,
                    hint: const Text('Choose a course'),
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.book_outlined, size: 18)),
                    items: courses.map((c) => DropdownMenuItem(
                      value: c,
                      child: Text('${c.code} — ${c.name}'),
                    )).toList(),
                    onChanged: (v) => setState(() => _selectedCourse = v),
                  ),
                ),
                const SizedBox(height: 16),

                // Format selector
                Text('Report Format', style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 8),
                Row(children: [
                  _FormatOption(
                    label: 'PDF',
                    icon: Icons.picture_as_pdf_outlined,
                    selected: _format == 'PDF',
                    color: AppTheme.error,
                    description: 'Watermarked report with attainment charts',
                    onTap: () => setState(() => _format = 'PDF'),
                  ),
                  const SizedBox(width: 10),
                  _FormatOption(
                    label: 'CSV',
                    icon: Icons.table_chart_outlined,
                    selected: _format == 'CSV',
                    color: AppTheme.primaryGreen,
                    description: 'Raw attainment data, Excel-compatible',
                    onTap: () => setState(() => _format = 'CSV'),
                  ),
                ]),
                const SizedBox(height: 20),

                // What's included
                _WhatIsIncluded(),
                const SizedBox(height: 20),

                // Generate button
                LoadingButton(
                  isLoading: _isGenerating,
                  label: 'Generate ${_format} Report',
                  icon: Icons.download_outlined,
                  onPressed: _selectedCourse == null ? null : _generate,
                ),
              ]),
            ),
          ),

          // ── Generated Reports History ─────────────────────────
          if (history.isNotEmpty) ...[
            const SizedBox(height: 28),
            Text('Generated This Session',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            ...history.map((r) => _ReportHistoryCard(record: r)),
          ],

          // ── Export Guide ──────────────────────────────────────
          const SizedBox(height: 28),
          _ExportGuideCard(),
        ]),
      ),
    );
  }

  Future<void> _generate() async {
    if (_selectedCourse == null) return;
    setState(() => _isGenerating = true);
    try {
      final res = await ApiClient().post(
        '/reports/course/${_selectedCourse!.id}',
        data: {'format': _format},
      );
      final data = res.data['data'];
      final reportId = data['reportId'] as String;
      final downloadUrl = '${AppConstants.baseUrl}${data['downloadUrl']}';

      // Add to history
      ref.read(_reportsHistoryProvider.notifier).state = [
        _ReportRecord(
          courseCode: _selectedCourse!.code,
          courseName: _selectedCourse!.name,
          format: _format,
          reportId: reportId,
          downloadUrl: downloadUrl,
          generatedAt: DateTime.now(),
        ),
        ...ref.read(_reportsHistoryProvider),
      ];

      // For CSV, browser will handle the download directly
      if (_format == 'CSV') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('CSV ready — use the download button below.')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF report generated — tap Download to open it.')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(parseApiError(e)), backgroundColor: AppTheme.error));
    }
    setState(() => _isGenerating = false);
  }
}

class _FormatOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final Color color;
  final String description;
  final VoidCallback onTap;

  const _FormatOption({
    required this.label, required this.icon, required this.selected,
    required this.color, required this.description, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: selected ? color.withOpacity(0.08) : const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? color : const Color(0xFFE5E7EB),
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(icon, color: selected ? color : const Color(0xFF9CA3AF), size: 20),
              const SizedBox(width: 6),
              Text(label, style: TextStyle(
                fontWeight: FontWeight.w700,
                color: selected ? color : const Color(0xFF374151),
              )),
              const Spacer(),
              if (selected) Icon(Icons.check_circle, color: color, size: 16),
            ]),
            const SizedBox(height: 4),
            Text(description,
                style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
          ]),
        ),
      ),
    );
  }
}

class _WhatIsIncluded extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const items = [
      '📊  CO attainment averaged across all enrolled students',
      '🎯  PO attainment computed from the CO–PO mapping',
      '📋  Bloom\'s Taxonomy and Profile classification per CO',
      '⚠️   PDF reports are watermarked and stored for 30 days',
    ];
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.info.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.info.withOpacity(0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.info_outline, color: AppTheme.info, size: 16),
          const SizedBox(width: 6),
          Text('What\'s included', style: TextStyle(
              fontWeight: FontWeight.w600, color: AppTheme.info, fontSize: 13)),
        ]),
        const SizedBox(height: 8),
        ...items.map((item) => Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(item, style: const TextStyle(fontSize: 12, color: Color(0xFF374151))),
        )),
      ]),
    );
  }
}

class _ReportHistoryCard extends StatelessWidget {
  final _ReportRecord record;
  const _ReportHistoryCard({required this.record});

  @override
  Widget build(BuildContext context) {
    final isPdf = record.format == 'PDF';
    final color = isPdf ? AppTheme.error : AppTheme.primaryGreen;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(isPdf ? Icons.picture_as_pdf_outlined : Icons.table_chart_outlined,
                color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${record.courseCode} — ${record.format} Report',
                style: Theme.of(context).textTheme.titleMedium),
            Text(
              '${record.courseName}  ·  Generated ${_timeAgo(record.generatedAt)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ])),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: () => _openUrl(record.downloadUrl, context),
            icon: const Icon(Icons.download_outlined, size: 16),
            label: const Text('Download'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(100, 36),
              textStyle: const TextStyle(fontSize: 13),
            ),
          ),
        ]),
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    return '${diff.inHours}h ago';
  }

  Future<void> _openUrl(String url, BuildContext context) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open: $url')));
    }
  }
}

class _ExportGuideCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.help_outline, size: 18, color: Color(0xFF6B7280)),
            const SizedBox(width: 8),
            Text('Bulk Export & Student Transcripts',
                style: Theme.of(context).textTheme.titleMedium),
          ]),
          const SizedBox(height: 12),
          const Text(
            'Students can generate their own attainment transcripts from their dashboard. '
            'For bulk exports of all student data, use the API directly:',
            style: TextStyle(fontSize: 13, color: Color(0xFF374151)),
          ),
          const SizedBox(height: 12),
          _CodeSnippet('GET  /api/v1/bulk/templates/marks/:assessmentId'),
          const SizedBox(height: 4),
          _CodeSnippet('POST /api/v1/reports/course/:courseId'),
          const SizedBox(height: 4),
          _CodeSnippet('GET  /api/v1/reports/:reportId/download'),
        ]),
      ),
    );
  }
}

class _CodeSnippet extends StatelessWidget {
  final String code;
  const _CodeSnippet(this.code);
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: const Color(0xFF1F2937),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(code,
        style: const TextStyle(
            fontFamily: 'monospace', fontSize: 11, color: Color(0xFF86EFAC))),
  );
}
