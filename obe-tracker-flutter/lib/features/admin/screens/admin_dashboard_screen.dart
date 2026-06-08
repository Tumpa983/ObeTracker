import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:obe_tracker/core/theme/app_theme.dart';
import 'package:obe_tracker/features/auth/providers/auth_provider.dart';
import 'package:obe_tracker/features/shared/widgets/app_scaffold.dart';
import 'package:obe_tracker/features/shared/widgets/stat_card.dart';
import '../providers/admin_providers.dart';

final _adminNavItems = const [
  NavItem(label: 'Dashboard', icon: Icons.dashboard_outlined, selectedIcon: Icons.dashboard, route: '/admin/dashboard'),
  NavItem(label: 'Structure', icon: Icons.account_tree_outlined, selectedIcon: Icons.account_tree, route: '/admin/structure'),
  NavItem(label: 'Courses', icon: Icons.book_outlined, selectedIcon: Icons.book, route: '/admin/courses'),
  NavItem(label: 'Users', icon: Icons.people_outlined, selectedIcon: Icons.people, route: '/admin/users'),
  NavItem(label: 'Outcomes', icon: Icons.track_changes_outlined, selectedIcon: Icons.track_changes, route: '/admin/outcomes'),
];

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final statsAsync = ref.watch(dashboardProvider);

    return AppScaffold(
      title: 'Dashboard',
      navItems: _adminNavItems,
      currentRoute: '/admin/dashboard',
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(dashboardProvider.future),
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
                  gradient: const LinearGradient(
                    colors: [AppTheme.primaryGreen, AppTheme.primaryLight],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      child: Text(
                        user?.firstName[0].toUpperCase() ?? 'A',
                        style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome back, ${user?.firstName ?? 'Admin'}',
                            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
                          ),
                          const Text(
                            'Bangladesh University of Professionals',
                            style: TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Stats
              Text('Institution Overview', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              statsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text('Failed to load stats: $e',
                        style: const TextStyle(color: AppTheme.error)),
                  ),
                ),
                data: (stats) => Column(
                  children: [
                    Row(children: [
                      Expanded(
                        child: StatCard(
                          title: 'Departments',
                          value: '${stats.deptCount}',
                          icon: Icons.apartment_outlined,
                          color: AppTheme.primaryGreen,
                          onTap: () => context.go('/admin/structure'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: StatCard(
                          title: 'Programs',
                          value: '${stats.programCount}',
                          icon: Icons.school_outlined,
                          color: AppTheme.info,
                          onTap: () => context.go('/admin/structure'),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(
                        child: StatCard(
                          title: 'Courses',
                          value: '${stats.courseCount}',
                          icon: Icons.book_outlined,
                          color: AppTheme.warning,
                          onTap: () => context.go('/admin/courses'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: StatCard(
                          title: 'Active Users',
                          value: '${stats.userCount}',
                          icon: Icons.people_outlined,
                          color: AppTheme.l3Color,
                          onTap: () => context.go('/admin/users'),
                        ),
                      ),
                    ]),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              Text('Quick Actions', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              _QuickActions(),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final actions = [
      _ActionItem(Icons.add_business_outlined, 'Add Department', () => context.go('/admin/structure')),
      _ActionItem(Icons.person_add_outlined, 'Add User', () => context.go('/admin/users')),
      _ActionItem(Icons.upload_file_outlined, 'Bulk Import', () => context.go('/admin/users')),
      _ActionItem(Icons.track_changes_outlined, 'Manage POs', () => context.go('/admin/outcomes')),
      _ActionItem(Icons.tune_outlined, 'Thresholds', () => context.go('/admin/outcomes')),
      _ActionItem(Icons.calendar_month_outlined, 'Sessions', () => context.go('/admin/structure')),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 180,
        mainAxisExtent: 80,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: actions.length,
      itemBuilder: (_, i) => actions[i],
    );
  }
}

class _ActionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionItem(this.icon, this.label, this.onTap);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(icon, size: 22, color: AppTheme.primaryGreen),
              const SizedBox(width: 10),
              Expanded(
                child: Text(label,
                    style: Theme.of(context).textTheme.labelLarge,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
