import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:obe_tracker/core/api/api_client.dart';
import 'package:obe_tracker/core/theme/app_theme.dart';
import 'package:obe_tracker/features/shared/widgets/app_scaffold.dart';
import 'package:obe_tracker/features/shared/widgets/empty_state.dart';
import 'package:obe_tracker/features/shared/widgets/loading_button.dart';
import '../models/admin_models.dart';
import '../providers/admin_providers.dart';

const _adminNavItems = [
  NavItem(label: 'Dashboard', icon: Icons.dashboard_outlined, selectedIcon: Icons.dashboard, route: '/admin/dashboard'),
  NavItem(label: 'Structure', icon: Icons.account_tree_outlined, selectedIcon: Icons.account_tree, route: '/admin/structure'),
  NavItem(label: 'Courses', icon: Icons.book_outlined, selectedIcon: Icons.book, route: '/admin/courses'),
  NavItem(label: 'Users', icon: Icons.people_outlined, selectedIcon: Icons.people, route: '/admin/users'),
  NavItem(label: 'Outcomes', icon: Icons.track_changes_outlined, selectedIcon: Icons.track_changes, route: '/admin/outcomes'),
];

// Filter state: sessionId + programId
class _CourseFilters {
  final String? sessionId;
  final String? programId;
  const _CourseFilters({this.sessionId, this.programId});
  Map<String, String>? toQuery() {
    final m = <String, String>{};
    if (sessionId != null) m['sessionId'] = sessionId!;
    if (programId != null) m['programId'] = programId!;
    return m.isEmpty ? null : m;
  }
}

final _courseFiltersProvider =
    StateProvider<_CourseFilters>((ref) => const _CourseFilters());

class AdminCoursesScreen extends ConsumerWidget {
  const AdminCoursesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(_courseFiltersProvider);
    final coursesAsync = ref.watch(coursesProvider(filters.toQuery()));
    final sessionsAsync = ref.watch(sessionsProvider);
    final programsAsync = ref.watch(programsProvider);

