import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:obe_tracker/core/theme/app_theme.dart';
import 'package:obe_tracker/features/auth/providers/auth_provider.dart';
import 'package:obe_tracker/features/shared/widgets/app_scaffold.dart';
import 'package:obe_tracker/features/shared/widgets/empty_state.dart';
import '../providers/faculty_providers.dart';

final _facultyNavItems = const [
  NavItem(label: 'Dashboard', icon: Icons.dashboard_outlined, selectedIcon: Icons.dashboard, route: '/faculty/dashboard'),
  NavItem(label: 'Courses', icon: Icons.book_outlined, selectedIcon: Icons.book, route: '/faculty/courses'),
  NavItem(label: 'Reports', icon: Icons.assessment_outlined, selectedIcon: Icons.assessment, route: '/faculty/reports'),
];

class FacultyDashboardScreen extends ConsumerWidget {
  const FacultyDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final coursesAsync = ref.watch(facultyCoursesProvider);

    return AppScaffold(
      title: 'My Dashboard',
      navItems: _facultyNavItems,
      currentRoute: '/faculty/dashboard',
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(facultyCoursesProvider.future),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [AppTheme.primaryGreen, AppTheme.primaryLight]),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Hello, ${user?.firstName ?? 'Faculty'} 👋',
                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  const Text('Manage your courses, outcomes, and attainment.',
                      style: TextStyle(color: Colors.white70, fontSize: 13)),
                ]),
              ),
              const SizedBox(height: 24),

              Text('My Assigned Courses', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),

              coursesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text('Error: $e'),
                  ),
                ),
                data: (courses) => courses.isEmpty
                    ? const EmptyState(
                        icon: Icons.book_outlined,
                        title: 'No courses assigned',
                        subtitle: 'Contact your administrator to get assigned to courses.',
                      )
                    : Column(
                        children: courses
                            .map((course) => _CourseCard(course: course))
                            .toList(),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CourseCard extends StatelessWidget {
  final dynamic course;
  const _CourseCard({required this.course});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => context.go('/faculty/courses/${course.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.book_outlined, color: AppTheme.primaryGreen, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(course.name, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 2),
                Text(
                  '${course.code} · ${course.session?['name'] ?? ''} · ${course.creditHours} credits',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 4),
                Text(
                  course.program?['name'] ?? '',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.primaryGreen,
                  ),
                ),
              ]),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFF9CA3AF)),
          ]),
        ),
      ),
    );
  }
}
