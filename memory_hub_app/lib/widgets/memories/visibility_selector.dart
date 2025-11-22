import 'package:flutter/material.dart';
import 'package:memory_hub_app/design_system/design_system.dart';
import 'package:memory_hub_app/design_system/tokens/spacing_tokens.dart';
import 'package:memory_hub_app/design_system/tokens/radius_tokens.dart';

enum VisibilityType {
  private,
  friends,
  public,
  family,
  familyCircle,
  specificUsers,
}

class VisibilitySelector extends StatelessWidget {
  final VisibilityType selectedType;
  final VoidCallback onTap;
  final String? specificLabel; // e.g., "3 users selected" or "Inner Circle"

  const VisibilitySelector({
    super.key,
    required this.selectedType,
    required this.onTap,
    this.specificLabel,
  });

  String get _label {
    switch (selectedType) {
      case VisibilityType.private:
        return 'Private';
      case VisibilityType.friends:
        return 'Friends';
      case VisibilityType.public:
        return 'Public';
      case VisibilityType.family:
        return 'Family';
      case VisibilityType.familyCircle:
        return 'Family Circle';
      case VisibilityType.specificUsers:
        return 'Specific Users';
    }
  }

  IconData get _icon {
    switch (selectedType) {
      case VisibilityType.private:
        return Icons.lock_outline;
      case VisibilityType.friends:
        return Icons.people_outline;
      case VisibilityType.public:
        return Icons.public;
      case VisibilityType.family:
        return Icons.family_restroom;
      case VisibilityType.familyCircle:
        return Icons.diversity_3;
      case VisibilityType.specificUsers:
        return Icons.person_add_alt;
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: Radii.mdRadius,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: Spacing.md,
          vertical: Spacing.sm,
        ),
        decoration: BoxDecoration(
          border: Border.all(color: context.colors.outline),
          borderRadius: Radii.mdRadius,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_icon, size: 18, color: context.colors.primary),
            HGap.sm(),
            Text(
              specificLabel ?? _label,
              style: context.text.labelLarge?.copyWith(
                color: context.colors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            HGap.xs(),
            Icon(Icons.arrow_drop_down, color: context.colors.primary),
          ],
        ),
      ),
    );
  }
}
