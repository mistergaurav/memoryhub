import 'package:flutter/material.dart';
import '../tokens/spacing_tokens.dart';
import '../utils/context_ext.dart';

/// Padding wrapper widget
/// Use instead of Padding with hardcoded EdgeInsets
class Padded extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const Padded({
    required this.child,
    required this.padding,
    super.key,
  });

  /// All sides with same padding
  const Padded.all(
    double value, {
    required this.child,
    super.key,
  }) : padding = EdgeInsets.all(value);

  /// Symmetric padding
  const Padded.symmetric({
    required this.child,
    double horizontal = 0,
    double vertical = 0,
    super.key,
  }) : padding = EdgeInsets.symmetric(
          horizontal: horizontal,
          vertical: vertical,
        );

  /// Custom padding for each side
  const Padded.only({
    required this.child,
    double left = 0,
    double top = 0,
    double right = 0,
    double bottom = 0,
    super.key,
  }) : padding = EdgeInsets.only(
          left: left,
          top: top,
          right: right,
          bottom: bottom,
        );

  /// Named constructors for common sizes
  const Padded.xxs({required this.child, super.key})
      : padding = const EdgeInsets.all(Spacing.xxs);

  const Padded.xs({required this.child, super.key})
      : padding = const EdgeInsets.all(Spacing.xs);

  const Padded.sm({required this.child, super.key})
      : padding = const EdgeInsets.all(Spacing.sm);

  const Padded.md({required this.child, super.key})
      : padding = const EdgeInsets.all(Spacing.md);

  const Padded.lg({required this.child, super.key})
      : padding = const EdgeInsets.all(Spacing.lg);

  const Padded.xl({required this.child, super.key})
      : padding = const EdgeInsets.all(Spacing.xl);

  const Padded.xxl({required this.child, super.key})
      : padding = const EdgeInsets.all(Spacing.xxl);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: child,
    );
  }
}

/// Screen-level padding wrapper with responsive support
class ScreenPadding extends StatelessWidget {
  final Widget child;
  final bool responsive;
  final double? override;

  const ScreenPadding({
    required this.child,
    this.responsive = false,
    this.override,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final padding = override ?? 
        (responsive ? context.responsivePadding() : Spacing.md);
    
    return Padding(
      padding: EdgeInsets.all(padding),
      child: child,
    );
  }
}
