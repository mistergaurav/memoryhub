import 'package:flutter/material.dart';
import '../../design_system/family_design_system.dart';
import '../animated/animated_family_button.dart';

class FamilyEmptyState extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final VoidCallback? onAction;
  final String? actionText;
  final Gradient? iconGradient;

  const FamilyEmptyState({
    Key? key,
    required this.title,
    required this.message,
    required this.icon,
    this.onAction,
    this.actionText,
    this.iconGradient,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(FamilySpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: FamilyAnimations.moderate,
              curve: FamilyAnimations.spring,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: child,
                );
              },
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: iconGradient ?? FamilyColors.familyDashboardGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (iconGradient?.colors.first ?? FamilyColors.midnightIndigo)
                          .withOpacity(0.3),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Icon(
                  icon,
                  size: 64,
                  color: FamilyColors.pureWhite,
                ),
              ),
            ),
            const SizedBox(height: FamilySpacing.xxl),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: FamilyAnimations.moderate,
              curve: Curves.easeOut,
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, 20 * (1 - value)),
                    child: child,
                  ),
                );
              },
              child: Column(
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: FamilyColors.deepCharcoal,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: FamilySpacing.md),
                  Text(
                    message,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: FamilyColors.deepCharcoal.withOpacity(0.6),
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            if (onAction != null && actionText != null) ...[
              const SizedBox(height: FamilySpacing.xxl),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: FamilyAnimations.slow,
                curve: Curves.easeOut,
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: child,
                  );
                },
                child: AnimatedFamilyButton(
                  onPressed: onAction,
                  gradient: iconGradient ?? FamilyColors.familyDashboardGradient,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        FamilyIcons.add,
                        color: FamilyColors.pureWhite,
                        size: 20,
                      ),
                      const SizedBox(width: FamilySpacing.sm),
                      Text(
                        actionText!,
                        style: const TextStyle(
                          color: FamilyColors.pureWhite,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
