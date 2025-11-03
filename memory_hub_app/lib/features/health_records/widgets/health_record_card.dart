import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../design_system.dart';
import '../models/health_record.dart';
import 'subject_type_badge.dart';
import '../../../widgets/approval_status_badge.dart';

class HealthRecordCard extends StatelessWidget {
  final HealthRecord record;
  final VoidCallback onTap;
  final int animationDelay;
  final bool isGridView;

  const HealthRecordCard({
    Key? key,
    required this.record,
    required this.onTap,
    this.animationDelay = 0,
    this.isGridView = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: HealthRecordsDesignSystem.animationNormal,
      curve: HealthRecordsDesignSystem.animationCurve,
      builder: (context, value, child) {
        final offset = isGridView ? 20 * (1 - value) : 0.0;
        final scale = isGridView ? 0.8 + (value * 0.2) : 1.0;
        
        return Transform.translate(
          offset: Offset(0, offset),
          child: Transform.scale(
            scale: scale,
            child: Opacity(
              opacity: value,
              child: child,
            ),
          ),
        );
      },
      child: isGridView ? _buildGridCard(context) : _buildListCard(context),
    );
  }

  Widget _buildGridCard(BuildContext context) {
    final color = HealthRecordsDesignSystem.getRecordTypeColor(record.recordType);
    final icon = HealthRecordsDesignSystem.getRecordTypeIcon(record.recordType);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: HealthRecordsDesignSystem.surfaceColor,
          borderRadius: BorderRadius.circular(HealthRecordsDesignSystem.radiusXLarge),
          boxShadow: [HealthRecordsDesignSystem.coloredShadow(color, opacity: 0.15)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [color, color.withOpacity(0.7)],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(HealthRecordsDesignSystem.radiusXLarge),
                  topRight: Radius.circular(HealthRecordsDesignSystem.radiusXLarge),
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: -15,
                    top: -15,
                    child: Icon(
                      icon,
                      size: 80,
                      color: Colors.white.withOpacity(0.2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(HealthRecordsDesignSystem.spacing16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(HealthRecordsDesignSystem.radiusSmall),
                          ),
                          child: Text(
                            HealthRecordsDesignSystem.formatRecordType(record.recordType),
                            style: HealthRecordsDesignSystem.textTheme.labelSmall?.copyWith(
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const Spacer(),
                        if (record.isConfidential)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.25),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.lock_rounded, size: 12, color: Colors.white),
                                const SizedBox(width: 4),
                                Text(
                                  'Private',
                                  style: HealthRecordsDesignSystem.textTheme.labelSmall?.copyWith(
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(HealthRecordsDesignSystem.spacing12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.title,
                      style: HealthRecordsDesignSystem.textTheme.headlineSmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: HealthRecordsDesignSystem.spacing8),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_rounded,
                          size: 12,
                          color: HealthRecordsDesignSystem.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('MMM d, yyyy').format(record.recordDate),
                          style: HealthRecordsDesignSystem.textTheme.bodySmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    SubjectTypeBadge(
                      subjectType: record.subjectType,
                      subjectName: record.subjectName,
                      compact: true,
                    ),
                    const SizedBox(height: 6),
                    buildApprovalStatusBadge(record.approvalStatus),
                    if (record.hasReminders) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: HealthRecordsDesignSystem.warningOrange.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.notifications_active,
                              size: 10,
                              color: HealthRecordsDesignSystem.warningOrange,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              '${record.reminders.length}',
                              style: HealthRecordsDesignSystem.textTheme.labelSmall?.copyWith(
                                color: HealthRecordsDesignSystem.warningOrange,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListCard(BuildContext context) {
    final color = HealthRecordsDesignSystem.getRecordTypeColor(record.recordType);
    final icon = HealthRecordsDesignSystem.getRecordTypeIcon(record.recordType);

    return Container(
      margin: const EdgeInsets.only(bottom: HealthRecordsDesignSystem.spacing12),
      decoration: BoxDecoration(
        color: HealthRecordsDesignSystem.surfaceColor,
        borderRadius: BorderRadius.circular(HealthRecordsDesignSystem.radiusLarge),
        boxShadow: HealthRecordsDesignSystem.shadowMedium,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(HealthRecordsDesignSystem.radiusLarge),
          child: Padding(
            padding: const EdgeInsets.all(HealthRecordsDesignSystem.spacing16),
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [color, color.withOpacity(0.7)],
                    ),
                    borderRadius: BorderRadius.circular(HealthRecordsDesignSystem.radiusMedium),
                    boxShadow: [HealthRecordsDesignSystem.coloredShadow(color, opacity: 0.3)],
                  ),
                  child: Icon(icon, color: Colors.white, size: 32),
                ),
                const SizedBox(width: HealthRecordsDesignSystem.spacing16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              record.title,
                              style: HealthRecordsDesignSystem.textTheme.headlineMedium,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (record.isConfidential) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: HealthRecordsDesignSystem.errorRed.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.lock_rounded, size: 11, color: HealthRecordsDesignSystem.errorRed),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Private',
                                    style: HealthRecordsDesignSystem.textTheme.labelSmall?.copyWith(
                                      color: HealthRecordsDesignSystem.errorRed,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              HealthRecordsDesignSystem.formatRecordType(record.recordType),
                              style: HealthRecordsDesignSystem.textTheme.labelMedium?.copyWith(
                                color: color,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(Icons.calendar_today_rounded, size: 12, color: HealthRecordsDesignSystem.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat('MMM d, yyyy').format(record.recordDate),
                            style: HealthRecordsDesignSystem.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          SubjectTypeBadge(
                            subjectType: record.subjectType,
                            subjectName: record.subjectName,
                            compact: true,
                          ),
                          const SizedBox(width: 8),
                          buildApprovalStatusBadge(record.approvalStatus),
                          if (record.hasReminders) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(
                                color: HealthRecordsDesignSystem.warningOrange.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.notifications_active,
                                    size: 11,
                                    color: HealthRecordsDesignSystem.warningOrange,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    '${record.reminders.length}',
                                    style: HealthRecordsDesignSystem.textTheme.labelSmall?.copyWith(
                                      color: HealthRecordsDesignSystem.warningOrange,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (record.description != null && record.description!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          record.description!,
                          style: HealthRecordsDesignSystem.textTheme.bodyMedium,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: HealthRecordsDesignSystem.spacing12),
                Icon(
                  Icons.chevron_right_rounded,
                  color: HealthRecordsDesignSystem.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
