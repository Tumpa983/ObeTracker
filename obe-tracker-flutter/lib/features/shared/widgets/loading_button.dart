import 'package:flutter/material.dart';
import 'package:obe_tracker/core/theme/app_theme.dart';

class LoadingButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;
  final String label;
  final IconData? icon;
  final bool outlined;
  final bool fullWidth;
  final Color? color;

  const LoadingButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.isLoading = false,
    this.icon,
    this.outlined = false,
    this.fullWidth = true,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final btnColor = color ?? AppTheme.primaryGreen;

    final child = isLoading
        ? const SizedBox(height: 20, width: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
        : icon != null
            ? Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(icon, size: 18),
                const SizedBox(width: 8),
                Text(label),
              ])
            : Text(label);

    final button = outlined
        ? OutlinedButton(
            onPressed: isLoading ? null : onPressed,
            style: OutlinedButton.styleFrom(
              foregroundColor: btnColor,
              side: BorderSide(color: btnColor),
            ),
            child: child,
          )
        : ElevatedButton(
            onPressed: isLoading ? null : onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: btnColor,
              foregroundColor: Colors.white,
            ),
            child: child,
          );

    return fullWidth ? SizedBox(width: double.infinity, child: button) : button;
  }
}
