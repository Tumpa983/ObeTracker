import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

final _selectedProgramProvider = StateProvider<String?>((ref) => null);

class AdminOutcomesScreen extends ConsumerStatefulWidget {
  const AdminOutcomesScreen({super.key});
  @override
  ConsumerState<AdminOutcomesScreen> createState() => _AdminOutcomesScreenState();
}

class _AdminOutcomesScreenState extends ConsumerState<AdminOutcomesScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;
  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }
  @override
  void dispose() { _tabCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Program Outcomes & Thresholds',
      navItems: _adminNavItems,
      currentRoute: '/admin/outcomes',
      body: Column(children: [
        TabBar(controller: _tabCtrl, tabs: const [
          Tab(icon: Icon(Icons.track_changes_outlined, size: 18), text: 'Program Outcomes'),
          Tab(icon: Icon(Icons.tune_outlined, size: 18), text: 'Thresholds'),
        ]),
        Expanded(child: TabBarView(controller: _tabCtrl, children: [
          const _ProgramOutcomesTab(),
          const _ThresholdsTab(),
        ])),
      ]),
    );
  }
}

// ── Program Outcomes Tab ─────────────────────────────────────
class _ProgramOutcomesTab extends ConsumerWidget {
  const _ProgramOutcomesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final programsAsync = ref.watch(programsProvider);
    final selectedProgramId = ref.watch(_selectedProgramProvider);

    return Column(children: [
      // Program selector
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: programsAsync.when(
          loading: () => const LinearProgressIndicator(),
          error: (_, __) => const SizedBox(),
          data: (programs) {
            // Auto-select first program
            if (selectedProgramId == null && programs.isNotEmpty) {
              WidgetsBinding.instance.addPostFrameCallback((_) =>
                  ref.read(_selectedProgramProvider.notifier).state = programs.first.id);
            }
            return Row(children: [
              const Icon(Icons.school_outlined, size: 18, color: AppTheme.primaryGreen),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButton<String?>(
                  value: selectedProgramId,
                  isExpanded: true,
                  underline: const SizedBox(),
                  hint: const Text('Select a program'),
                  items: programs.map((p) => DropdownMenuItem(
                    value: p.id,
                    child: Text('${p.code} — ${p.name}'),
                  )).toList(),
                  onChanged: (v) =>
                      ref.read(_selectedProgramProvider.notifier).state = v,
                ),
              ),
              if (selectedProgramId != null)
                FilledButton.icon(
                  onPressed: () => _showAddPODialog(context, ref, selectedProgramId),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add PO'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(90, 36),
                    backgroundColor: AppTheme.primaryGreen,
                  ),
                ),
            ]);
          },
        ),
      ),
      const SizedBox(height: 4),
      const Divider(height: 1),

      // PO list for selected program
      Expanded(
        child: selectedProgramId == null
            ? const Center(child: Text('Select a program above to manage its outcomes.',
                style: TextStyle(color: Color(0xFF6B7280))))
            : _POList(programId: selectedProgramId),
      ),
    ]);
  }

  Future<void> _showAddPODialog(BuildContext context, WidgetRef ref, String programId) async {
    final codeCtrl = TextEditingController();
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    bool isLoading = false;
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Add Program Outcome'),
          content: SizedBox(
            width: 400,
            child: Form(
              key: formKey,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Row(children: [
                  SizedBox(
                    width: 90,
                    child: TextFormField(
                      controller: codeCtrl,
                      decoration: const InputDecoration(labelText: 'Code'),
                      validator: (v) => v?.isEmpty == true ? 'Req.' : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: TextFormField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(labelText: 'Title'),
                    validator: (v) => v?.isEmpty == true ? 'Required' : null,
                  )),
                ]),
                const SizedBox(height: 12),
                TextFormField(
                  controller: descCtrl,
                  decoration: const InputDecoration(labelText: 'Description (optional)'),
                  maxLines: 3,
                ),
              ]),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            LoadingButton(
              isLoading: isLoading,
              label: 'Add PO',
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                setState(() => isLoading = true);
                final result = await AdminActions.createProgramOutcome(
                  programId, codeCtrl.text, titleCtrl.text,
                  descCtrl.text.isNotEmpty ? descCtrl.text : null,
                );
                setState(() => isLoading = false);
                result.when(
                  success: (_) {
                    ref.invalidate(programOutcomesProvider(programId));
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

class _POList extends ConsumerWidget {
  final String programId;
  const _POList({required this.programId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final posAsync = ref.watch(programOutcomesProvider(programId));
    return posAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (pos) => pos.isEmpty
          ? EmptyState(
              icon: Icons.track_changes_outlined,
              title: 'No program outcomes yet',
              subtitle: 'Define PO1–PO12 (or your program\'s outcomes) to enable CO–PO mapping.',
              actionLabel: 'Add PO',
              onAction: () => _showAddPODialog(context, ref, programId),
            )
          : ReorderableListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              itemCount: pos.length,
              onReorder: (_, __) {}, // UI-only reorder for now
              itemBuilder: (_, i) => _POCard(key: ValueKey(pos[i].id), po: pos[i],
                  programId: programId, ref: ref),
            ),
    );
  }

  Future<void> _showAddPODialog(BuildContext context, WidgetRef ref, String programId) async {
    // Delegate to parent tab
    final codeCtrl = TextEditingController();
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    bool isLoading = false;
    final formKey = GlobalKey<FormState>();
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Add Program Outcome'),
          content: Form(
            key: formKey,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Row(children: [
                SizedBox(width: 90, child: TextFormField(controller: codeCtrl,
                  decoration: const InputDecoration(labelText: 'Code'),
                  validator: (v) => v?.isEmpty == true ? 'Req.' : null)),
                const SizedBox(width: 10),
                Expanded(child: TextFormField(controller: titleCtrl,
                  decoration: const InputDecoration(labelText: 'Title'),
                  validator: (v) => v?.isEmpty == true ? 'Required' : null)),
              ]),
              const SizedBox(height: 12),
              TextFormField(controller: descCtrl,
                decoration: const InputDecoration(labelText: 'Description (optional)'),
                maxLines: 2),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            LoadingButton(isLoading: isLoading, label: 'Add PO', onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              setState(() => isLoading = true);
              final result = await AdminActions.createProgramOutcome(
                  programId, codeCtrl.text, titleCtrl.text,
                  descCtrl.text.isNotEmpty ? descCtrl.text : null);
              setState(() => isLoading = false);
              result.when(success: (_) { ref.invalidate(programOutcomesProvider(programId)); Navigator.pop(ctx); },
                failure: (e) => ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(e), backgroundColor: AppTheme.error)));
            }),
          ],
        ),
      ),
    );
  }
}

