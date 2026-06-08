import 'package:flutter/material.dart';
import 'package:obe_tracker/core/theme/app_theme.dart';
import 'package:obe_tracker/core/constants/app_constants.dart';

class AttainmentBadge extends StatelessWidget {
  final String level;
  final double? percentage;
  final bool showPercentage;

  const AttainmentBadge({
    super.key,
    required this.level,
    this.percentage,
    this.showPercentage = true,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.attainmentColor(level);
    final label = AppConstants.attainmentLevelLabels[level] ?? level;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            showPercentage && percentage != null
                ? '${percentage!.toStringAsFixed(1)}% · $level'
                : label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
