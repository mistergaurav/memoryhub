import 'package:flutter/material.dart';

/// Shadow tokens for consistent elevation styles
class Shadows {
  Shadows._();

  /// No shadow
  static List<BoxShadow> get none => [];

  /// Subtle shadow (cards)
  static List<BoxShadow> get sm => [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 4,
          offset: const Offset(0, 1),
        ),
        BoxShadow(
          color: Colors.black.withOpacity(0.03),
          blurRadius: 2,
          offset: const Offset(0, 1),
        ),
      ];

  /// Medium shadow (raised buttons)
  static List<BoxShadow> get md => [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
        BoxShadow(
          color: Colors.black.withOpacity(0.06),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ];

  /// Large shadow (modals, dropdowns)
  static List<BoxShadow> get lg => [
        BoxShadow(
          color: Colors.black.withOpacity(0.15),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];

  /// Extra large shadow (navigation drawer)
  static List<BoxShadow> get xl => [
        BoxShadow(
          color: Colors.black.withOpacity(0.2),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
        BoxShadow(
          color: Colors.black.withOpacity(0.12),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];
}
