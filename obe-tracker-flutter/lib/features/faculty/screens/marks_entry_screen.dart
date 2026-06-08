import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:obe_tracker/core/theme/app_theme.dart';
import 'package:obe_tracker/features/shared/widgets/loading_button.dart';
import '../models/faculty_models.dart';
import '../providers/faculty_providers.dart';

class MarksEntryScreen extends ConsumerStatefulWidget {
  final String courseId;
  final String assessmentId;
  const MarksEntryScreen({super.key, required this.courseId, required this.assessmentId});

  @override
  ConsumerState<MarksEntryScreen> createState() => _MarksEntryScreenState();
}

class _MarksEntryScreenState extends ConsumerState<MarksEntryScreen> {
  final Map<String, TextEditingController> _controllers = {};
  bool _isSaving = false;
  bool _isDirty = false;

  @override
  void dispose() {
    for (final c in _controllers.values) c.dispose();
    super.dispose();
  }

  TextEditingController _getController(String studentId, double? existingMark) {
    return _controllers.putIfAbsent(studentId, () =>
        TextEditingController(text: existingMark?.toStringAsFixed(0) ?? ''));
  }

  Future<void> _saveMarks(List<Map<String, dynamic>> marks, double totalMarks) async {
    setState(() => _isSaving = true);
    final data = <Map<String, dynamic>>[];
    for (final mark in marks) {
      final studentId = mark['studentId'] as String;
      final ctrl = _controllers[studentId];
      if (ctrl != null && ctrl.text.isNotEmpty) {
        data.add({'studentId': studentId, 'marksObtained': double.tryParse(ctrl.text) ?? 0});
      }
    }

    final result = await FacultyActions.saveMarks(widget.assessmentId, data);
    setState(() { _isSaving = false; _isDirty = false; });
    result.when(
      success: (_) {
        ref.invalidate(marksProvider(widget.assessmentId));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Marks saved. Attainment is being recomputed.')));
      },
      failure: (e) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e), backgroundColor: AppTheme.error),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final assessmentsAsync = ref.watch(assessmentsProvider(widget.courseId));
    final marksAsync = ref.watch(marksProvider(widget.assessmentId));

    // Get the assessment info
    Assessment? assessment;
    if (assessmentsAsync.value != null) {
      final list = (assessmentsAsync.value!['assessments'] as List)
          .map((j) => Assessment.fromJson(j))
          .where((a) => a.id == widget.assessmentId);
      if (list.isNotEmpty) assessment = list.first;
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(assessment?.title ?? 'Marks Entry', style: const TextStyle(fontSize: 16)),
          if (assessment != null)
            Text(
              'Total: ${assessment.totalMarks.toStringAsFixed(0)} marks · ${assessment.weight.toStringAsFixed(1)}% weight',
              style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
            ),
        ]),
        actions: [
          if (_isDirty && assessment != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: LoadingButton(
                onPressed: () => _saveMarks(
                  marksAsync.value ?? [],
                  assessment!.totalMarks,
                ),
                isLoading: _isSaving,
                label: 'Save',
                icon: Icons.save_outlined,
              ),
            ),
        ],
      ),
      body: marksAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (marks) {
          if (marks.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text('No students enrolled yet. Ask your administrator to enrol students.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFF6B7280))),
              ),
            );
          }

          final totalMarks = assessment?.totalMarks ?? 100;

          return Column(
            children: [
              // Header
              Container(
                color: const Color(0xFFF9FAFB),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(children: [
                  Expanded(child: Text('Student', style: Theme.of(context).textTheme.labelLarge)),
                  SizedBox(
                    width: 100,
                    child: Text('Marks / ${totalMarks.toStringAsFixed(0)}',
                        style: Theme.of(context).textTheme.labelLarge, textAlign: TextAlign.center),
                  ),
                  const SizedBox(width: 60),
                ]),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: marks.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final mark = marks[i];
                    final studentId = mark['studentId'] as String;
                    final existingMark = mark['marksObtained'] != null
                        ? (mark['marksObtained'] as num).toDouble()
                        : null;
                    final ctrl = _getController(studentId, existingMark);
                    final markValue = double.tryParse(ctrl.text);
                    final isValid = markValue == null ||
                        (markValue >= 0 && markValue <= totalMarks);

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: AppTheme.primaryGreen.withOpacity(0.1),
                          child: Text(
                            (i + 1).toString(),
                            style: const TextStyle(color: AppTheme.primaryGreen, fontSize: 12, fontWeight: FontWeight.w700),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(studentId,
                              style: Theme.of(context).textTheme.bodyMedium,
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                        SizedBox(
                          width: 100,
                          child: TextField(
                            controller: ctrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            textAlign: TextAlign.center,
                            decoration: InputDecoration(
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: isValid ? const Color(0xFFD1D5DB) : AppTheme.error,
                                ),
                              ),
                            ),
                            onChanged: (_) => setState(() => _isDirty = true),
                          ),
                        ),
                        SizedBox(
                          width: 60,
                          child: markValue != null
                              ? Text(
                                  '${(markValue / totalMarks * 100).toStringAsFixed(0)}%',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: isValid ? AppTheme.primaryGreen : AppTheme.error,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                )
                              : const SizedBox(),
                        ),
                      ]),
                    );
                  },
                ),
              ),
              if (_isDirty)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: LoadingButton(
                    onPressed: () => _saveMarks(marks, totalMarks),
                    isLoading: _isSaving,
                    label: 'Save All Marks',
                    icon: Icons.save_outlined,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
