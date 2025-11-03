import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../design_system/family_design_system.dart';

class AnimatedFamilyButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final Gradient? gradient;
  final Color? backgroundColor;
  final EdgeInsets? padding;
  final BorderRadius? borderRadius;
  final bool enabled;

  const AnimatedFamilyButton({
    Key? key,
    required this.onPressed,
    required this.child,
    this.gradient,
    this.backgroundColor,
    this.padding,
    this.borderRadius,
    this.enabled = true,
  }) : super(key: key);

  @override
  State<AnimatedFamilyButton> createState() => _AnimatedFamilyButtonState();
}

class _AnimatedFamilyButtonState extends State<AnimatedFamilyButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: FamilyAnimations.quick,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: FamilyAnimations.scaleTo,
      end: FamilyAnimations.scaleFrom,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: FamilyAnimations.easeInOutCubic,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (!widget.enabled || widget.onPressed == null) return;
    setState(() => _isPressed = true);
    _controller.forward();
    HapticFeedback.lightImpact();
  }

  void _handleTapUp(TapUpDetails details) {
    if (!widget.enabled || widget.onPressed == null) return;
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  void _handleTapCancel() {
    if (!widget.enabled || widget.onPressed == null) return;
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  void _handleTap() {
    if (!widget.enabled || widget.onPressed == null) return;
    HapticFeedback.mediumImpact();
    widget.onPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    final opacity = widget.enabled ? 1.0 : 0.5;
    
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: AnimatedOpacity(
              opacity: opacity,
              duration: FamilyAnimations.quick,
              child: Container(
                padding: widget.padding ??
                    const EdgeInsets.symmetric(
                      horizontal: FamilySpacing.xl,
                      vertical: FamilySpacing.md,
                    ),
                decoration: BoxDecoration(
                  gradient: widget.gradient,
                  color: widget.backgroundColor,
                  borderRadius: widget.borderRadius ?? FamilyBorderRadius.lgRadius,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(_isPressed ? 0.1 : 0.2),
                      blurRadius: _isPressed ? 4 : 8,
                      offset: Offset(0, _isPressed ? 2 : 4),
                    ),
                  ],
                ),
                child: child,
              ),
            ),
          );
        },
        child: widget.child,
      ),
    );
  }
}
