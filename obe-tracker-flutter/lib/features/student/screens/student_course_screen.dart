import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:obe_tracker/core/api/api_client.dart';
import 'package:obe_tracker/core/theme/app_theme.dart';
import 'package:obe_tracker/features/shared/widgets/attainment_badge.dart';

final _studentCourseMarksProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((ref, courseId) async {
  final res = await ApiClient().get('/student/courses/$courseId/marks');
  return List<Map<String, dynamic>>.from(res.data['data']);
});

final _studentCourseAttainmentProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, courseId) async {
  final res = await ApiClient().get('/student/courses/$courseId/attainment');
  return res.data['data'];
});

class StudentCourseScreen extends ConsumerStatefulWidget {
  final String courseId;
  const StudentCourseScreen({super.key, required this.courseId});

  @override
  ConsumerState<StudentCourseScreen> createState() => _StudentCourseScreenState();
}

class _StudentCourseScreenState extends ConsumerState<StudentCourseScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Course Details'),
        bottom: TabBar(
          controller: _tabCtrl,
          tabs: const [
            Tab(icon: Icon(Icons.assignment_outlined, size: 18), text: 'My Marks'),
            Tab(icon: Icon(Icons.bar_chart_outlined, size: 18), text: 'Attainment'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _MarksTab(courseId: widget.courseId),
          _AttainmentTab(courseId: widget.courseId),
        ],
      ),
    );
  }
}

class _MarksTab extends ConsumerWidget {
  final String courseId;
  const _MarksTab({required this.courseId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_studentCourseMarksProvider(courseId));
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (assessments) => assessments.isEmpty
          ? const Center(
              child: Text('No marks available yet.',
                  style: TextStyle(color: Color(0xFF6B7280))))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: assessments.length,
              itemBuilder: (_, i) {
                final a = assessments[i];
                final marks = a['marks'] as List? ?? [];
                final myMark = marks.isNotEmpty
                    ? (marks[0]['marksObtained'] as num?)?.toDouble()
                    : null;
                final totalMarks = (a['totalMarks'] as num?)?.toDouble() ?? 100;
                final pct = myMark != null ? myMark / totalMarks * 100 : null;

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(a['title'] ?? '', style: Theme.of(context).textTheme.titleMedium),
                            Text(
                              '${(a['type'] as String? ?? '').replaceAll('_', ' ')} · ${totalMarks.toStringAsFixed(0)} marks',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ]),
                        ),
                        if (myMark != null)
                          Column(children: [
                            Text(myMark.toStringAsFixed(1),
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: (pct ?? 0) >= 50 ? AppTheme.primaryGreen : AppTheme.error,
                                )),
                            Text('/ ${totalMarks.toStringAsFixed(0)}',
                                style: Theme.of(context).textTheme.bodySmall),
                          ])
                        else
                          const Chip(
                            label: Text('Not graded'),
                            backgroundColor: Color(0xFFF3F4F6),
                            labelStyle: TextStyle(fontSize: 11),
                          ),
                      ]),
                      if (myMark != null) ...[
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: myMark / totalMarks,
                          backgroundColor: const Color(0xFFE5E7EB),
                          color: (pct ?? 0) >= 50 ? AppTheme.primaryGreen : AppTheme.error,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        const SizedBox(height: 4),
                        Text('${pct!.toStringAsFixed(1)}%',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      ],
                    ]),
                  ),
                );
              },
            ),
    );
  }
}

class _AttainmentTab extends ConsumerWidget {
  final String courseId;
  const _AttainmentTab({required this.courseId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_studentCourseAttainmentProvider(courseId));
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (data) {
        final coAttainments = data['coAttainments'] as List? ?? [];
        final poAttainments = data['poAttainments'] as List? ?? [];

        if (coAttainments.isEmpty && poAttainments.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text('Attainment not yet available.\nYour faculty needs to enter marks first.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF6B7280))),
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (coAttainments.isNotEmpty) ...[
                Text('Course Outcome Attainment', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                ...coAttainments.map((att) {
                  final pct = (att['percentage'] as num).toDouble();
                  final level = att['level'] as String;
                  final co = att['courseOutcome'] as Map<String, dynamic>? ?? {};
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Text(co['code'] ?? '',
                              style: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.primaryGreen)),
                          const SizedBox(width: 8),
                          Expanded(child: Text(co['title'] ?? '',
                              style: Theme.of(context).textTheme.bodyMedium)),
                          AttainmentBadge(level: level, percentage: pct),
                        ]),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: pct / 100,
                          backgroundColor: const Color(0xFFE5E7EB),
                          color: AppTheme.attainmentColor(level),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ]),
                    ),
                  );
                }),
              ],

              if (poAttainments.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text('Program Outcome Attainment', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                ...poAttainments.map((att) {
                  final pct = (att['percentage'] as num).toDouble();
                  final level = att['level'] as String;
                  final po = att['programOutcome'] as Map<String, dynamic>? ?? {};
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(children: [
                        SizedBox(
                          width: 56,
                          child: Text(po['code'] ?? '',
                              style: const TextStyle(fontWeight: FontWeight.w700)),
                        ),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(po['title'] ?? '', style: Theme.of(context).textTheme.bodyMedium,
                                maxLines: 1, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 4),
                            LinearProgressIndicator(
                              value: pct / 100,
                              backgroundColor: const Color(0xFFE5E7EB),
                              color: AppTheme.attainmentColor(level),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ]),
                        ),
                        const SizedBox(width: 12),
                        AttainmentBadge(level: level, percentage: pct),
                      ]),
                    ),
                  );
                }),
              ],
            ],
          ),
        );
      },
    );
  }
}
