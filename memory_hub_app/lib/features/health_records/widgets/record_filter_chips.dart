import 'package:flutter/material.dart';
import '../design_system.dart';

class RecordFilterChips extends StatelessWidget {
  final String selectedFilter;
  final Function(String) onFilterSelected;
  final List<Map<String, dynamic>> filters;

  const RecordFilterChips({
    Key? key,
    required this.selectedFilter,
    required this.onFilterSelected,
    required this.filters,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: HealthRecordsDesignSystem.spacing16),
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: HealthRecordsDesignSystem.spacing8),
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = selectedFilter == filter['value'];
          final color = filter['color'] as Color? ?? HealthRecordsDesignSystem.deepCobalt;

          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: Duration(milliseconds: 300 + (index * 50)),
            curve: HealthRecordsDesignSystem.animationCurve,
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, 10 * (1 - value)),
                child: Opacity(
                  opacity: value,
                  child: child,
                ),
              );
            },
            child: AnimatedFilterChip(
              label: filter['label'] as String,
              icon: filter['icon'] as IconData,
              isSelected: isSelected,
              color: color,
              onTap: () => onFilterSelected(filter['value'] as String),
            ),
          );
        },
      ),
    );
  }
}

class AnimatedFilterChip extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const AnimatedFilterChip({
    Key? key,
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.color,
    required this.onTap,
  }) : super(key: key);

  @override
  State<AnimatedFilterChip> createState() => _AnimatedFilterChipState();
}

class _AnimatedFilterChipState extends State<AnimatedFilterChip>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: AnimatedContainer(
          duration: HealthRecordsDesignSystem.animationNormal,
          curve: HealthRecordsDesignSystem.animationCurve,
          padding: const EdgeInsets.symmetric(
            horizontal: HealthRecordsDesignSystem.spacing16,
            vertical: HealthRecordsDesignSystem.spacing12,
          ),
          decoration: BoxDecoration(
            color: widget.isSelected ? widget.color : HealthRecordsDesignSystem.surfaceColor,
            borderRadius: BorderRadius.circular(HealthRecordsDesignSystem.radiusLarge),
            border: Border.all(
              color: widget.isSelected
                  ? widget.color
                  : HealthRecordsDesignSystem.dividerColor,
              width: 1.5,
            ),
            boxShadow: widget.isSelected
                ? [HealthRecordsDesignSystem.coloredShadow(widget.color, opacity: 0.25)]
                : HealthRecordsDesignSystem.shadowSmall,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                size: 18,
                color: widget.isSelected
                    ? Colors.white
                    : HealthRecordsDesignSystem.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                widget.label,
                style: HealthRecordsDesignSystem.textTheme.labelLarge?.copyWith(
                  color: widget.isSelected
                      ? Colors.white
                      : HealthRecordsDesignSystem.textPrimary,
                ),
              ),
              if (widget.isSelected) ...[
                const SizedBox(width: 4),
                const Icon(Icons.check_circle, size: 16, color: Colors.white),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
