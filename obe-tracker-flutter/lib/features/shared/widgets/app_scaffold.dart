import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:obe_tracker/core/theme/app_theme.dart';
import 'package:obe_tracker/features/auth/providers/auth_provider.dart';

class NavItem {
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final String route;

  const NavItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.route,
  });
}

class AppScaffold extends ConsumerWidget {
  final Widget body;
  final String title;
  final List<NavItem> navItems;
  final String currentRoute;
  final List<Widget>? actions;
  final Widget? floatingActionButton;

  const AppScaffold({
    super.key,
    required this.body,
    required this.title,
    required this.navItems,
    required this.currentRoute,
    this.actions,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 720;
    final selectedIndex = navItems.indexWhere((n) => currentRoute.startsWith(n.route));

    if (isWide) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              backgroundColor: Colors.white,
              selectedIndex: selectedIndex < 0 ? 0 : selectedIndex,
              onDestinationSelected: (i) => context.go(navItems[i].route),
              extended: size.width > 1024,
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.school_rounded, color: Colors.white, size: 24),
                    ),
                  ],
                ),
              ),
              trailing: Expanded(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (user != null) ...[
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: AppTheme.primaryGreen,
                            child: Text(
                              user.firstName[0].toUpperCase(),
                              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                            ),
                          ),
                          const SizedBox(height: 4),
                          if (size.width > 1024)
                            Text(user.fullName,
                                style: const TextStyle(fontSize: 11),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                        ],
                        const SizedBox(height: 8),
                        IconButton(
                          icon: const Icon(Icons.logout_outlined),
                          tooltip: 'Logout',
                          onPressed: () => _confirmLogout(context, ref),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              destinations: navItems
                  .map((n) => NavigationRailDestination(
                        icon: Icon(n.icon),
                        selectedIcon: Icon(n.selectedIcon),
                        label: Text(n.label),
                      ))
                  .toList(),
            ),
            const VerticalDivider(width: 1),
            Expanded(
              child: Column(
                children: [
                  AppBar(
                    title: Text(title),
                    actions: actions,
                    automaticallyImplyLeading: false,
                  ),
                  Expanded(child: body),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: floatingActionButton,
      );
    }

    // Mobile: bottom navigation
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          ...?actions,
          PopupMenuButton<String>(
            icon: CircleAvatar(
              radius: 16,
              backgroundColor: AppTheme.primaryGreen,
              child: Text(
                user?.firstName[0].toUpperCase() ?? 'U',
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
            onSelected: (val) {
              if (val == 'logout') _confirmLogout(context, ref);
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                enabled: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user?.fullName ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text(user?.role ?? '', style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(value: 'logout', child: Row(children: [
                Icon(Icons.logout_outlined, size: 18),
                SizedBox(width: 8),
                Text('Logout'),
              ])),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: body,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex < 0 ? 0 : selectedIndex,
        onDestinationSelected: (i) => context.go(navItems[i].route),
        destinations: navItems
            .map((n) => NavigationDestination(
                  icon: Icon(n.icon),
                  selectedIcon: Icon(n.selectedIcon),
                  label: n.label,
                ))
            .toList(),
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(authProvider.notifier).logout();
      if (context.mounted) context.go('/login');
    }
  }
}
