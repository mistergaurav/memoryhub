import 'package:flutter/material.dart';
import '../../utils/a11y.dart';

/// Custom icon button with minimum touch target
/// Use for icon-only actions
class IconButtonX extends StatelessWidget {
  final VoidCallback? onPressed;
  final IconData icon;
  final String? tooltip;
  final Color? color;
  final double? size;

  const IconButtonX({
    required this.onPressed,
    required this.icon,
    this.tooltip,
    this.color,
    this.size,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final button = IconButton(
      onPressed: onPressed,
      icon: Icon(icon, size: size),
      color: color,
      tooltip: tooltip,
      constraints: const BoxConstraints(
        minWidth: kMinTouchTarget,
        minHeight: kMinTouchTarget,
      ),
    );

    return tooltip != null
        ? Tooltip(
            message: tooltip!,
            child: button,
          )
        : button;
  }
}
