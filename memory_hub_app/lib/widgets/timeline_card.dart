import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../design_system/design_tokens.dart';

class TimelineCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final DateTime date;
  final IconData icon;
  final List<Color> gradientColors;
  final VoidCallback? onTap;
  final Widget? trailing;

  const TimelineCard({
    super.key,
    required this.title,
    this.subtitle,
    required this.date,
    required this.icon,
    required this.gradientColors,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Card(
      margin: const EdgeInsets.only(bottom: MemoryHubSpacing.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: MemoryHubBorderRadius.xlRadius,
        child: Padding(
          padding: const EdgeInsets.all(MemoryHubSpacing.lg),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: gradientColors,
                  ),
                  borderRadius: MemoryHubBorderRadius.mdRadius,
                  boxShadow: [
                    BoxShadow(
                      color: gradientColors.first.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: MemoryHubSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: MemoryHubTypography.h5,
                        fontWeight: MemoryHubTypography.semiBold,
                        color: isDark ? Colors.white : MemoryHubColors.gray900,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: MemoryHubSpacing.xs),
                      Text(
                        subtitle!,
                        style: GoogleFonts.inter(
                          fontSize: MemoryHubTypography.bodySmall,
                          color: isDark
                              ? MemoryHubColors.gray400
                              : MemoryHubColors.gray600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              trailing ??
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: isDark
                        ? MemoryHubColors.gray500
                        : MemoryHubColors.gray400,
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

class TimelineCardWithDate extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String dateLabel;
  final String monthLabel;
  final IconData icon;
  final List<Color> gradientColors;
  final VoidCallback? onTap;
  final List<Widget>? badges;

  const TimelineCardWithDate({
    super.key,
    required this.title,
    this.subtitle,
    required this.dateLabel,
    required this.monthLabel,
    required this.icon,
    required this.gradientColors,
    this.onTap,
    this.badges,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Card(
      margin: const EdgeInsets.only(bottom: MemoryHubSpacing.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: MemoryHubBorderRadius.xlRadius,
        child: Padding(
          padding: const EdgeInsets.all(MemoryHubSpacing.lg),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: gradientColors,
                  ),
                  borderRadius: MemoryHubBorderRadius.mdRadius,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      monthLabel,
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: MemoryHubTypography.bold,
                      ),
                    ),
                    Text(
                      dateLabel,
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: MemoryHubTypography.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: MemoryHubSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: MemoryHubTypography.h5,
                        fontWeight: MemoryHubTypography.semiBold,
                        color: isDark ? Colors.white : MemoryHubColors.gray900,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: MemoryHubSpacing.xs),
                      Text(
                        subtitle!,
                        style: GoogleFonts.inter(
                          fontSize: MemoryHubTypography.bodySmall,
                          color: isDark
                              ? MemoryHubColors.gray400
                              : MemoryHubColors.gray600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (badges != null && badges!.isNotEmpty) ...[
                      const SizedBox(height: MemoryHubSpacing.sm),
                      Wrap(
                        spacing: MemoryHubSpacing.sm,
                        runSpacing: MemoryHubSpacing.xs,
                        children: badges!,
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: isDark
                    ? MemoryHubColors.gray500
                    : MemoryHubColors.gray400,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
