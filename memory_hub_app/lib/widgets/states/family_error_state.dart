import 'package:flutter/material.dart';
import '../../design_system/family_design_system.dart';
import '../animated/animated_family_button.dart';

class FamilyErrorState extends StatelessWidget {
  final String? title;
  final String? message;
  final VoidCallback? onRetry;
  final String? errorDetails;

  const FamilyErrorState({
    Key? key,
    this.title,
    this.message,
    this.onRetry,
    this.errorDetails,
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
                  gradient: LinearGradient(
                    colors: [FamilyColors.coralBloom, Colors.red.shade400],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: FamilyColors.coralBloom.withOpacity(0.3),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Icon(
                  FamilyIcons.error,
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
                    title ?? 'Oops! Something went wrong',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: FamilyColors.deepCharcoal,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: FamilySpacing.md),
                  Text(
                    message ?? 'We encountered an error while loading your data.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: FamilyColors.deepCharcoal.withOpacity(0.6),
                        ),
                    textAlign: TextAlign.center,
                  ),
                  if (errorDetails != null) ...[
                    const SizedBox(height: FamilySpacing.md),
                    Container(
                      padding: const EdgeInsets.all(FamilySpacing.md),
                      decoration: BoxDecoration(
                        color: FamilyColors.cloudGray,
                        borderRadius: FamilyBorderRadius.mdRadius,
                      ),
                      child: Text(
                        errorDetails!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontFamily: 'monospace',
                              color: FamilyColors.deepCharcoal.withOpacity(0.8),
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (onRetry != null) ...[
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
                  onPressed: onRetry,
                  gradient: LinearGradient(
                    colors: [FamilyColors.auroraTeal, FamilyColors.evergreen],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.refresh_rounded,
                        color: FamilyColors.pureWhite,
                        size: 20,
                      ),
                      const SizedBox(width: FamilySpacing.sm),
                      const Text(
                        'Try Again',
                        style: TextStyle(
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
