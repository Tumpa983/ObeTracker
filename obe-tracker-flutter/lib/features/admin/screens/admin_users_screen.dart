import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:obe_tracker/core/theme/app_theme.dart';
import 'package:obe_tracker/features/shared/widgets/app_scaffold.dart';
import 'package:obe_tracker/features/shared/widgets/empty_state.dart';
import 'package:obe_tracker/features/shared/widgets/loading_button.dart';
import '../models/admin_models.dart';
import '../providers/admin_providers.dart';

final _adminNavItems = const [
  NavItem(label: 'Dashboard', icon: Icons.dashboard_outlined, selectedIcon: Icons.dashboard, route: '/admin/dashboard'),
  NavItem(label: 'Structure', icon: Icons.account_tree_outlined, selectedIcon: Icons.account_tree, route: '/admin/structure'),
  NavItem(label: 'Courses', icon: Icons.book_outlined, selectedIcon: Icons.book, route: '/admin/courses'),
  NavItem(label: 'Users', icon: Icons.people_outlined, selectedIcon: Icons.people, route: '/admin/users'),
  NavItem(label: 'Outcomes', icon: Icons.track_changes_outlined, selectedIcon: Icons.track_changes, route: '/admin/outcomes'),
];

final _userFiltersProvider = StateProvider<Map<String, String>?>((ref) => null);

