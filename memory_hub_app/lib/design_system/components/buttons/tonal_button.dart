import 'package:flutter/material.dart';
import '../../tokens/spacing_tokens.dart';
import '../../tokens/radius_tokens.dart';
import '../../utils/a11y.dart';

/// Tonal button component
/// Use for medium-emphasis actions
class TonalButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String label;
  final Widget? leading;
  final Widget? trailing;
  final bool isLoading;
  final bool fullWidth;

  const TonalButton({
    required this.onPressed,
    required this.label,
    this.leading,
    this.trailing,
    this.isLoading = false,
    this.fullWidth = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final button = FilledButton.tonal(
      onPressed: isLoading ? null : onPressed,
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.xl,
          vertical: Spacing.md,
        ),
        minimumSize: const Size(kMinTouchTarget, kMinTouchTarget),
        shape: RoundedRectangleBorder(
          borderRadius: Radii.lgRadius,
        ),
      ),
      child: isLoading
          ? SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.onSecondaryContainer,
                ),
              ),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (leading != null) ...[
                  leading!,
                  const SizedBox(width: Spacing.xs),
                ],
                Text(label),
                if (trailing != null) ...[
                  const SizedBox(width: Spacing.xs),
                  trailing!,
                ],
              ],
            ),
    );

    return fullWidth
        ? SizedBox(
            width: double.infinity,
            child: button,
          )
        : button;
  }
}