class _POCard extends StatelessWidget {
  final ProgramOutcome po;
  final String programId;
  final WidgetRef ref;
  const _POCard({super.key, required this.po, required this.programId, required this.ref});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(children: [
          // Drag handle
          const Icon(Icons.drag_handle, color: Color(0xFFD1D5DB), size: 20),
          const SizedBox(width: 10),
          // PO code badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(po.code,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
          ),
          const SizedBox(width: 12),
          // Content
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(po.title, style: Theme.of(context).textTheme.titleMedium),
            if (po.description != null && po.description!.isNotEmpty)
              Text(po.description!,
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 2, overflow: TextOverflow.ellipsis),
          ])),
          // Actions
          Row(mainAxisSize: MainAxisSize.min, children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 18),
              tooltip: 'Edit',
              onPressed: () => _showEditDialog(context),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 18, color: AppTheme.error),
              tooltip: 'Delete',
              onPressed: () => _confirmDelete(context),
            ),
          ]),
        ]),
      ),
    );
  }

  Future<void> _showEditDialog(BuildContext context) async {
    final codeCtrl = TextEditingController(text: po.code);
    final titleCtrl = TextEditingController(text: po.title);
    final descCtrl = TextEditingController(text: po.description ?? '');
    bool isLoading = false;
    final formKey = GlobalKey<FormState>();
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Edit Program Outcome'),
          content: Form(
            key: formKey,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Row(children: [
                SizedBox(width: 90, child: TextFormField(controller: codeCtrl,
                  decoration: const InputDecoration(labelText: 'Code'),
                  validator: (v) => v?.isEmpty == true ? 'Req.' : null)),
                const SizedBox(width: 10),
                Expanded(child: TextFormField(controller: titleCtrl,
                  decoration: const InputDecoration(labelText: 'Title'),
                  validator: (v) => v?.isEmpty == true ? 'Required' : null)),
              ]),
              const SizedBox(height: 12),
              TextFormField(controller: descCtrl,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 2),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            LoadingButton(isLoading: isLoading, label: 'Save', onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              setState(() => isLoading = true);
              final result = await AdminActions.updateProgramOutcome(po.id,
                  codeCtrl.text, titleCtrl.text,
                  descCtrl.text.isNotEmpty ? descCtrl.text : null);
              setState(() => isLoading = false);
              result.when(success: (_) { ref.invalidate(programOutcomesProvider(programId)); Navigator.pop(ctx); },
                failure: (e) => ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(e), backgroundColor: AppTheme.error)));
            }),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete PO'),
        content: Text('Delete ${po.code}? This will fail if it has CO–PO mappings.'),
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
    if (confirmed == true) {
      final result = await AdminActions.deleteProgramOutcome(po.id);
      result.when(
        success: (_) => ref.invalidate(programOutcomesProvider(programId)),
        failure: (e) => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e), backgroundColor: AppTheme.error)),
      );
    }
  }
}

// ── Thresholds Tab ───────────────────────────────────────────
class _ThresholdsTab extends ConsumerStatefulWidget {
  const _ThresholdsTab();
  @override
  ConsumerState<_ThresholdsTab> createState() => _ThresholdsTabState();
}

