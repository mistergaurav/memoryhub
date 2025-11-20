import 'package:flutter/material.dart';
import '../../tokens/spacing_tokens.dart';
import '../../tokens/radius_tokens.dart';
import '../buttons/primary_button.dart';
import '../buttons/secondary_button.dart';
import '../../layout/gap.dart';

/// Dialog utilities for consistent feedback
class AppDialog {
  AppDialog._();

  /// Show confirmation dialog
  static Future<bool> confirm(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    bool isDangerous = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: Radii.lgRadius,
        ),
        title: Text(title),
        content: Text(message),
        actions: [
          SecondaryButton(
            onPressed: () => Navigator.of(context).pop(false),
            label: cancelText,
          ),
          HGap.sm(),
          PrimaryButton(
            onPressed: () => Navigator.of(context).pop(true),
            label: confirmText,
          ),
        ],
      ),
    );

    return result ?? false;
  }

  /// Show error dialog
  static Future<void> error(
    BuildContext context, {
    required String title,
    required String message,
  }) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: Radii.lgRadius,
        ),
        title: Row(
          children: [
            Icon(Icons.error, color: Theme.of(context).colorScheme.error),
            HGap.sm(),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          PrimaryButton(
            onPressed: () => Navigator.of(context).pop(),
            label: 'OK',
          ),
        ],
      ),
    );
  }

  /// Show info dialog
  static Future<void> info(
    BuildContext context, {
    required String title,
    required String message,
  }) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: Radii.lgRadius,
        ),
        title: Text(title),
        content: Text(message),
        actions: [
          PrimaryButton(
            onPressed: () => Navigator.of(context).pop(),
            label: 'OK',
          ),
        ],
      ),
    );
  }
}
