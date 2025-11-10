import 'package:flutter/material.dart';
import '../../tokens/spacing_tokens.dart';
import '../../tokens/radius_tokens.dart';
import '../../tokens/elevation_tokens.dart';

/// App card component with consistent styling
/// Use instead of raw Card widget
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Color? color;

  const AppCard({
    required this.child,
    this.padding,
    this.onTap,
    this.color,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final card = Card(
      elevation: Elevations.level2,
      shape: RoundedRectangleBorder(
        borderRadius: Radii.lgRadius,
      ),
      color: color,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: padding ?? const EdgeInsets.all(Spacing.md),
        child: child,
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: Radii.lgRadius,
        child: card,
      );
    }

    return card;
  }
}
