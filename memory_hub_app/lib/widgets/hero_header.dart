import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../design_system/design_tokens.dart';

class HeroHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final List<Color> gradientColors;
  final List<Widget>? actions;
  final double expandedHeight;

  const HeroHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    required this.gradientColors,
    this.actions,
    this.expandedHeight = 200.0,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: expandedHeight,
      floating: false,
      pinned: true,
      actions: actions,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          title,
          style: GoogleFonts.inter(
            fontWeight: MemoryHubTypography.bold,
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradientColors,
            ),
          ),
          child: Stack(
            children: [
              if (icon != null)
                Positioned(
                  right: -50,
                  top: -50,
                  child: Icon(
                    icon,
                    size: 200,
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
              Positioned(
                right: -30,
                bottom: -30,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.05),
                  ),
                ),
              ),
              Positioned(
                left: -20,
                top: 80,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.05),
                  ),
                ),
              ),
              if (subtitle != null)
                Positioned(
                  bottom: 60,
                  left: MemoryHubSpacing.xl,
                  right: MemoryHubSpacing.xl,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subtitle!,
                        style: GoogleFonts.inter(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: MemoryHubTypography.h5,
                          fontWeight: MemoryHubTypography.light,
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

class HeroHeaderWithDate extends StatelessWidget {
  final String title;
  final String subtitle;
  final String date;
  final IconData? icon;
  final List<Color> gradientColors;
  final List<Widget>? actions;
  final double expandedHeight;

  const HeroHeaderWithDate({
    super.key,
    required this.title,
    required this.subtitle,
    required this.date,
    this.icon,
    required this.gradientColors,
    this.actions,
    this.expandedHeight = 200.0,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: expandedHeight,
      floating: false,
      pinned: true,
      actions: actions,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          title,
          style: GoogleFonts.inter(
            fontWeight: MemoryHubTypography.bold,
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradientColors,
            ),
          ),
          child: Stack(
            children: [
              if (icon != null)
                Positioned(
                  right: -50,
                  top: -50,
                  child: Icon(
                    icon,
                    size: 200,
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
              Positioned(
                bottom: 60,
                left: MemoryHubSpacing.xl,
                right: MemoryHubSpacing.xl,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: MemoryHubTypography.h5,
                        fontWeight: MemoryHubTypography.light,
                      ),
                    ),
                    const SizedBox(height: MemoryHubSpacing.xs),
                    Text(
                      date,
                      style: GoogleFonts.inter(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: MemoryHubTypography.caption,
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
