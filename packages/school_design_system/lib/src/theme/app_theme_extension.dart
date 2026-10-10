
import 'package:flutter/material.dart';

@immutable
class AppThemeExtension
    extends ThemeExtension<AppThemeExtension> {
  final Color success;
  final Color warning;
  final Color info;
  final Color chartPrimary;
  final Color chartSecondary;
  final Color chartTertiary;
  final Color divider;
  final Color disabled;

  const AppThemeExtension({
    required this.success,
    required this.warning,
    required this.info,
    required this.chartPrimary,
    required this.chartSecondary,
    required this.chartTertiary,
    required this.divider,
    required this.disabled,
  });

  static const light = AppThemeExtension(
    success: Color(0xFF16A34A),
    warning: Color(0xFFF59E0B),
    info: Color(0xFF0284C7),
    chartPrimary: Color(0xFF2563EB),
    chartSecondary: Color(0xFF0F766E),
    chartTertiary: Color(0xFF9333EA),
    divider: Color(0xFFE2E8F0),
    disabled: Color(0xFF94A3B8),
  );

  static const dark = AppThemeExtension(
    success: Color(0xFF4ADE80),
    warning: Color(0xFFFBBF24),
    info: Color(0xFF38BDF8),
    chartPrimary: Color(0xFF93B4FF),
    chartSecondary: Color(0xFF5EEAD4),
    chartTertiary: Color(0xFFC084FC),
    divider: Color(0xFF334155),
    disabled: Color(0xFF64748B),
  );

  @override
  AppThemeExtension copyWith({
    Color? success,
    Color? warning,
    Color? info,
    Color? chartPrimary,
    Color? chartSecondary,
    Color? chartTertiary,
    Color? divider,
    Color? disabled,
  }) {
    return AppThemeExtension(
      success: success ?? this.success,
      warning: warning ?? this.warning,
      info: info ?? this.info,
      chartPrimary: chartPrimary ?? this.chartPrimary,
      chartSecondary: chartSecondary ?? this.chartSecondary,
      chartTertiary: chartTertiary ?? this.chartTertiary,
      divider: divider ?? this.divider,
      disabled: disabled ?? this.disabled,
    );
  }

  @override
  AppThemeExtension lerp(
    covariant ThemeExtension<AppThemeExtension>? other,
    double t,
  ) {
    if (other is! AppThemeExtension) {
      return this;
    }

    return AppThemeExtension(
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      info: Color.lerp(info, other.info, t)!,
      chartPrimary:
          Color.lerp(chartPrimary, other.chartPrimary, t)!,
      chartSecondary:
          Color.lerp(chartSecondary, other.chartSecondary, t)!,
      chartTertiary:
          Color.lerp(chartTertiary, other.chartTertiary, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      disabled: Color.lerp(disabled, other.disabled, t)!,
    );
  }
}

extension AppThemeExtensionContext on BuildContext {
  AppThemeExtension get appTheme =>
      Theme.of(this).extension<AppThemeExtension>() ??
      AppThemeExtension.light;
}
