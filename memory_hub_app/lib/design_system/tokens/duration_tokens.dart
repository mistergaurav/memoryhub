/// Animation duration tokens
/// Use these instead of hardcoded Duration values
class Durations {
  Durations._();

  /// 120ms - Fast animations (micro-interactions)
  static const Duration fast = Duration(milliseconds: 120);

  /// 200ms - Base animations (standard transitions)
  static const Duration base = Duration(milliseconds: 200);

  /// 300ms - Slow animations (complex transitions)
  static const Duration slow = Duration(milliseconds: 300);

  /// 450ms - Slower animations (page transitions)
  static const Duration slower = Duration(milliseconds: 450);

  /// 600ms - Slowest animations (emphasis)
  static const Duration slowest = Duration(milliseconds: 600);
}
