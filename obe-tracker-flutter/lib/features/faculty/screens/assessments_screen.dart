import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:obe_tracker/core/constants/app_constants.dart';
import 'package:obe_tracker/core/theme/app_theme.dart';
import 'package:obe_tracker/features/shared/widgets/empty_state.dart';
import 'package:obe_tracker/features/shared/widgets/loading_button.dart';
import '../models/faculty_models.dart';
import '../providers/faculty_providers.dart';

class AssessmentsScreen extends ConsumerWidget {
  final String courseId;
  const AssessmentsScreen({super.key, required this.courseId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncData = ref.watch(assessmentsProvider(courseId));

    return asyncData.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (data) {
        final assessments = (data['assessments'] as List)
            .map((j) => Assessment.fromJson(j))
            .toList();
        final weightSum = (data['weightSum'] as num?)?.toDouble() ?? 0;
        final weightWarning = data['weightWarning'] == true;

        return Column(
          children: [
            if (weightWarning)
              Container(
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.warning.withOpacity(0.4)),
                ),
                child: Row(children: [
                  const Icon(Icons.warning_amber_outlined, color: AppTheme.warning, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Total assessment weight is ${weightSum.toStringAsFixed(1)}% (should be 100%). Attainment computation requires exactly 100%.',
                      style: const TextStyle(color: AppTheme.warning, fontSize: 13),
                    ),
                  ),
                ]),
              ),
            Expanded(
              child: assessments.isEmpty
                  ? EmptyState(
                      icon: Icons.assignment_outlined,
                      title: 'No assessments yet',
                      subtitle: 'Add assessments and map them to course outcomes.',
                      actionLabel: 'Add Assessment',
                      onAction: () => _showAddDialog(context, ref),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: assessments.length + 1,
                      itemBuilder: (_, i) {
                        if (i == assessments.length) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: OutlinedButton.icon(
                              onPressed: () => _showAddDialog(context, ref),
                              icon: const Icon(Icons.add),
                              label: const Text('Add Assessment'),
                            ),
                          );
                        }
                        final a = assessments[i];
                        final coLabels = a.assessmentCOs
                            .map((aco) => aco['courseOutcome']?['code'] ?? '')
                            .where((c) => c.isNotEmpty)
                            .join(', ');
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppTheme.info.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.assignment_outlined, color: AppTheme.info, size: 22),
                            ),
                            title: Text(a.title),
                            subtitle: Text(
                              '${a.type.replaceAll('_', ' ')} · ${a.totalMarks.toStringAsFixed(0)} marks · ${a.weight.toStringAsFixed(1)}% weight'
                              '${coLabels.isNotEmpty ? '\nMaps to: $coLabels' : ''}',
                            ),
                            isThreeLine: coLabels.isNotEmpty,
                            trailing: ElevatedButton.icon(
                              onPressed: () => context.go('/faculty/courses/$courseId/assessments/${a.id}/marks'),
                              icon: const Icon(Icons.edit_outlined, size: 16),
                              label: const Text('Marks'),
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(90, 36),
                                textStyle: const TextStyle(fontSize: 13),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showAddDialog(BuildContext context, WidgetRef ref) async {
    final titleCtrl = TextEditingController();
    final marksCtrl = TextEditingController(text: '100');
    final weightCtrl = TextEditingController(text: '25');
    String type = 'MID_TERM';
    List<String> selectedCOs = [];
    bool isLoading = false;
    final formKey = GlobalKey<FormState>();

    final cosAsync = ref.watch(courseOutcomesProvider(courseId));
    final cos = cosAsync.value ?? [];

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Add Assessment'),
          content: SizedBox(
            width: 420,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  TextFormField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(labelText: 'Title'),
                    validator: (v) => v?.isEmpty == true ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: type,
                    decoration: const InputDecoration(labelText: 'Type'),
                    items: AppConstants.assessmentTypes.map((t) => DropdownMenuItem(
                      value: t, child: Text(t.replaceAll('_', ' ')),
                    )).toList(),
                    onChanged: (v) => setState(() => type = v!),
                  ),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: TextFormField(
                      controller: marksCtrl,
                      decoration: const InputDecoration(labelText: 'Total Marks'),
                      keyboardType: TextInputType.number,
                      validator: (v) => v?.isEmpty == true ? 'Required' : null,
                    )),
                    const SizedBox(width: 10),
                    Expanded(child: TextFormField(
                      controller: weightCtrl,
                      decoration: const InputDecoration(labelText: 'Weight (%)'),
                      keyboardType: TextInputType.number,
                      validator: (v) => v?.isEmpty == true ? 'Required' : null,
                    )),
                  ]),
                  const SizedBox(height: 12),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Map to Course Outcomes',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  ),
                  const SizedBox(height: 8),
                  if (cos.isEmpty)
                    const Text('No COs defined yet. Add them in the Outcomes tab.',
                        style: TextStyle(color: Color(0xFF6B7280), fontSize: 13))
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: cos.map((co) {
                        final selected = selectedCOs.contains(co.id);
                        return FilterChip(
                          label: Text(co.code),
                          tooltip: co.title,
                          selected: selected,
                          onSelected: (v) => setState(() {
                            if (v) selectedCOs.add(co.id);
                            else selectedCOs.remove(co.id);
                          }),
                          selectedColor: AppTheme.primaryGreen.withOpacity(0.2),
                        );
                      }).toList(),
                    ),
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
                final result = await FacultyActions.createAssessment(courseId, {
                  'type': type,
                  'title': titleCtrl.text,
                  'totalMarks': double.tryParse(marksCtrl.text) ?? 100,
                  'weight': double.tryParse(weightCtrl.text) ?? 25,
                  'courseOutcomeIds': selectedCOs,
                });
                setState(() => isLoading = false);
                result.when(
                  success: (_) { ref.invalidate(assessmentsProvider(courseId)); Navigator.pop(ctx); },
                  failure: (e) => ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e), backgroundColor: AppTheme.error),
                  ),
                );
              },
              label: 'Add',
            ),
          ],
        ),
      ),
    );
  }
}
