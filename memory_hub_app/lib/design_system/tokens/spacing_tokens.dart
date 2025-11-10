import 'package:flutter/material.dart';

/// Spacing tokens following 8px grid system
/// Use these instead of hardcoded EdgeInsets or SizedBox values
class Spacing {
  Spacing._();

  /// 4px - Minimal spacing
  static const double xxs = 4.0;

  /// 8px - Extra small spacing
  static const double xs = 8.0;

  /// 12px - Small spacing
  static const double sm = 12.0;

  /// 16px - Medium spacing (base unit)
  static const double md = 16.0;

  /// 24px - Large spacing
  static const double lg = 24.0;

  /// 32px - Extra large spacing
  static const double xl = 32.0;

  /// 48px - Double extra large spacing
  static const double xxl = 48.0;

  /// 64px - Triple extra large spacing
  static const double xxxl = 64.0;

  // Deprecated shims for backward compatibility
  // TODO: Remove these after migrating all usages to EdgeInsets.all(Spacing.X)
  @Deprecated('Use const EdgeInsets.all(Spacing.xs) instead')
  static const EdgeInsets edgeInsetsAll8 = EdgeInsets.all(xs);

  @Deprecated('Use const EdgeInsets.all(Spacing.sm) instead')
  static const EdgeInsets edgeInsetsAll12 = EdgeInsets.all(sm);

  @Deprecated('Use const EdgeInsets.all(Spacing.md) instead')
  static const EdgeInsets edgeInsetsAll16 = EdgeInsets.all(md);

  @Deprecated('Use const EdgeInsets.all(Spacing.lg) instead')
  static const EdgeInsets edgeInsetsAll20 = EdgeInsets.all(lg);

  @Deprecated('Use const EdgeInsets.all(Spacing.xl) instead')
  static const EdgeInsets edgeInsetsAll24 = EdgeInsets.all(xl);

  @Deprecated('Use EdgeInsets.only() with Spacing constants instead')
  static EdgeInsets edgeInsetsOnly({
    double left = 0.0,
    double top = 0.0,
    double right = 0.0,
    double bottom = 0.0,
  }) => EdgeInsets.only(left: left, top: top, right: right, bottom: bottom);

  @Deprecated('Use EdgeInsets.symmetric() with Spacing constants instead')
  static EdgeInsets edgeInsetsSymmetric({
    double horizontal = 0.0,
    double vertical = 0.0,
  }) => EdgeInsets.symmetric(horizontal: horizontal, vertical: vertical);

  @Deprecated('Use const EdgeInsets.only(bottom: Spacing.sm) instead')
  static const EdgeInsets edgeInsetsBottomSm = EdgeInsets.only(bottom: sm);
  
  @Deprecated('Use const EdgeInsets.only(bottom: Spacing.md) instead')
  static const EdgeInsets edgeInsetsBottomMd = EdgeInsets.only(bottom: md);
  
  @Deprecated('Use const EdgeInsets.only(bottom: Spacing.lg) instead')
  static const EdgeInsets edgeInsetsBottomLg = EdgeInsets.only(bottom: lg);
}
