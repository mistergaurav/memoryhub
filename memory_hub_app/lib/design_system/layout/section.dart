import 'package:flutter/material.dart';
import '../tokens/spacing_tokens.dart';
import '../tokens/radius_tokens.dart';
import '../layout/gap.dart';
import '../layout/padded.dart';

/// Section container with optional title and divider
/// Use for grouping related content
class Section extends StatelessWidget {
  final Widget? title;
  final Widget child;
  final bool showDivider;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;

  const Section({
    this.title,
    required this.child,
    this.showDivider = false,
    this.padding,
    this.backgroundColor,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor,
      padding: padding ?? const EdgeInsets.all(Spacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title != null) ...[
            title!,
            const VGap.sm(),
          ],
          if (showDivider && title != null) ...[
            const Divider(),
            const VGap.sm(),
          ],
          child,
        ],
      ),
    );
  }
}

/// Card-based section with elevation and rounded corners
class CardSection extends StatelessWidget {
  final Widget? title;
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  const CardSection({
    this.title,
    required this.child,
    this.padding,
    this.margin,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: margin ?? EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: Radii.lgRadius,
      ),
      child: Padded(
        padding: padding ?? const EdgeInsets.all(Spacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (title != null) ...[
              DefaultTextStyle(
                style: Theme.of(context).textTheme.titleMedium!,
                child: title!,
              ),
              const VGap.md(),
            ],
            child,
          ],
        ),
      ),
    );
  }
}
