import 'package:flutter/material.dart';

/// Border radius tokens
/// Use these instead of hardcoded BorderRadius values
class Radii {
  Radii._();

  /// 4px radius - Extra small
  static const double xs = 4.0;

  /// 8px radius - Small
  static const double sm = 8.0;

  /// 12px radius - Medium
  static const double md = 12.0;

  /// 16px radius - Large
  static const double lg = 16.0;

  /// 20px radius - Extra large
  static const double xl = 20.0;

  /// 999px radius - Pill shape
  static const double pill = 999.0;

  /// BorderRadius helpers
  static BorderRadius get xsRadius => BorderRadius.circular(xs);
  static BorderRadius get smRadius => BorderRadius.circular(sm);
  static BorderRadius get mdRadius => BorderRadius.circular(md);
  static BorderRadius get lgRadius => BorderRadius.circular(lg);
  static BorderRadius get xlRadius => BorderRadius.circular(xl);
  static BorderRadius get pillRadius => BorderRadius.circular(pill);
}
