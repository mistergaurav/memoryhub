import 'package:flutter/material.dart';

/// Accessibility minimum touch target size (44x44 logical pixels)
const double kMinTouchTarget = 44.0;

/// Wrapper to ensure minimum touch target size
class MinTouchTarget extends StatelessWidget {
  final Widget child;

  const MinTouchTarget({
    required this.child,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(
        minWidth: kMinTouchTarget,
        minHeight: kMinTouchTarget,
      ),
      child: child,
    );
  }
}

/// Semantic label helper for better screen reader support
Widget withSemantics({
  required Widget child,
  String? label,
  String? hint,
  bool? button,
  bool? header,
}) {
  return Semantics(
    label: label,
    hint: hint,
    button: button ?? false,
    header: header ?? false,
    child: child,
  );
}

/// Focus highlight builder for keyboard navigation
Widget focusHighlight(BuildContext context, Widget child, FocusNode focusNode) {
  return AnimatedBuilder(
    animation: focusNode,
    builder: (context, _) {
      return Container(
        decoration: focusNode.hasFocus
            ? BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary,
                  width: 3,
                ),
                borderRadius: BorderRadius.circular(8),
              )
            : null,
        child: child,
      );
    },
  );
}
