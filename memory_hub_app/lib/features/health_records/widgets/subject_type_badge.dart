import 'package:flutter/material.dart';
import '../design_system.dart';

class SubjectTypeBadge extends StatelessWidget {
  final String subjectType;
  final String? subjectName;
  final bool compact;

  const SubjectTypeBadge({
    Key? key,
    required this.subjectType,
    this.subjectName,
    this.compact = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final color = HealthRecordsDesignSystem.getSubjectTypeColor(subjectType);
    final text = _getDisplayText();
    final icon = _getIcon();

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8,
        vertical: compact ? 3 : 4,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: compact ? 11 : 12,
            color: color,
          ),
          SizedBox(width: compact ? 3 : 4),
          Flexible(
            child: Text(
              text,
              style: (compact
                      ? HealthRecordsDesignSystem.textTheme.labelSmall
                      : HealthRecordsDesignSystem.textTheme.labelMedium)
                  ?.copyWith(color: color),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _getDisplayText() {
    switch (subjectType.toLowerCase()) {
      case 'self':
        return 'Myself';
      case 'family':
        return subjectName ?? 'Family Member';
      case 'friend':
        return subjectName ?? 'Friend';
      default:
        return subjectName ?? 'Unknown';
    }
  }

  IconData _getIcon() {
    switch (subjectType.toLowerCase()) {
      case 'self':
        return Icons.person_rounded;
      case 'family':
        return Icons.family_restroom_rounded;
      case 'friend':
        return Icons.people_rounded;
      default:
        return Icons.person_pin_rounded;
    }
  }
}
