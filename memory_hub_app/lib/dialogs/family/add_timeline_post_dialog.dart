import 'package:flutter/material.dart';
import 'package:memory_hub_app/design_system/design_system.dart';
import 'package:intl/intl.dart';
import 'add_event_dialog.dart';
import 'add_milestone_dialog.dart';

class AddTimelinePostDialog extends StatelessWidget {
  final Function(Map\u003cString, dynamic\u003e) onEventSubmit;
  final Function(Map\u003cString, dynamic\u003e) onMilestoneSubmit;
  final Function(Map\u003cString, dynamic\u003e)? onPostSubmit;

  const AddTimelinePostDialog({
    Key? key,
    required this.onEventSubmit,
    required this.onMilestoneSubmit,
    this.onPostSubmit,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: MemoryHubBorderRadius.xlRadius,
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: EdgeInsets.all(MemoryHubSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add to Timeline',
              style: TextStyle(
                fontSize: MemoryHubTypography.h3,
                fontWeight: MemoryHubTypography.bold,
                color: context.colors.onSurface,
              ),
            ),
            VGap.lg(),
            _buildOption(
              context,
              icon: Icons.celebration,
              title: 'Milestone',
              subtitle: 'Significant life moments like birthdays, graduations',
              color: Colors.orange,
              onTap: () {
                Navigator.pop(context);
                showDialog(
                  context: context,
                  builder: (context) => AddMilestoneDialog(
                    onSubmit: onMilestoneSubmit,
                  ),
                );
              },
            ),
            VGap.md(),
            _buildOption(
              context,
              icon: Icons.event,
              title: 'Event',
              subtitle: 'Schedule a gathering or reminder',
              color: Colors.blue,
              onTap: () {
                Navigator.pop(context);
                showDialog(
                  context: context,
                  builder: (context) => AddEventDialog(
                    onSubmit: onEventSubmit,
                  ),
                );
              },
            ),
            VGap.md(),
            _buildOption(
              context,
              icon: Icons.edit_note,
              title: 'Post',
              subtitle: 'Share a memory, thought, or photo',
              color: Colors.green,
              onTap: () {
                // For now, we can treat simple posts as generic milestones or implement a separate dialog
                // Using Milestone dialog with 'other' type for simplicity in this iteration
                Navigator.pop(context);
                showDialog(
                  context: context,
                  builder: (context) => AddMilestoneDialog(
                    onSubmit: onMilestoneSubmit,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: MemoryHubBorderRadius.lgRadius,
      child: Container(
        padding: EdgeInsets.all(MemoryHubSpacing.md),
        decoration: BoxDecoration(
          border: Border.all(color: context.colors.outlineVariant),
          borderRadius: MemoryHubBorderRadius.lgRadius,
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(MemoryHubSpacing.sm),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            HGap.md(),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: MemoryHubTypography.h4,
                      fontWeight: MemoryHubTypography.semiBold,
                      color: context.colors.onSurface,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: MemoryHubTypography.bodySmall,
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: context.colors.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
