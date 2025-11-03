import 'package:flutter/material.dart';
import '../design_system.dart';

class HealthStatsCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const HealthStatsCard({
    Key? key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          return Transform.scale(
            scale: 0.9 + (value * 0.1),
            child: Opacity(
              opacity: value,
              child: child,
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(HealthRecordsDesignSystem.spacing16),
          decoration: BoxDecoration(
            color: HealthRecordsDesignSystem.surfaceColor,
            borderRadius: BorderRadius.circular(HealthRecordsDesignSystem.radiusMedium),
            boxShadow: HealthRecordsDesignSystem.shadowSmall,
            border: Border.all(
              color: color.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(HealthRecordsDesignSystem.radiusMedium),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: HealthRecordsDesignSystem.spacing12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TweenAnimationBuilder<int>(
                      tween: IntTween(begin: 0, end: int.tryParse(value) ?? 0),
                      duration: const Duration(milliseconds: 800),
                      curve: Curves.easeOut,
                      builder: (context, animatedValue, child) {
                        return Text(
                          int.tryParse(value) != null
                              ? animatedValue.toString()
                              : value,
                          style: HealthRecordsDesignSystem.textTheme.displaySmall?.copyWith(
                            color: HealthRecordsDesignSystem.textPrimary,
                            height: 1.0,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 2),
                    Text(
                      label,
                      style: HealthRecordsDesignSystem.textTheme.bodySmall?.copyWith(
                        color: HealthRecordsDesignSystem.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
