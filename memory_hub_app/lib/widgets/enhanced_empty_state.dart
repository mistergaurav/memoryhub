import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../design_system/design_tokens.dart';

class EnhancedEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final List<Color>? gradientColors;
  final IconData? actionIcon;

  const EnhancedEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.gradientColors,
    this.actionIcon,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = gradientColors ?? [
      Theme.of(context).colorScheme.primary.withOpacity(0.1),
      Theme.of(context).colorScheme.secondary.withOpacity(0.1),
    ];

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(MemoryHubSpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: colors,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(
                icon,
                size: 60,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: MemoryHubSpacing.xl),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: MemoryHubTypography.h2,
                fontWeight: MemoryHubTypography.bold,
                color: isDark ? Colors.white : MemoryHubColors.gray900,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: MemoryHubSpacing.md),
            Text(
              message,
              style: GoogleFonts.inter(
                fontSize: MemoryHubTypography.h5,
                color: isDark ? MemoryHubColors.gray400 : MemoryHubColors.gray600,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: MemoryHubSpacing.xxl),
              ElevatedButton.icon(
                onPressed: onAction,
                icon: Icon(actionIcon ?? Icons.add),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
