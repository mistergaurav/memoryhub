import 'package:flutter/material.dart';
import '../../theme/color_tokens.dart';

/// Theme extension for custom design tokens
/// Access via: Theme.of(context).extension<AppTokens>()
/// Or use context extensions: context.spacing, context.radii
class AppTokens extends ThemeExtension<AppTokens> {
  final Color success;
  final Color warning;
  final Color info;

  const AppTokens({
    required this.success,
    required this.warning,
    required this.info,
  });

  @override
  AppTokens copyWith({
    Color? success,
    Color? warning,
    Color? info,
  }) {
    return AppTokens(
      success: success ?? this.success,
      warning: warning ?? this.warning,
      info: info ?? this.info,
    );
  }

  @override
  AppTokens lerp(ThemeExtension<AppTokens>? other, double t) {
    if (other is! AppTokens) return this;
    return AppTokens(
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      info: Color.lerp(info, other.info, t)!,
    );
  }

  /// Light theme tokens
  static AppTokens light() => const AppTokens(
        success: AppColorTokens.lightSuccess,
        warning: AppColorTokens.lightWarning,
        info: AppColorTokens.lightInfo,
      );

  /// Dark theme tokens
  static AppTokens dark() => const AppTokens(
        success: AppColorTokens.darkSuccess,
        warning: AppColorTokens.darkWarning,
        info: AppColorTokens.darkInfo,
      );
}
