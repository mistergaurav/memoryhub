import 'package:flutter/material.dart';
import '../tokens/spacing_tokens.dart';

/// Gap widget for spacing between elements
/// Use instead of SizedBox with hardcoded values
class Gap extends StatelessWidget {
  final double size;

  const Gap(this.size, {super.key});

  /// 4px gap
  const Gap.xxs({super.key}) : size = Spacing.xxs;

  /// 8px gap
  const Gap.xs({super.key}) : size = Spacing.xs;

  /// 12px gap
  const Gap.sm({super.key}) : size = Spacing.sm;

  /// 16px gap
  const Gap.md({super.key}) : size = Spacing.md;

  /// 24px gap
  const Gap.lg({super.key}) : size = Spacing.lg;

  /// 32px gap
  const Gap.xl({super.key}) : size = Spacing.xl;

  /// 48px gap
  const Gap.xxl({super.key}) : size = Spacing.xxl;

  /// 64px gap
  const Gap.xxxl({super.key}) : size = Spacing.xxxl;

  @override
  Widget build(BuildContext context) {
    return SizedBox(width: size, height: size);
  }
}

/// Horizontal gap widget
class HGap extends StatelessWidget {
  final double width;

  const HGap(this.width, {super.key});

  const HGap.xxs({super.key}) : width = Spacing.xxs;
  const HGap.xs({super.key}) : width = Spacing.xs;
  const HGap.sm({super.key}) : width = Spacing.sm;
  const HGap.md({super.key}) : width = Spacing.md;
  const HGap.lg({super.key}) : width = Spacing.lg;
  const HGap.xl({super.key}) : width = Spacing.xl;
  const HGap.xxl({super.key}) : width = Spacing.xxl;
  const HGap.xxxl({super.key}) : width = Spacing.xxxl;

  @override
  Widget build(BuildContext context) {
    return SizedBox(width: width);
  }
}

/// Vertical gap widget
class VGap extends StatelessWidget {
  final double height;

  const VGap(this.height, {super.key});

  const VGap.xxs({super.key}) : height = Spacing.xxs;
  const VGap.xs({super.key}) : height = Spacing.xs;
  const VGap.sm({super.key}) : height = Spacing.sm;
  const VGap.md({super.key}) : height = Spacing.md;
  const VGap.lg({super.key}) : height = Spacing.lg;
  const VGap.xl({super.key}) : height = Spacing.xl;
  const VGap.xxl({super.key}) : height = Spacing.xxl;
  const VGap.xxxl({super.key}) : height = Spacing.xxxl;

  @override
  Widget build(BuildContext context) {
    return SizedBox(height: height);
  }
}
