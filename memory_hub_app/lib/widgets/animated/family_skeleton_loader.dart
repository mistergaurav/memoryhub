import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../design_system/family_design_system.dart';

class FamilySkeletonLoader extends StatelessWidget {
  final double height;
  final double width;
  final BorderRadius? borderRadius;

  const FamilySkeletonLoader({
    Key? key,
    this.height = 16,
    this.width = double.infinity,
    this.borderRadius,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: FamilyColors.cloudGray,
      highlightColor: FamilyColors.softSand,
      period: const Duration(milliseconds: 1500),
      child: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: FamilyColors.cloudGray,
          borderRadius: borderRadius ?? FamilyBorderRadius.mdRadius,
        ),
      ),
    );
  }
}

class FamilySkeletonCard extends StatelessWidget {
  const FamilySkeletonCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: FamilyElevation.md,
      shape: RoundedRectangleBorder(
        borderRadius: FamilyBorderRadius.lgRadius,
      ),
      child: Padding(
        padding: const EdgeInsets.all(FamilySpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FamilySkeletonLoader(
              height: 24,
              width: 150,
              borderRadius: FamilyBorderRadius.smRadius,
            ),
            const SizedBox(height: FamilySpacing.md),
            FamilySkeletonLoader(
              height: 16,
              width: double.infinity,
              borderRadius: FamilyBorderRadius.smRadius,
            ),
            const SizedBox(height: FamilySpacing.sm),
            FamilySkeletonLoader(
              height: 16,
              width: 200,
              borderRadius: FamilyBorderRadius.smRadius,
            ),
          ],
        ),
      ),
    );
  }
}

class FamilySkeletonListItem extends StatelessWidget {
  const FamilySkeletonListItem({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: FamilySpacing.lg,
        vertical: FamilySpacing.sm,
      ),
      child: Row(
        children: [
          FamilySkeletonLoader(
            height: 48,
            width: 48,
            borderRadius: BorderRadius.circular(24),
          ),
          const SizedBox(width: FamilySpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FamilySkeletonLoader(
                  height: 16,
                  width: double.infinity,
                  borderRadius: FamilyBorderRadius.smRadius,
                ),
                const SizedBox(height: FamilySpacing.sm),
                FamilySkeletonLoader(
                  height: 12,
                  width: 150,
                  borderRadius: FamilyBorderRadius.smRadius,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class FamilySkeletonGrid extends StatelessWidget {
  final int itemCount;

  const FamilySkeletonGrid({
    Key? key,
    this.itemCount = 6,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(FamilySpacing.lg),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: FamilySpacing.lg,
        mainAxisSpacing: FamilySpacing.lg,
        childAspectRatio: 0.75,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) => const FamilySkeletonCard(),
    );
  }
}
