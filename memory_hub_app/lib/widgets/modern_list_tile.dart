import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ModernListTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;
  final Color? iconColor;
  final Color? backgroundColor;
  final bool showChevron;
  final bool isDestructive;

  const ModernListTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.trailing,
    this.iconColor,
    this.backgroundColor,
    this.showChevron = true,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveIconColor = isDestructive
        ? Colors.red
        : iconColor ?? Theme.of(context).colorScheme.primary;
    
    final effectiveBackgroundColor = backgroundColor ??
        (isDestructive
            ? Colors.red.withOpacity(0.1)
            : Theme.of(context).colorScheme.primary.withOpacity(0.1));

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: effectiveBackgroundColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: effectiveIconColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isDestructive ? Colors.red : null,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null)
                trailing!
              else if (showChevron)
                Icon(
                  Icons.chevron_right,
                  color: Colors.grey[400],
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
