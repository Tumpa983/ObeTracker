import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:obe_tracker/core/theme/app_theme.dart';
import 'package:obe_tracker/features/shared/widgets/loading_button.dart';
import '../models/faculty_models.dart';
import '../providers/faculty_providers.dart';

class MappingMatrixScreen extends ConsumerStatefulWidget {
  final String courseId;
  const MappingMatrixScreen({super.key, required this.courseId});

  @override
  ConsumerState<MappingMatrixScreen> createState() => _MappingMatrixScreenState();
}

class _MappingMatrixScreenState extends ConsumerState<MappingMatrixScreen> {
  Map<String, Map<String, String?>> _localMatrix = {};
  bool _initialised = false; // only init once, don't overwrite edits
  bool _isDirty = false;
  bool _isSaving = false;

  static const _correlationValues = [null, 'WEAK', 'MODERATE', 'STRONG'];
  static const _correlationLabels = {null: '–', 'WEAK': '1', 'MODERATE': '2', 'STRONG': '3'};
  static const _correlationColors = {
    null: Color(0xFFF3F4F6),
    'WEAK': Color(0xFFDCFCE7),
    'MODERATE': Color(0xFFBBF7D0),
    'STRONG': Color(0xFF4ADE80),
  };

  void _initMatrix(MappingMatrix matrix) {
    // Only initialise once so user edits are not overwritten on rebuild
    if (_initialised) return;
    _localMatrix = {};
    for (final co in matrix.courseOutcomes) {
      _localMatrix[co.id] = {};
      for (final po in matrix.programOutcomes) {
        _localMatrix[co.id]![po['id']] = matrix.getCorrelation(co.id, po['id']);
      }
    }
    _initialised = true;
  }

  void _cycleCorrelation(String coId, String poId) {
    setState(() {
      _isDirty = true;
      final current = _localMatrix[coId]?[poId];
      final idx = _correlationValues.indexOf(current);
      final next = _correlationValues[(idx + 1) % _correlationValues.length];
      _localMatrix[coId]![poId] = next;
    });
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    final mappings = <Map<String, dynamic>>[];
    _localMatrix.forEach((coId, poMap) {
      poMap.forEach((poId, correlation) {
        mappings.add({
          'courseOutcomeId': coId,
          'programOutcomeId': poId,
          'correlation': correlation,
        });
      });
    });

    final result = await FacultyActions.saveMapping(widget.courseId, mappings);
    if (!mounted) return;
    setState(() { _isSaving = false; _isDirty = false; });
    result.when(
      success: (_) {
        ref.invalidate(mappingProvider(widget.courseId));
        ref.invalidate(courseAttainmentProvider(widget.courseId));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Mapping saved. Attainment recomputed.'),
            backgroundColor: AppTheme.primaryGreen,
          ),
        );
      },
      failure: (e) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e), backgroundColor: AppTheme.error),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final matrixAsync = ref.watch(mappingProvider(widget.courseId));

    return matrixAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (matrix) {
        _initMatrix(matrix);

        if (matrix.courseOutcomes.isEmpty || matrix.programOutcomes.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.grid_on_outlined, size: 48, color: Color(0xFF9CA3AF)),
                SizedBox(height: 16),
                Text('CO–PO Mapping Matrix',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                SizedBox(height: 8),
                Text(
                  'Add Course Outcomes in the Outcomes tab and ensure POs are defined for your program.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF6B7280)),
                ),
              ]),
            ),
          );
        }

        return Column(
          children: [
            // Toolbar
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Wrap(spacing: 8, runSpacing: 4, children: [
                      _LegendChip(label: '– None', color: const Color(0xFFF3F4F6)),
                      _LegendChip(label: '1 Weak', color: const Color(0xFFDCFCE7)),
                      _LegendChip(label: '2 Moderate', color: const Color(0xFFBBF7D0)),
                      _LegendChip(label: '3 Strong', color: const Color(0xFF4ADE80)),
                    ]),
                  ),
                  const SizedBox(width: 12),
                  // Always show Save button — not just when dirty
                  LoadingButton(
                    onPressed: _save,
                    isLoading: _isSaving,
                    label: _isDirty ? 'Save Changes' : 'Save Matrix',
                    icon: Icons.save_outlined,
                    color: _isDirty ? AppTheme.primaryGreen : const Color(0xFF6B7280),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(children: [
                const Icon(Icons.touch_app_outlined, size: 14, color: Color(0xFF9CA3AF)),
                const SizedBox(width: 4),
                const Text(
                  'Tap a cell to cycle: – → 1 (Weak) → 2 (Moderate) → 3 (Strong)',
                  style: TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
                ),
                const Spacer(),
                if (_isDirty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.amber.shade200),
                    ),
                    child: Text('Unsaved changes',
                        style: TextStyle(fontSize: 11, color: Colors.amber.shade800, fontWeight: FontWeight.w600)),
                  ),
              ]),
            ),
            const SizedBox(height: 8),

            // Matrix
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.all(16),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // PO header row
                      Row(
                        children: [
                          const SizedBox(width: 130),
                          ...matrix.programOutcomes.map(
                            (po) => _MatrixHeader(label: po['code'] ?? '', tooltip: po['title'] ?? ''),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),

                      // CO rows
                      ...matrix.courseOutcomes.map((co) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            // CO label
                            SizedBox(
                              width: 130,
                              child: Tooltip(
                                message: co.title,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryGreen.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(7),
                                  ),
                                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Text(co.code,
                                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppTheme.primaryGreen)),
                                    const SizedBox(height: 1),
                                    Text(co.title,
                                        style: const TextStyle(fontSize: 9.5, color: Color(0xFF6B7280)),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis),
                                  ]),
                                ),
                              ),
                            ),

                            // PO cells
                            ...matrix.programOutcomes.map((po) {
                              final value = _localMatrix[co.id]?[po['id']];
                              final color = _correlationColors[value] ?? const Color(0xFFF3F4F6);
                              final hasValue = value != null;
                              return GestureDetector(
                                onTap: () => _cycleCorrelation(co.id, po['id']),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  width: 52,
                                  height: 48,
                                  margin: const EdgeInsets.only(left: 4),
                                  decoration: BoxDecoration(
                                    color: color,
                                    borderRadius: BorderRadius.circular(7),
                                    border: Border.all(
                                      color: hasValue ? color.withOpacity(0.6) : const Color(0xFFE5E7EB),
                                      width: hasValue ? 1.5 : 1,
                                    ),
                                    boxShadow: hasValue ? [
                                      BoxShadow(color: color.withOpacity(0.3), blurRadius: 4, offset: const Offset(0, 2))
                                    ] : null,
                                  ),
                                  child: Center(
                                    child: Text(
                                      _correlationLabels[value] ?? '–',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 15,
                                        color: hasValue ? const Color(0xFF065F46) : const Color(0xFFD1D5DB),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                      )),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _MatrixHeader extends StatelessWidget {
  final String label;
  final String tooltip;
  const _MatrixHeader({required this.label, required this.tooltip});

  @override
  Widget build(BuildContext context) => Tooltip(
        message: tooltip,
        child: Container(
          width: 52,
          height: 42,
          margin: const EdgeInsets.only(left: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF111827),
            borderRadius: BorderRadius.circular(7),
          ),
          child: Center(
            child: Text(label,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 10.5)),
          ),
        ),
      );
}

class _LegendChip extends StatelessWidget {
  final String label;
  final Color color;
  const _LegendChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color == const Color(0xFFF3F4F6)
              ? const Color(0xFFE5E7EB) : color.withOpacity(0.5)),
        ),
        child: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
      );
}
