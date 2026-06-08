import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:obe_tracker/core/constants/app_constants.dart';
import 'package:obe_tracker/core/theme/app_theme.dart';
import 'package:obe_tracker/features/shared/widgets/empty_state.dart';
import 'package:obe_tracker/features/shared/widgets/loading_button.dart';
import '../providers/faculty_providers.dart';

class CoManagementScreen extends ConsumerWidget {
  final String courseId;
  const CoManagementScreen({super.key, required this.courseId});

  static const _bloomColors = {
    'COGNITIVE': Color(0xFF3B82F6),
    'AFFECTIVE': Color(0xFF8B5CF6),
    'PSYCHOMOTOR': Color(0xFFF59E0B),
  };

  static const _profileColors = {
    'FUNDAMENTAL': Color(0xFF16A34A),
    'SOCIAL': Color(0xFF0EA5E9),
    'THINKING': Color(0xFFEC4899),
    'PERSONAL': Color(0xFFEA580C),
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cosAsync = ref.watch(courseOutcomesProvider(courseId));

    return cosAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (cos) => cos.isEmpty
          ? EmptyState(
              icon: Icons.track_changes_outlined,
              title: 'No course outcomes yet',
              subtitle: 'Define the learning outcomes for this course.',
              actionLabel: 'Add CO',
              onAction: () => _showAddCODialog(context, ref),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: cos.length + 1,
              itemBuilder: (_, i) {
                if (i == cos.length) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: OutlinedButton.icon(
                      onPressed: () => _showAddCODialog(context, ref),
                      icon: const Icon(Icons.add),
                      label: const Text('Add Course Outcome'),
                    ),
                  );
                }
                final co = cos[i];
                final bloomColor = _bloomColors[co.bloomDomain] ?? Colors.grey;
                final profileColor = _profileColors[co.profileType] ?? Colors.grey;

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryGreen,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(co.code,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(co.title,
                              style: Theme.of(context).textTheme.titleMedium),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFEF4444)),
                          onPressed: () => _confirmDelete(context, ref, co.id, co.code),
                          tooltip: 'Delete CO',
                        ),
                      ]),
                      if (co.description != null && co.description!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(co.description!,
                            style: Theme.of(context).textTheme.bodySmall,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis),
                      ],
                      const SizedBox(height: 8),
                      Wrap(spacing: 6, runSpacing: 4, children: [
                        if (co.bloomDomain != null)
                          _Tag(
                            label: '${AppConstants.bloomDomainLabels[co.bloomDomain]!.split(' ')[1].replaceAll('(', '').replaceAll(')', '')}${co.bloomLevel ?? ''}',
                            color: bloomColor,
                            tooltip: '${AppConstants.bloomDomainLabels[co.bloomDomain]} Level ${co.bloomLevel}',
                          ),
                        if (co.profileType != null)
                          _Tag(
                            label: co.profileCode ?? co.profileType!,
                            color: profileColor,
                            tooltip: AppConstants.profileTypeLabels[co.profileType] ?? '',
                          ),
                      ]),
                    ]),
                  ),
                );
              },
            ),
    );
  }

  Future<void> _showAddCODialog(BuildContext context, WidgetRef ref) async {
    final codeCtrl = TextEditingController();
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final profileCodeCtrl = TextEditingController();
    String? bloomDomain;
    int? bloomLevel;
    String? profileType;
    bool isLoading = false;
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Add Course Outcome'),
          content: SizedBox(
            width: 420,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
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
                    maxLines: 2,
                  ),
                  const Divider(height: 24),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text("Bloom's Taxonomy",
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  ),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: bloomDomain,
                        decoration: const InputDecoration(labelText: 'Domain'),
                        items: const [
                          DropdownMenuItem(value: null, child: Text('None')),
                          DropdownMenuItem(value: 'COGNITIVE', child: Text('Cognitive')),
                          DropdownMenuItem(value: 'AFFECTIVE', child: Text('Affective')),
                          DropdownMenuItem(value: 'PSYCHOMOTOR', child: Text('Psychomotor')),
                        ],
                        onChanged: (v) => setState(() => bloomDomain = v),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: bloomLevel,
                        decoration: const InputDecoration(labelText: 'Level'),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('None')),
                          ...List.generate(6, (i) => DropdownMenuItem(value: i + 1, child: Text('${i + 1}'))),
                        ],
                        onChanged: (v) => setState(() => bloomLevel = v),
                      ),
                    ),
                  ]),
                  const Divider(height: 24),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Profile Classification',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  ),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: profileType,
                        decoration: const InputDecoration(labelText: 'Profile'),
                        items: const [
                          DropdownMenuItem(value: null, child: Text('None')),
                          DropdownMenuItem(value: 'FUNDAMENTAL', child: Text('Fundamental')),
                          DropdownMenuItem(value: 'SOCIAL', child: Text('Social')),
                          DropdownMenuItem(value: 'THINKING', child: Text('Thinking')),
                          DropdownMenuItem(value: 'PERSONAL', child: Text('Personal')),
                        ],
                        onChanged: (v) => setState(() => profileType = v),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: profileCodeCtrl,
                        decoration: const InputDecoration(labelText: 'Profile Code (e.g. F1)'),
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
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                setState(() => isLoading = true);
                final result = await FacultyActions.createCO(courseId, {
                  'code': codeCtrl.text,
                  'title': titleCtrl.text,
                  'description': descCtrl.text.isNotEmpty ? descCtrl.text : null,
                  'bloomDomain': bloomDomain,
                  'bloomLevel': bloomLevel,
                  'profileType': profileType,
                  'profileCode': profileCodeCtrl.text.isNotEmpty ? profileCodeCtrl.text : null,
                });
                setState(() => isLoading = false);
                result.when(
                  success: (_) { ref.invalidate(courseOutcomesProvider(courseId)); Navigator.pop(ctx); },
                  failure: (e) => ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e), backgroundColor: AppTheme.error),
                  ),
                );
              },
              label: 'Add CO',
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, String coId, String coCode) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete CO'),
        content: Text('Delete $coCode? This cannot be undone if it has no mappings or assessments.'),
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
      final result = await FacultyActions.deleteCO(courseId, coId);
      result.when(
        success: (_) => ref.invalidate(courseOutcomesProvider(courseId)),
        failure: (e) => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e), backgroundColor: AppTheme.error),
        ),
      );
    }
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final Color color;
  final String tooltip;

  const _Tag({required this.label, required this.color, required this.tooltip});

  @override
  Widget build(BuildContext context) => Tooltip(
        message: tooltip,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Text(label,
              style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
        ),
      );
}
