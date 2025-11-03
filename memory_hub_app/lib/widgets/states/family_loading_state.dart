import 'package:flutter/material.dart';
import '../../design_system/family_design_system.dart';
import '../animated/family_skeleton_loader.dart';

class FamilyLoadingState extends StatelessWidget {
  final String? message;
  final LoadingStyle style;

  const FamilyLoadingState({
    Key? key,
    this.message,
    this.style = LoadingStyle.spinner,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    switch (style) {
      case LoadingStyle.spinner:
        return _buildSpinner(context);
      case LoadingStyle.skeleton:
        return _buildSkeleton(context);
      case LoadingStyle.shimmer:
        return _buildShimmer(context);
    }
  }

  Widget _buildSpinner(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
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
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: FamilyColors.familyDashboardGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: FamilyColors.midnightIndigo.withOpacity(0.3),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Padding(
                padding: EdgeInsets.all(FamilySpacing.lg),
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    FamilyColors.pureWhite,
                  ),
                ),
              ),
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: FamilySpacing.xl),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: FamilyAnimations.moderate,
              curve: Curves.easeOut,
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: child,
                );
              },
              child: Text(
                message!,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: FamilyColors.deepCharcoal.withOpacity(0.6),
                    ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSkeleton(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(FamilySpacing.lg),
      itemCount: 5,
      itemBuilder: (context, index) => const Padding(
        padding: EdgeInsets.only(bottom: FamilySpacing.md),
        child: FamilySkeletonCard(),
      ),
    );
  }

  Widget _buildShimmer(BuildContext context) {
    return const FamilySkeletonGrid();
  }
}

enum LoadingStyle {
  spinner,
  skeleton,
  shimmer,
}
