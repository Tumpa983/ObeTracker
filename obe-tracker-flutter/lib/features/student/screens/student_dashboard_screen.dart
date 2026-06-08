import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:obe_tracker/core/api/api_client.dart';
import 'package:obe_tracker/core/api/api_result.dart';
import 'package:obe_tracker/core/theme/app_theme.dart';
import 'package:obe_tracker/features/auth/providers/auth_provider.dart';
import 'package:obe_tracker/features/shared/widgets/app_scaffold.dart';
import 'package:obe_tracker/features/shared/widgets/attainment_badge.dart';
import 'package:obe_tracker/features/shared/widgets/empty_state.dart';
import 'package:fl_chart/fl_chart.dart';

final _studentNavItems = const [
  NavItem(label: 'Dashboard', icon: Icons.dashboard_outlined, selectedIcon: Icons.dashboard, route: '/student/dashboard'),
  NavItem(label: 'Courses', icon: Icons.book_outlined, selectedIcon: Icons.book, route: '/student/courses'),
  NavItem(label: 'Attainment', icon: Icons.bar_chart_outlined, selectedIcon: Icons.bar_chart, route: '/student/attainment'),
];

final _studentCoursesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final res = await ApiClient().get('/student/courses');
  return List<Map<String, dynamic>>.from(res.data['data']);
});

final _studentProgramAttainmentProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final res = await ApiClient().get('/student/program-attainment');
  return List<Map<String, dynamic>>.from(res.data['data']);
});

class StudentDashboardScreen extends ConsumerWidget {
  const StudentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final coursesAsync = ref.watch(_studentCoursesProvider);
    final attainmentAsync = ref.watch(_studentProgramAttainmentProvider);

    return AppScaffold(
      title: 'My Dashboard',
      navItems: _studentNavItems,
      currentRoute: '/student/dashboard',
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(_studentCoursesProvider);
          ref.invalidate(_studentProgramAttainmentProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AppTheme.primaryGreen, AppTheme.primaryLight]),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    child: Text(
                      user?.firstName[0].toUpperCase() ?? 'S',
                      style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Hi, ${user?.firstName ?? 'Student'} 👋',
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                    const Text('Track your outcomes and attainment.',
                        style: TextStyle(color: Colors.white70, fontSize: 13)),
                  ])),
                ]),
              ),
              const SizedBox(height: 24),

              // Program Attainment Radar Preview
              Text('Program Outcome Overview', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              attainmentAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => const SizedBox(),
                data: (attainments) => attainments.isEmpty
                    ? const Card(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: Center(
                            child: Text('No attainment data yet. Marks will appear once your faculty enters them.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Color(0xFF6B7280))),
                          ),
                        ))
                    : _PoSummaryCards(attainments: attainments),
              ),

              const SizedBox(height: 24),

              // My Courses
              Text('My Enrolled Courses', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              coursesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
                data: (courses) => courses.isEmpty
                    ? const EmptyState(
                        icon: Icons.book_outlined,
                        title: 'No courses enrolled',
                        subtitle: 'Contact your administrator to get enrolled in courses.',
                      )
                    : Column(
                        children: courses.map((c) => _CourseCard(course: c)).toList(),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PoSummaryCards extends StatelessWidget {
  final List<Map<String, dynamic>> attainments;
  const _PoSummaryCards({required this.attainments});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 180,
        mainAxisExtent: 90,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: attainments.length,
      itemBuilder: (_, i) {
        final po = attainments[i];
        final pct = (po['averagePercentage'] as num).toDouble();
        final level = pct >= 70 ? 'L3' : pct >= 60 ? 'L2' : pct >= 50 ? 'L1' : 'L0';
        final code = po['code'] ?? '';
        final title = po['title'] ?? '';
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text(code, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                const Spacer(),
                AttainmentBadge(level: level, showPercentage: false),
              ]),
              const SizedBox(height: 4),
              Text(title, style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 2, overflow: TextOverflow.ellipsis),
              const Spacer(),
              LinearProgressIndicator(
                value: pct / 100,
                backgroundColor: const Color(0xFFE5E7EB),
                color: AppTheme.attainmentColor(level),
                borderRadius: BorderRadius.circular(4),
              ),
            ]),
          ),
        );
      },
    );
  }
}

class _CourseCard extends StatelessWidget {
  final Map<String, dynamic> course;
  const _CourseCard({required this.course});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () => context.go('/student/courses/${course['id']}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.book_outlined, color: AppTheme.primaryGreen, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(course['name'] ?? '', style: Theme.of(context).textTheme.titleMedium),
              Text(
                '${course['code'] ?? ''} · ${course['session']?['name'] ?? ''}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ])),
            const Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFF9CA3AF)),
          ]),
        ),
      ),
    );
  }
}
