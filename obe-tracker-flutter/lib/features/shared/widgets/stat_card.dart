import 'package:flutter/material.dart';

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String? subtitle;
  final VoidCallback? onTap;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(value,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: color,
                              fontWeight: FontWeight.w700,
                            )),
                    Text(title, style: Theme.of(context).textTheme.bodySmall),
                    if (subtitle != null)
                      Text(subtitle!,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: const Color(0xFF9CA3AF))),
                  ],
                ),
              ),
              if (onTap != null)
                const Icon(Icons.chevron_right, color: Color(0xFF9CA3AF)),
            ],
          ),
        ),
      ),
    );
  }
}
