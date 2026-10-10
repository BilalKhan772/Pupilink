
import 'package:flutter/material.dart';

import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';

enum AppButtonVariant {
  primary,
  secondary,
  outline,
  text,
  danger,
}

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    this.isEnabled = true,
    this.icon,
    this.width,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool isLoading;
  final bool isEnabled;
  final IconData? icon;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final isDisabled = !isEnabled || isLoading || onPressed == null;

    final child = isLoading
        ? SizedBox(
            height: AppSpacing.iconMedium,
            width: AppSpacing.iconMedium,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: variant == AppButtonVariant.outline ||
                      variant == AppButtonVariant.text
                  ? colors.primary
                  : colors.onPrimary,
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: AppSpacing.iconMedium),
                const SizedBox(width: AppSpacing.sm),
              ],
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelLarge,
                ),
              ),
            ],
          );

    final buttonStyle = ButtonStyle(
      minimumSize: WidgetStatePropertyAll(
        Size(0, AppSpacing.buttonHeight),
      ),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(
          horizontal: AppSpacing.buttonHorizontal,
          vertical: AppSpacing.buttonVertical,
        ),
      ),
      shape: const WidgetStatePropertyAll(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(AppRadius.medium),
          ),
        ),
      ),
    );

    Widget button;

    switch (variant) {
      case AppButtonVariant.primary:
        button = ElevatedButton(
          onPressed: isDisabled ? null : onPressed,
          style: buttonStyle,
          child: child,
        );

      case AppButtonVariant.secondary:
        button = ElevatedButton(
          onPressed: isDisabled ? null : onPressed,
          style: buttonStyle.copyWith(
            backgroundColor: WidgetStatePropertyAll(colors.secondary),
            foregroundColor: WidgetStatePropertyAll(colors.onSecondary),
          ),
          child: child,
        );

      case AppButtonVariant.outline:
        button = OutlinedButton(
          onPressed: isDisabled ? null : onPressed,
          style: buttonStyle,
          child: child,
        );

      case AppButtonVariant.text:
        button = TextButton(
          onPressed: isDisabled ? null : onPressed,
          style: buttonStyle,
          child: child,
        );

      case AppButtonVariant.danger:
        button = ElevatedButton(
          onPressed: isDisabled ? null : onPressed,
          style: buttonStyle.copyWith(
            backgroundColor: WidgetStatePropertyAll(colors.error),
            foregroundColor: WidgetStatePropertyAll(colors.onError),
          ),
          child: child,
        );
    }

    return SizedBox(
      width: width,
      child: button,
    );
  }
}
