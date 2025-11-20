import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import '../design_system/design_tokens.dart';

class StatCard extends StatefulWidget {
  final String label;
  final String value;
  final IconData icon;
  final List<Color> gradientColors;
  final String? trend;
  final VoidCallback? onTap;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.gradientColors,
    this.trend,
    this.onTap,
  });

  @override
  State<StatCard> createState() => _StatCardState();
}

class _StatCardState extends State<StatCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: MemoryHubAnimations.slow,
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: MemoryHubAnimations.elasticOut,
      ),
    );
    
    _rotationAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: MemoryHubAnimations.easeOut,
      ),
    );
    
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: widget.gradientColors,
            ),
            borderRadius: MemoryHubBorderRadius.xxlRadius,
            boxShadow: [
              BoxShadow(
                color: widget.gradientColors.first.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                right: -10,
                top: -10,
                child: AnimatedBuilder(
                  animation: _rotationAnimation,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: _rotationAnimation.value * math.pi * 0.1,
                      child: Icon(
                        widget.icon,
                        size: 100,
                        color: Colors.white.withOpacity(0.1),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: EdgeInsets.all(MemoryHubSpacing.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: EdgeInsets.all(MemoryHubSpacing.md),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: MemoryHubBorderRadius.mdRadius,
                      ),
                      child: Icon(
                        widget.icon,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.value,
                          style: GoogleFonts.inter(
                            fontSize: MemoryHubTypography.h1,
                            fontWeight: MemoryHubTypography.bold,
                            color: Colors.white,
                            height: 1.0,
                          ),
                        ),
                        const SizedBox(height: MemoryHubSpacing.xs),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                widget.label,
                                style: GoogleFonts.inter(
                                  fontSize: MemoryHubTypography.bodyMedium,
                                  fontWeight: MemoryHubTypography.medium,
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              ),
                            ),
                            if (widget.trend != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: MemoryHubSpacing.sm,
                                  vertical: MemoryHubSpacing.xs,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: MemoryHubBorderRadius.smRadius,
                                ),
                                child: Text(
                                  widget.trend!,
                                  style: GoogleFonts.inter(
                                    fontSize: MemoryHubTypography.caption,
                                    fontWeight: MemoryHubTypography.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
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
