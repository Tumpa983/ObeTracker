import 'package:flutter/material.dart';
import 'package:obe_tracker/core/theme/app_theme.dart';

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 36, color: AppTheme.primaryGreen.withOpacity(0.6)),
            ),
            const SizedBox(height: 16),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(subtitle!,
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add, size: 18),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
