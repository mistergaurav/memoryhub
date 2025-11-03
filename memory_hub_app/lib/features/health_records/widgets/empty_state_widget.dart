import 'package:flutter/material.dart';
import '../design_system.dart';

class HealthRecordsEmptyState extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color? iconColor;

  const HealthRecordsEmptyState({
    Key? key,
    required this.title,
    required this.message,
    required this.icon,
    this.actionLabel,
    this.onAction,
    this.iconColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(HealthRecordsDesignSystem.spacing32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 800),
              curve: Curves.elasticOut,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: child,
                );
              },
              child: Container(
                padding: const EdgeInsets.all(HealthRecordsDesignSystem.spacing32),
                decoration: BoxDecoration(
                  color: (iconColor ?? HealthRecordsDesignSystem.deepCobalt).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 80,
                  color: iconColor ?? HealthRecordsDesignSystem.deepCobalt,
                ),
              ),
            ),
            const SizedBox(height: HealthRecordsDesignSystem.spacing24),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 600),
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
                    style: HealthRecordsDesignSystem.textTheme.displayMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: HealthRecordsDesignSystem.spacing12),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: HealthRecordsDesignSystem.textTheme.bodyLarge?.copyWith(
                      color: HealthRecordsDesignSystem.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: HealthRecordsDesignSystem.spacing32),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 700),
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
                child: ElevatedButton.icon(
                  onPressed: onAction,
                  icon: const Icon(Icons.add_rounded),
                  label: Text(
                    actionLabel!,
                    style: HealthRecordsDesignSystem.textTheme.labelLarge?.copyWith(
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: iconColor ?? HealthRecordsDesignSystem.deepCobalt,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: HealthRecordsDesignSystem.spacing32,
                      vertical: HealthRecordsDesignSystem.spacing16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(HealthRecordsDesignSystem.radiusMedium),
                    ),
                    elevation: 0,
                    shadowColor: (iconColor ?? HealthRecordsDesignSystem.deepCobalt).withOpacity(0.3),
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