class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});
  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen> {
  String _selectedRole = 'ALL';
  final _searchCtrl = TextEditingController();
  // Optimistic local overrides: userId -> isActive
  // Updated instantly on toggle so UI responds without waiting for refetch
  final Map<String, bool> _activeOverrides = {};

  static const _roleColors = {
    'ADMIN': AppTheme.error,
    'FACULTY': AppTheme.info,
    'STUDENT': AppTheme.primaryGreen,
  };

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filters = _selectedRole != 'ALL'
        ? {'role': _selectedRole}
        : null;
    final usersAsync = ref.watch(usersProvider(filters));

    return AppScaffold(
      title: 'User Management',
      navItems: _adminNavItems,
      currentRoute: '/admin/users',
      actions: [
        IconButton(
          icon: const Icon(Icons.upload_file_outlined),
          tooltip: 'Bulk Import',
          onPressed: () => _showBulkImportInfo(context),
        ),
      ],
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddUserDialog(context, ref),
        icon: const Icon(Icons.person_add_outlined),
        label: const Text('Add User'),
      ),
      body: Column(
        children: [
          // Filters
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(children: [
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Search by name or email…',
                    prefixIcon: Icon(Icons.search, size: 20),
                    isDense: true,
                  ),
                  onChanged: (v) => setState(() {}),
                ),
              ),
              const SizedBox(width: 10),
              DropdownButton<String>(
                value: _selectedRole,
                underline: const SizedBox(),
                items: const [
                  DropdownMenuItem(value: 'ALL', child: Text('All Roles')),
                  DropdownMenuItem(value: 'ADMIN', child: Text('Admin')),
                  DropdownMenuItem(value: 'FACULTY', child: Text('Faculty')),
                  DropdownMenuItem(value: 'STUDENT', child: Text('Student')),
                ],
                onChanged: (v) => setState(() => _selectedRole = v!),
              ),
            ]),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: usersAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (users) {
                final search = _searchCtrl.text.toLowerCase();
                final filtered = search.isEmpty
                    ? users
                    : users.where((u) =>
                        u.fullName.toLowerCase().contains(search) ||
                        u.email.toLowerCase().contains(search)).toList();

                if (filtered.isEmpty) {
                  return const EmptyState(
                    icon: Icons.people_outline,
                    title: 'No users found',
                    subtitle: 'Adjust your filters or add a new user.',
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => ref.refresh(usersProvider(filters).future),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    itemBuilder: (_, i) {
                      final u = filtered[i];
                      final roleColor = _roleColors[u.role] ?? Colors.grey;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: roleColor.withOpacity(0.15),
                            child: Text(
                              u.firstName[0].toUpperCase(),
                              style: TextStyle(color: roleColor, fontWeight: FontWeight.w700),
                            ),
                          ),
                          title: Text(u.fullName),
                          subtitle: Text('${u.email} · ${u.institutionalId ?? 'No ID'}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Chip(
                                label: Text(u.role),
                                backgroundColor: roleColor.withOpacity(0.1),
                                labelStyle: TextStyle(color: roleColor, fontSize: 10),
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                              ),
                              const SizedBox(width: 4),
                              Switch(
                                value: _activeOverrides.containsKey(u.id)
                                    ? _activeOverrides[u.id]!
                                    : u.isActive,
                                onChanged: (v) async {
                                  // Update locally first for instant feedback
                                  setState(() => _activeOverrides[u.id] = v);
                                  final result = await AdminActions.updateUserStatus(u.id, v);
                                  result.when(
                                    success: (_) {
                                      // Refresh cache in background; local override keeps UI correct
                                      ref.invalidate(usersProvider);
                                    },
                                    failure: (e) {
                                      // Revert local override on failure
                                      setState(() => _activeOverrides[u.id] = !v);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text(e), backgroundColor: AppTheme.error),
                                      );
                                    },
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddUserDialog(BuildContext context, WidgetRef ref) async {
    final firstCtrl = TextEditingController();
    final lastCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final idCtrl = TextEditingController();
    String role = 'STUDENT';
    bool isLoading = false;
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Add User'),
          content: SizedBox(
            width: 360,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Row(children: [
                    Expanded(child: TextFormField(
                      controller: firstCtrl,
                      decoration: const InputDecoration(labelText: 'First Name'),
                      validator: (v) => v?.isEmpty == true ? 'Required' : null,
                    )),
                    const SizedBox(width: 10),
                    Expanded(child: TextFormField(
                      controller: lastCtrl,
                      decoration: const InputDecoration(labelText: 'Last Name'),
                      validator: (v) => v?.isEmpty == true ? 'Required' : null,
                    )),
                  ]),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email'),
                    validator: (v) => v?.isEmpty == true ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: idCtrl,
                    decoration: const InputDecoration(labelText: 'Institutional ID (optional)'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: role,
                    decoration: const InputDecoration(labelText: 'Role'),
                    items: const [
                      DropdownMenuItem(value: 'STUDENT', child: Text('Student')),
                      DropdownMenuItem(value: 'FACULTY', child: Text('Faculty')),
                      DropdownMenuItem(value: 'ADMIN', child: Text('Admin')),
                    ],
                    onChanged: (v) => setState(() => role = v!),
                  ),
                ]),
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            LoadingButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                setState(() => isLoading = true);
                final result = await AdminActions.createUser({
                  'firstName': firstCtrl.text,
                  'lastName': lastCtrl.text,
                  'email': emailCtrl.text,
                  'institutionalId': idCtrl.text.isNotEmpty ? idCtrl.text : null,
                  'role': role,
                });
                setState(() => isLoading = false);
                result.when(
                  success: (_) {
                    ref.invalidate(usersProvider);
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('User created successfully.')),
                    );
                  },
                  failure: (e) {
                    setState(() => isLoading = false);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(e), backgroundColor: AppTheme.error),
                    );
                  },
                );
              },
              isLoading: isLoading,
              label: 'Create',
            ),
          ],
        ),
      ),
    );
  }

  void _showBulkImportInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Bulk Import'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('To bulk import students:'),
            SizedBox(height: 8),
            Text('1. Download the student template from\n   GET /api/v1/bulk/templates/students'),
            SizedBox(height: 4),
            Text('2. Fill in the Excel/CSV file'),
            SizedBox(height: 4),
            Text('3. Upload to\n   POST /api/v1/bulk/students'),
            SizedBox(height: 8),
            Text('Row-level validation errors will be\nreturned before any commit.',
                style: TextStyle(color: Color(0xFF6B7280))),
          ],
        ),
        actions: [TextButton(onPressed: Navigator.of(context).pop, child: const Text('Got it'))],
      ),
    );
  }
}