class _ThresholdsTabState extends ConsumerState<_ThresholdsTab> {
  final _l3Ctrl = TextEditingController();
  final _l2Ctrl = TextEditingController();
  final _l1Ctrl = TextEditingController();
  bool _isDirty = false;
  bool _isSaving = false;
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _l3Ctrl.dispose(); _l2Ctrl.dispose(); _l1Ctrl.dispose();
    super.dispose();
  }

  void _initFromData(Map<String, dynamic> data) {
    if (!_isDirty) {
      _l3Ctrl.text = (data['l3Min'] as num).toStringAsFixed(0);
      _l2Ctrl.text = (data['l2Min'] as num).toStringAsFixed(0);
      _l1Ctrl.text = (data['l1Min'] as num).toStringAsFixed(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final thAsync = ref.watch(thresholdsProvider);
    return thAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (data) {
        _initFromData(data);
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Attainment Level Thresholds',
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(
                'Define the minimum percentage score required for each attainment level. '
                'These thresholds apply across the institution. When a session is closed, '
                'thresholds are frozen into the session record.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: const Color(0xFF6B7280)),
              ),
              const SizedBox(height: 28),

              _ThresholdRow(
                level: 'L3',
                label: 'Fully Attained',
                color: AppTheme.l3Color,
                description: 'Student has fully attained the outcome.',
                controller: _l3Ctrl,
                suffix: '% and above',
                onChanged: () => setState(() => _isDirty = true),
              ),
              const SizedBox(height: 16),
              _ThresholdRow(
                level: 'L2',
                label: 'Moderately Attained',
                color: AppTheme.l2Color,
                description: 'Student has moderately attained the outcome.',
                controller: _l2Ctrl,
                suffix: '% to < L3',
                onChanged: () => setState(() => _isDirty = true),
              ),
              const SizedBox(height: 16),
              _ThresholdRow(
                level: 'L1',
                label: 'Partially Attained',
                color: AppTheme.l1Color,
                description: 'Student has partially attained the outcome.',
                controller: _l1Ctrl,
                suffix: '% to < L2',
                onChanged: () => setState(() => _isDirty = true),
              ),
              const SizedBox(height: 16),

              // L0 info (not configurable)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.l0Color.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.l0Color.withOpacity(0.2)),
                ),
                child: Row(children: [
                  Container(
                    width: 52, height: 32,
                    decoration: BoxDecoration(
                      color: AppTheme.l0Color, borderRadius: BorderRadius.circular(6)),
                    child: const Center(
                      child: Text('L0', style: TextStyle(color: Colors.white,
                          fontWeight: FontWeight.w800, fontSize: 14)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Not Attained',
                        style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.l0Color)),
                    Text('Below L1 threshold — automatically calculated.',
                        style: Theme.of(context).textTheme.bodySmall),
                  ])),
                ]),
              ),

              const SizedBox(height: 32),
              if (_isDirty) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.warning.withOpacity(0.3)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.info_outline, color: AppTheme.warning, size: 18),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Changing thresholds will NOT retroactively recompute existing '
                        'attainment records. Recomputation happens on the next mark save or '
                        'mapping change per course.',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ]),
                ),
                const SizedBox(height: 16),
              ],
              LoadingButton(
                isLoading: _isSaving,
                label: 'Save Thresholds',
                icon: Icons.save_outlined,
                onPressed: _isDirty ? _save : null,
              ),
            ]),
          ),
        );
      },
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final l3 = double.tryParse(_l3Ctrl.text);
    final l2 = double.tryParse(_l2Ctrl.text);
    final l1 = double.tryParse(_l1Ctrl.text);
    if (l3 == null || l2 == null || l1 == null) return;
    if (l3 <= l2 || l2 <= l1) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Thresholds must be descending: L3 > L2 > L1'),
          backgroundColor: AppTheme.error));
      return;
    }
    setState(() => _isSaving = true);
    final result = await AdminActions.upsertThresholds(l3, l2, l1);
    setState(() { _isSaving = false; _isDirty = false; });
    result.when(
      success: (_) {
        ref.invalidate(thresholdsProvider);
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Thresholds saved successfully.')));
      },
      failure: (e) => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e), backgroundColor: AppTheme.error)),
    );
  }
}

class _ThresholdRow extends StatelessWidget {
  final String level;
  final String label;
  final Color color;
  final String description;
  final TextEditingController controller;
  final String suffix;
  final VoidCallback onChanged;

  const _ThresholdRow({
    required this.level, required this.label, required this.color,
    required this.description, required this.controller,
    required this.suffix, required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(children: [
        Container(
          width: 52, height: 32,
          decoration: BoxDecoration(
              color: color, borderRadius: BorderRadius.circular(6)),
          child: Center(child: Text(level,
              style: const TextStyle(color: Colors.white,
                  fontWeight: FontWeight.w800, fontSize: 14))),
        ),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: color)),
          Text(description, style: Theme.of(context).textTheme.bodySmall),
        ])),
        const SizedBox(width: 16),
        SizedBox(
          width: 80,
          child: TextFormField(
            controller: controller,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            onChanged: (_) => onChanged(),
            decoration: InputDecoration(
              isDense: true,
              suffixText: '%',
              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: color.withOpacity(0.4)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: color, width: 2),
              ),
            ),
            validator: (v) {
              final n = double.tryParse(v ?? '');
              if (n == null || n < 0 || n > 100) return 'Invalid';
              return null;
            },
          ),
        ),
      ]),
    );
  }
}
