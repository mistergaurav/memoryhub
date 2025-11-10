import 'package:flutter/material.dart';
import '../tokens/spacing_tokens.dart';
import '../tokens/radius_tokens.dart';
import '../tokens/elevation_tokens.dart';
import '../tokens/border_tokens.dart';

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
        success: Color(0xFF10B981),
        warning: Color(0xFFF59E0B),
        info: Color(0xFF06B6D4),
      );

  /// Dark theme tokens
  static AppTokens dark() => const AppTokens(
        success: Color(0xFF34D399),
        warning: Color(0xFFFBBF24),
        info: Color(0xFF22D3EE),
      );
}
