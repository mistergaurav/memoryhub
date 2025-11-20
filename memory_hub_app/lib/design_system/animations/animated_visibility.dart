import 'package:flutter/material.dart';
import '../tokens/duration_tokens.dart' as custom;
import 'motion.dart';

/// Animated visibility widget with fade and size transitions
/// Respects reduced motion preferences
class AnimatedVisibilityX extends StatelessWidget {
  final bool visible;
  final Widget child;
  final Duration? duration;
  final Curve? curve;

  const AnimatedVisibilityX({
    required this.visible,
    required this.child,
    this.duration,
    this.curve,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveDuration = Motion.duration(
      context,
      duration ?? custom.Durations.base,
    );
    final effectiveCurve = curve ?? Motion.standard;

    return AnimatedOpacity(
      opacity: visible ? 1.0 : 0.0,
      duration: effectiveDuration,
      curve: effectiveCurve,
      child: AnimatedSize(
        duration: effectiveDuration,
        curve: effectiveCurve,
        child: visible ? child : SizedBox.shrink(),
      ),
    );
  }
}
