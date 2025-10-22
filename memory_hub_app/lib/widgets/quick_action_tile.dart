import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../design_system/design_tokens.dart';

class QuickActionTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String? badge;

  const QuickActionTile({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: MemoryHubBorderRadius.xlRadius,
      child: Container(
        width: 85,
        padding: const EdgeInsets.all(MemoryHubSpacing.md),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: MemoryHubBorderRadius.xlRadius,
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.all(MemoryHubSpacing.sm),
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                if (badge != null)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: MemoryHubColors.red500,
                        borderRadius: MemoryHubBorderRadius.smRadius,
                      ),
                      child: Text(
                        badge!,
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: MemoryHubTypography.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: MemoryHubSpacing.sm),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: MemoryHubTypography.semiBold,
                color: color,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class QuickActionGrid extends StatelessWidget {
  final List<QuickActionTileData> actions;
  final int crossAxisCount;
  final double childAspectRatio;

  const QuickActionGrid({
    super.key,
    required this.actions,
    this.crossAxisCount = 4,
    this.childAspectRatio = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: MemoryHubSpacing.md,
        mainAxisSpacing: MemoryHubSpacing.md,
        childAspectRatio: childAspectRatio,
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        final action = actions[index];
        return QuickActionTile(
          label: action.label,
          icon: action.icon,
          color: action.color,
          onTap: action.onTap,
          badge: action.badge,
        );
      },
    );
  }
}

class QuickActionHorizontalList extends StatelessWidget {
  final List<QuickActionTileData> actions;
  final String? title;

  const QuickActionHorizontalList({
    super.key,
    required this.actions,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: MemoryHubSpacing.lg,
            ),
            child: Text(
              title!,
              style: GoogleFonts.inter(
                fontSize: MemoryHubTypography.h4,
                fontWeight: MemoryHubTypography.bold,
                color: isDark ? Colors.white : MemoryHubColors.gray900,
              ),
            ),
          ),
        const SizedBox(height: MemoryHubSpacing.md),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: MemoryHubSpacing.md,
            ),
            itemCount: actions.length,
            itemBuilder: (context, index) {
              final action = actions[index];
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: MemoryHubSpacing.xs,
                ),
                child: QuickActionTile(
                  label: action.label,
                  icon: action.icon,
                  color: action.color,
                  onTap: action.onTap,
                  badge: action.badge,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class QuickActionTileData {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String? badge;

  const QuickActionTileData({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    this.badge,
  });
}
