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

class AdminStructureScreen extends ConsumerStatefulWidget {
  const AdminStructureScreen({super.key});

  @override
  ConsumerState<AdminStructureScreen> createState() => _AdminStructureScreenState();
}

class _AdminStructureScreenState extends ConsumerState<AdminStructureScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Institutional Structure',
      navItems: _adminNavItems,
      currentRoute: '/admin/structure',
      body: Column(
        children: [
          TabBar(
            controller: _tabCtrl,
            tabs: const [
              Tab(text: 'Departments'),
              Tab(text: 'Programs'),
              Tab(text: 'Sessions'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                _DepartmentsTab(),
                _ProgramsTab(),
                _SessionsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Departments Tab ──────────────────────────────────────────
class _DepartmentsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(departmentsProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (depts) => depts.isEmpty
          ? EmptyState(
              icon: Icons.apartment_outlined,
              title: 'No departments yet',
              subtitle: 'Add your first department to get started.',
              actionLabel: 'Add Department',
              onAction: () => _showAddDeptDialog(context, ref),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: depts.length + 1,
              itemBuilder: (_, i) {
                if (i == depts.length) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: OutlinedButton.icon(
                      onPressed: () => _showAddDeptDialog(context, ref),
                      icon: const Icon(Icons.add),
                      label: const Text('Add Department'),
                    ),
                  );
                }
                final dept = depts[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(dept.code[0],
                            style: const TextStyle(
                                color: AppTheme.primaryGreen, fontWeight: FontWeight.w700)),
                      ),
                    ),
                    title: Text(dept.name),
                    subtitle: Text('Code: ${dept.code}'),
                    trailing: dept.isActive
                        ? const Chip(
                            label: Text('Active'),
                            backgroundColor: Color(0xFFDCFCE7),
                            labelStyle: TextStyle(color: Color(0xFF16A34A), fontSize: 11),
                            visualDensity: VisualDensity.compact,
                          )
                        : const Chip(
                            label: Text('Inactive'),
                            backgroundColor: Color(0xFFF3F4F6),
                            labelStyle: TextStyle(color: Color(0xFF6B7280), fontSize: 11),
                            visualDensity: VisualDensity.compact,
                          ),
                  ),
                );
              },
            ),
    );
  }

  Future<void> _showAddDeptDialog(BuildContext context, WidgetRef ref) async {
    final nameCtrl = TextEditingController();
    final codeCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isLoading = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Add Department'),
          content: Form(
            key: formKey,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Department Name'),
                validator: (v) => v?.isEmpty == true ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: codeCtrl,
                decoration: const InputDecoration(labelText: 'Code (e.g. CSE)'),
                textCapitalization: TextCapitalization.characters,
                validator: (v) => v?.isEmpty == true ? 'Required' : null,
              ),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            LoadingButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                setState(() => isLoading = true);
                final result = await AdminActions.createDepartment(nameCtrl.text, codeCtrl.text);
                setState(() => isLoading = false);
                result.when(
                  success: (_) {
                    ref.invalidate(departmentsProvider);
                    Navigator.pop(ctx);
                  },
                  failure: (e) => ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e), backgroundColor: AppTheme.error),
                  ),
                );
              },
              isLoading: isLoading,
              label: 'Add',
            ),
          ],
        ),
      ),
    );
  }
}

