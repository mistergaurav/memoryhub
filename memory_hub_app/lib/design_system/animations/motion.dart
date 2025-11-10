import 'package:flutter/material.dart';
import '../tokens/duration_tokens.dart' as custom;

/// Animation motion utilities
/// Provides standard curves and durations with reduced motion support
class Motion {
  Motion._();

  /// Standard curve for most animations
  static const Curve standard = Curves.easeInOut;

  /// Emphasized curve for important animations
  static const Curve emphasized = Curves.easeInOutCubic;

  /// Decelerate curve for entering elements
  static const Curve decelerate = Curves.decelerate;

  /// Accelerate curve for exiting elements
  static const Curve accelerate = Curves.easeIn;

  /// Check if reduced motion is preferred
  static bool reducedMotion(BuildContext context) {
    return MediaQuery.of(context).disableAnimations;
  }

  /// Get duration based on reduced motion preference
  static Duration duration(BuildContext context, Duration normal) {
    return reducedMotion(context) ? Duration.zero : normal;
  }

  /// Fast duration with reduced motion support
  static Duration fast(BuildContext context) {
    return duration(context, custom.Durations.fast);
  }

  /// Base duration with reduced motion support
  static Duration base(BuildContext context) {
    return duration(context, custom.Durations.base);
  }

  /// Slow duration with reduced motion support
  static Duration slow(BuildContext context) {
    return duration(context, custom.Durations.slow);
  }

  /// Slower duration with reduced motion support
  static Duration slower(BuildContext context) {
    return duration(context, custom.Durations.slower);
  }
}