    return AppScaffold(
      title: 'Course Management',
      navItems: _adminNavItems,
      currentRoute: '/admin/courses',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddCourseDialog(context, ref,
            sessionsAsync.value ?? [], programsAsync.value ?? []),
        icon: const Icon(Icons.add),
        label: const Text('Add Course'),
      ),
      body: Column(
        children: [
          // Filters bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(children: [
              Expanded(
                child: sessionsAsync.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (_, __) => const SizedBox(),
                  data: (sessions) => DropdownButtonFormField<String?>(
                    value: filters.sessionId,
                    decoration: const InputDecoration(
                      labelText: 'Session',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('All Sessions')),
                      ...sessions.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))),
                    ],
                    onChanged: (v) => ref.read(_courseFiltersProvider.notifier).state =
                        _CourseFilters(sessionId: v, programId: filters.programId),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: programsAsync.when(
                  loading: () => const SizedBox(),
                  error: (_, __) => const SizedBox(),
                  data: (programs) => DropdownButtonFormField<String?>(
                    value: filters.programId,
                    decoration: const InputDecoration(
                      labelText: 'Program',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('All Programs')),
                      ...programs.map((p) => DropdownMenuItem(value: p.id, child: Text(p.code))),
                    ],
                    onChanged: (v) => ref.read(_courseFiltersProvider.notifier).state =
                        _CourseFilters(sessionId: filters.sessionId, programId: v),
                  ),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 8),

          // Course list
          Expanded(
            child: coursesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (courses) => courses.isEmpty
                  ? EmptyState(
                      icon: Icons.book_outlined,
                      title: 'No courses found',
                      subtitle: 'Add a course or change your filters.',
                      actionLabel: 'Add Course',
                      onAction: () => _showAddCourseDialog(context, ref,
                          sessionsAsync.value ?? [], programsAsync.value ?? []),
                    )
                  : RefreshIndicator(
                      onRefresh: () => ref.refresh(coursesProvider(filters.toQuery()).future),
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                        itemCount: courses.length,
                        itemBuilder: (_, i) => _CourseCard(
                          course: courses[i],
                          onFacultyAssign: (courseId, facultyIds) async {
                            final result = await AdminActions.assignFaculty(courseId, facultyIds);
                            result.when(
                              success: (_) {
                                ref.invalidate(coursesProvider);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Faculty assigned successfully')));
                              },
                              failure: (e) => ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(e), backgroundColor: AppTheme.error)),
                            );
                          },
                          onDelete: (courseId) async {
                            // Soft-delete via update
                            final result = await AdminActions.deleteCourse(courseId);
                            result.when(
                              success: (_) => ref.invalidate(coursesProvider(filters.toQuery())),
                              failure: (e) => ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(e), backgroundColor: AppTheme.error)),
                            );
                          },
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddCourseDialog(BuildContext context, WidgetRef ref,
      List<AcademicSession> sessions, List<Program> programs) async {
    if (sessions.isEmpty || programs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Create at least one session and program first.')));
      return;
    }
    final nameCtrl = TextEditingController();
    final codeCtrl = TextEditingController();
    final creditsCtrl = TextEditingController(text: '3');
    String sessionId = sessions.first.id;
    String programId = programs.first.id;
    bool isLoading = false;
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Add Course'),
          content: SizedBox(
            width: 400,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  DropdownButtonFormField<String>(
                    value: sessionId,
                    decoration: const InputDecoration(labelText: 'Session'),
                    items: sessions.map((s) =>
                        DropdownMenuItem(value: s.id, child: Text(s.name))).toList(),
                    onChanged: (v) => setState(() => sessionId = v!),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: programId,
                    decoration: const InputDecoration(labelText: 'Program'),
                    items: programs.map((p) =>
                        DropdownMenuItem(value: p.id, child: Text('${p.code} — ${p.name}'))).toList(),
                    onChanged: (v) => setState(() => programId = v!),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Course Name'),
                    validator: (v) => v?.isEmpty == true ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: TextFormField(
                      controller: codeCtrl,
                      decoration: const InputDecoration(labelText: 'Code (e.g. CSE301)'),
                      textCapitalization: TextCapitalization.characters,
                      validator: (v) => v?.isEmpty == true ? 'Required' : null,
                    )),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 90,
                      child: TextFormField(
                        controller: creditsCtrl,
                        decoration: const InputDecoration(labelText: 'Credits'),
                        keyboardType: TextInputType.number,
                        validator: (v) => v?.isEmpty == true ? 'Required' : null,
                      ),
                    ),
                  ]),
                ]),
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            LoadingButton(
              isLoading: isLoading,
              label: 'Add Course',
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                setState(() => isLoading = true);
                final result = await AdminActions.createCourse(
                  programId, sessionId, nameCtrl.text, codeCtrl.text,
                  int.tryParse(creditsCtrl.text) ?? 3,
                );
                setState(() => isLoading = false);
                result.when(
                  success: (_) {
                    final f = ref.read(_courseFiltersProvider);
                    ref.invalidate(coursesProvider(f.toQuery()));
                    Navigator.pop(ctx);
                  },
                  failure: (e) => ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e), backgroundColor: AppTheme.error)),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _CourseCard extends StatelessWidget {
  final Course course;
  final Future<void> Function(String courseId, List<String> facultyIds) onFacultyAssign;
  final Future<void> Function(String courseId) onDelete;

  const _CourseCard({
    required this.course,
    required this.onFacultyAssign,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final assignedFaculty = course.assignments
        .map((a) => a['faculty'] as Map<String, dynamic>?)
        .whereType<Map<String, dynamic>>()
        .toList();

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: AppTheme.info.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.book_outlined, color: AppTheme.info, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(course.name, style: Theme.of(context).textTheme.titleMedium),
              Text(
                '${course.code}  ·  ${course.creditHours} credits',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ])),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, size: 20),
              onSelected: (v) {
                if (v == 'assign') _showAssignDialog(context);
                if (v == 'delete') _confirmDelete(context);
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'assign', child: Row(children: [
                  Icon(Icons.person_add_outlined, size: 16), SizedBox(width: 8), Text('Assign Faculty'),
                ])),
                PopupMenuItem(value: 'delete', child: Row(children: [
                  Icon(Icons.delete_outline, size: 16, color: AppTheme.error),
                  SizedBox(width: 8), Text('Delete', style: TextStyle(color: AppTheme.error)),
                ])),
              ],
            ),
          ]),

          // Metadata row
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 4, children: [
            _MetaChip(
              icon: Icons.school_outlined,
              label: course.program?['name'] ?? 'Unknown Program',
              color: AppTheme.primaryGreen,
            ),
            _MetaChip(
              icon: Icons.calendar_month_outlined,
              label: course.session?['name'] ?? 'Unknown Session',
              color: AppTheme.warning,
            ),
          ]),

          // Assigned faculty
          if (assignedFaculty.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(children: [
              const Icon(Icons.person_outline, size: 14, color: Color(0xFF6B7280)),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  assignedFaculty.map((f) => '${f['firstName']} ${f['lastName']}').join(', '),
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ]),
          ] else ...[
            const SizedBox(height: 6),
            GestureDetector(
              onTap: () => _showAssignDialog(context),
              child: Row(children: [
                const Icon(Icons.warning_amber_outlined, size: 14, color: AppTheme.warning),
                const SizedBox(width: 4),
                Text('No faculty assigned — tap to assign',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.warning)),
              ]),
            ),
          ],
        ]),
      ),
    );
  }

  Future<void> _showAssignDialog(BuildContext context) async {
    // Show loading dialog while fetching faculty
    List<AppUser> faculty = [];
    bool fetchError = false;
    try {
      final res = await ApiClient().get('/admin/users', queryParameters: {'role': 'FACULTY'});
      faculty = (res.data['data'] as List).map((j) => AppUser.fromJson(j)).toList();
    } catch (_) {
      fetchError = true;
    }

    if (!context.mounted) return;

    if (fetchError || faculty.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('No faculty users found. Create faculty users first.')));
      return;
    }

    final selected = Set<String>.from(course.assignedFacultyIds);
    bool isLoading = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text('Assign Faculty to ${course.code}'),
          content: SizedBox(
            width: 360,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: faculty.map((f) => CheckboxListTile(
                  title: Text(f.fullName),
                  subtitle: Text(f.email),
                  value: selected.contains(f.id),
                  onChanged: (v) => setState(() {
                    if (v == true) selected.add(f.id);
                    else selected.remove(f.id);
                  }),
                )).toList(),
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            LoadingButton(
              isLoading: isLoading,
              label: 'Save',
              onPressed: () async {
                setState(() => isLoading = true);
                await onFacultyAssign(course.id, selected.toList());
                setState(() => isLoading = false);
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Course'),
        content: Text('Delete "${course.name}"? This will deactivate the course.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) await onDelete(course.id);
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _MetaChip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: color.withOpacity(0.08),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 12, color: color),
      const SizedBox(width: 4),
      Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500)),
    ]),
  );
}