// ── Programs Tab ─────────────────────────────────────────────
class _ProgramsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(programsProvider);
    final deptsAsync = ref.watch(departmentsProvider);

    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (programs) => ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: programs.length + 1,
        itemBuilder: (_, i) {
          if (i == programs.length) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: OutlinedButton.icon(
                onPressed: deptsAsync.value?.isEmpty == false
                    ? () => _showAddProgramDialog(context, ref, deptsAsync.value!)
                    : null,
                icon: const Icon(Icons.add),
                label: const Text('Add Program'),
              ),
            );
          }
          final prog = programs[i];
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFDCFCE7),
                child: Icon(Icons.school_outlined, color: AppTheme.primaryGreen, size: 20),
              ),
              title: Text(prog.name),
              subtitle: Text('Code: ${prog.code}'),
              trailing: const Icon(Icons.chevron_right, color: Color(0xFF9CA3AF)),
            ),
          );
        },
      ),
    );
  }

  Future<void> _showAddProgramDialog(
      BuildContext context, WidgetRef ref, List<Department> depts) async {
    final nameCtrl = TextEditingController();
    final codeCtrl = TextEditingController();
    String? selectedDeptId = depts.isNotEmpty ? depts.first.id : null;
    final formKey = GlobalKey<FormState>();
    bool isLoading = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Add Program'),
          content: Form(
            key: formKey,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              DropdownButtonFormField<String>(
                value: selectedDeptId,
                decoration: const InputDecoration(labelText: 'Department'),
                items: depts.map((d) => DropdownMenuItem(value: d.id, child: Text(d.name))).toList(),
                onChanged: (v) => setState(() => selectedDeptId = v),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Program Name'),
                validator: (v) => v?.isEmpty == true ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: codeCtrl,
                decoration: const InputDecoration(labelText: 'Code (e.g. BSCS)'),
                textCapitalization: TextCapitalization.characters,
                validator: (v) => v?.isEmpty == true ? 'Required' : null,
              ),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            LoadingButton(
              onPressed: () async {
                if (!formKey.currentState!.validate() || selectedDeptId == null) return;
                setState(() => isLoading = true);
                final result = await AdminActions.createProgram(selectedDeptId!, nameCtrl.text, codeCtrl.text);
                setState(() => isLoading = false);
                result.when(
                  success: (_) { ref.invalidate(programsProvider); Navigator.pop(ctx); },
                  failure: (e) => ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e), backgroundColor: AppTheme.error),
                  ),
                );
              },
              isLoading: isLoading,
              label: 'Add',
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sessions Tab ─────────────────────────────────────────────
class _SessionsTab extends ConsumerWidget {
  static const _statusColors = {
    'ACTIVE': Color(0xFF16A34A),
    'DRAFT': Color(0xFF6B7280),
    'CLOSED': Color(0xFFF59E0B),
    'ARCHIVED': Color(0xFF9CA3AF),
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(sessionsProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (sessions) => ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: sessions.length + 1,
        itemBuilder: (_, i) {
          if (i == sessions.length) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: OutlinedButton.icon(
                onPressed: () => _showAddSessionDialog(context, ref),
                icon: const Icon(Icons.add),
                label: const Text('Add Session'),
              ),
            );
          }
          final s = sessions[i];
          final color = _statusColors[s.status] ?? const Color(0xFF6B7280);
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFFFF9E6),
                child: Icon(Icons.calendar_month_outlined, color: AppTheme.warning, size: 20),
              ),
              title: Text(s.name),
              subtitle: Text('Status: ${s.status}'),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(s.status,
                    style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _showAddSessionDialog(BuildContext context, WidgetRef ref) async {
    final nameCtrl = TextEditingController();
    DateTime startDate = DateTime.now();
    final formKey = GlobalKey<FormState>();
    bool isLoading = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Add Session'),
          content: Form(
            key: formKey,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Session Name (e.g. Spring 2026)'),
                validator: (v) => v?.isEmpty == true ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Start: ${startDate.toLocal().toString().split(' ')[0]}'),
                trailing: const Icon(Icons.calendar_today_outlined),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: startDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (picked != null) setState(() => startDate = picked);
                },
              ),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            LoadingButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                setState(() => isLoading = true);
                final result = await AdminActions.createSession(nameCtrl.text, startDate.toIso8601String());
                setState(() => isLoading = false);
                result.when(
                  success: (_) { ref.invalidate(sessionsProvider); Navigator.pop(ctx); },
                  failure: (e) => ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e), backgroundColor: AppTheme.error),
                  ),
                );
              },
              isLoading: isLoading,
              label: 'Add',
            ),
          ],
        ),
      ),
    );
  }
}
