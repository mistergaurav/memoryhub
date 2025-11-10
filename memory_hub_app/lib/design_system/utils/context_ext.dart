import 'package:flutter/material.dart';
import '../tokens/spacing_tokens.dart';
import '../tokens/radius_tokens.dart';
import '../tokens/breakpoint_tokens.dart';
import '../theme/extensions.dart';

/// BuildContext extensions for easy access to theme and tokens
extension DesignSystemContext on BuildContext {
  /// Access theme
  ThemeData get theme => Theme.of(this);

  /// Access color scheme
  ColorScheme get colors => theme.colorScheme;

  /// Access text theme
  TextTheme get text => theme.textTheme;

  /// Access custom tokens
  AppTokens get tokens =>
      theme.extension<AppTokens>() ?? AppTokens.light();

  /// Check if device is small (phone)
  bool get isSm => MediaQuery.of(this).size.width < Breakpoints.sm;

  /// Check if device is medium (tablet)
  bool get isMd =>
      MediaQuery.of(this).size.width >= Breakpoints.sm &&
      MediaQuery.of(this).size.width < Breakpoints.md;

  /// Check if device is large (desktop)
  bool get isLg =>
      MediaQuery.of(this).size.width >= Breakpoints.md &&
      MediaQuery.of(this).size.width < Breakpoints.lg;

  /// Check if device is extra large
  bool get isXl => MediaQuery.of(this).size.width >= Breakpoints.xl;

  /// Get responsive padding based on screen size
  double responsivePadding() {
    if (isSm) return Spacing.md;
    if (isMd) return Spacing.lg;
    return Spacing.xl;
  }

  /// Show snackbar helper
  void showSnackbar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? colors.error : null,
      ),
    );
  }
}
