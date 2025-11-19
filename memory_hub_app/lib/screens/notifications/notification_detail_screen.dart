import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../services/notifications_service.dart';
import '../../services/family/family_service.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/profile_avatar.dart';
import '../../design_system/design_tokens.dart';
import '../../design_system/layout/gap.dart';

class NotificationDetailScreen extends StatefulWidget {
  final String notificationId;

  const NotificationDetailScreen({
    super.key,
    required this.notificationId,
  });

  @override
  State<NotificationDetailScreen> createState() => _NotificationDetailScreenState();
}

class _NotificationDetailScreenState extends State<NotificationDetailScreen> {
  final NotificationsService _notificationsService = NotificationsService();
  final FamilyService _familyService = FamilyService();

  bool _isLoading = true;
  bool _isProcessing = false;
  String? _error;
  Map<String, dynamic>? _notificationDetails;
  String _selectedVisibilityScope = 'private';

  @override
  void initState() {
    super.initState();
    _loadNotificationDetails();
  }

  Future<void> _loadNotificationDetails() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final details = await _notificationsService.getNotificationDetails(widget.notificationId);
      setState(() {
        _notificationDetails = details;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _approveHealthRecord() async {
    if (_notificationDetails == null || _isProcessing) return;

    final healthRecordId = _notificationDetails!['health_record_id'];
    if (healthRecordId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Approve Health Record',
          style: GoogleFonts.inter(fontWeight: MemoryHubTypography.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select visibility scope for this health record:',
              style: GoogleFonts.inter(),
            ),
            VGap(MemoryHubSpacing.lg),
            DropdownButtonFormField<String>(
              value: _selectedVisibilityScope,
              decoration: InputDecoration(
                labelText: 'Visibility Scope',
                labelStyle: GoogleFonts.inter(),
                border: const OutlineInputBorder(),
              ),
              style: GoogleFonts.inter(color: Colors.black87),
              items: [
                DropdownMenuItem(
                  value: 'private',
                  child: Text('Private', style: GoogleFonts.inter()),
                ),
                DropdownMenuItem(
                  value: 'family',
                  child: Text('Family', style: GoogleFonts.inter()),
                ),
                DropdownMenuItem(
                  value: 'friends',
                  child: Text('Friends', style: GoogleFonts.inter()),
                ),
                DropdownMenuItem(
                  value: 'public',
                  child: Text('Public', style: GoogleFonts.inter()),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedVisibilityScope = value;
                  });
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel', style: GoogleFonts.inter()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: MemoryHubColors.green600),
            child: Text(
              'Approve',
              style: GoogleFonts.inter(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _isProcessing = true);

      try {
        await _familyService.approveHealthRecord(healthRecordId);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Health record approved successfully',
                style: GoogleFonts.inter(),
              ),
              backgroundColor: MemoryHubColors.green600,
            ),
          );

          Navigator.of(context).pop(true);
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isProcessing = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Error approving record: $e',
                style: GoogleFonts.inter(),
              ),
              backgroundColor: MemoryHubColors.red600,
            ),
          );
        }
      }
    }
  }

  Future<void> _rejectHealthRecord() async {
    if (_notificationDetails == null || _isProcessing) return;

    final healthRecordId = _notificationDetails!['health_record_id'];
    if (healthRecordId == null) return;

    String? reason;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Reject Health Record',
          style: GoogleFonts.inter(fontWeight: MemoryHubTypography.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Are you sure you want to reject this health record?',
              style: GoogleFonts.inter(),
            ),
            VGap(MemoryHubSpacing.lg),
            TextField(
              decoration: InputDecoration(
                labelText: 'Reason (optional)',
                labelStyle: GoogleFonts.inter(),
                border: const OutlineInputBorder(),
                hintText: 'Enter rejection reason...',
                hintStyle: GoogleFonts.inter(color: MemoryHubColors.gray500),
              ),
              style: GoogleFonts.inter(),
              maxLines: 3,
              onChanged: (value) => reason = value,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel', style: GoogleFonts.inter()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: MemoryHubColors.red600),
            child: Text(
              'Reject',
              style: GoogleFonts.inter(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _isProcessing = true);

      try {
        await _familyService.rejectHealthRecord(healthRecordId, reason);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Health record rejected',
                style: GoogleFonts.inter(),
              ),
              backgroundColor: MemoryHubColors.red600,
            ),
          );

          Navigator.of(context).pop(true);
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isProcessing = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Error rejecting record: $e',
                style: GoogleFonts.inter(),
              ),
              backgroundColor: MemoryHubColors.red600,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Notification Details',
          style: GoogleFonts.inter(fontWeight: MemoryHubTypography.bold),
        ),
        elevation: 0,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: LoadingIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: MemoryHubColors.red300),
            VGap(MemoryHubSpacing.lg),
            Text(
              'Error loading notification',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: MemoryHubTypography.bold,
              ),
            ),
            VGap(MemoryHubSpacing.sm),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: MemoryHubSpacing.xxl + 8),
              child: Text(
                _error!,
                style: GoogleFonts.inter(color: MemoryHubColors.gray600),
                textAlign: TextAlign.center,
              ),
            ),
            VGap(MemoryHubSpacing.xxl),
            ElevatedButton.icon(
              onPressed: _loadNotificationDetails,
              icon: const Icon(Icons.refresh),
              label: Text('Retry', style: GoogleFonts.inter()),
            ),
          ],
        ),
      );
    }

    if (_notificationDetails == null) {
      return Center(
        child: Text(
          'Notification not found',
          style: GoogleFonts.inter(fontSize: 16, color: MemoryHubColors.gray600),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAssignerInfo(),
          const SizedBox(height: 24),
          _buildHealthRecordInfo(),
          if (_notificationDetails!['has_reminder'] == true) ...[
            VGap(MemoryHubSpacing.xxl),
            _buildReminderInfo(),
          ],
          if (_notificationDetails!['can_approve'] == true ||
              _notificationDetails!['can_reject'] == true) ...[
            VGap(MemoryHubSpacing.xxl + 8),
            _buildActionButtons(),
          ],
        ],
      ),
    );
  }

  Widget _buildAssignerInfo() {
    final assignerName = _notificationDetails!['assigner_name'] ?? 'Unknown';
    final assignerAvatar = _notificationDetails!['assigner_avatar'];
    final assignedAt = _notificationDetails!['assigned_at'];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            ProfileAvatar(
              imageUrl: assignerAvatar,
              size: 60,
              name: assignerName,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Assigned by',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    assignerName,
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (assignedAt != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(assignedAt),
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthRecordInfo() {
    final title = _notificationDetails!['record_title'] ?? 'Untitled Record';
    final type = _notificationDetails!['record_type'] ?? 'medical';
    final description = _notificationDetails!['record_description'];
    final date = _notificationDetails!['record_date'];
    final provider = _notificationDetails!['record_provider'];
    final severity = _notificationDetails!['record_severity'];
    final approvalStatus = _notificationDetails!['approval_status'] ?? 'pending';

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Health Record Details',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _buildStatusBadge(approvalStatus),
              ],
            ),
            const Divider(height: 24),
            _buildInfoRow(Icons.title, 'Title', title),
            VGap(MemoryHubSpacing.md),
            _buildInfoRow(Icons.medical_services, 'Type', _formatType(type)),
            if (description != null && description.isNotEmpty) ...[
              VGap(MemoryHubSpacing.md),
              _buildInfoRow(Icons.description, 'Description', description),
            ],
            if (date != null && date.isNotEmpty) ...[
              VGap(MemoryHubSpacing.md),
              _buildInfoRow(Icons.calendar_today, 'Date', _formatDate(date)),
            ],
            if (provider != null && provider.isNotEmpty) ...[
              VGap(MemoryHubSpacing.md),
              _buildInfoRow(Icons.local_hospital, 'Provider', provider),
            ],
            if (severity != null && severity.isNotEmpty) ...[
              VGap(MemoryHubSpacing.md),
              _buildInfoRow(Icons.warning, 'Severity', _formatSeverity(severity)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildReminderInfo() {
    final reminderTitle = _notificationDetails!['reminder_title'];
    final reminderDueAt = _notificationDetails!['reminder_due_at'];

    return Card(
      elevation: 2,
      color: Colors.amber[50],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.alarm, color: Colors.amber[700]),
                const SizedBox(width: 8),
                Text(
                  'Reminder Set',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            if (reminderTitle != null) ...[
              VGap(MemoryHubSpacing.md),
              Text(
                reminderTitle,
                style: GoogleFonts.inter(fontSize: 14),
              ),
            ],
            if (reminderDueAt != null) ...[
              VGap(MemoryHubSpacing.sm),
              Row(
                children: [
                  Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    'Due: ${_formatDate(reminderDueAt)}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    final canApprove = _notificationDetails!['can_approve'] == true;
    final canReject = _notificationDetails!['can_reject'] == true;
    final approvalStatus = _notificationDetails!['approval_status'] ?? 'pending';

    if (approvalStatus != 'pending') {
      return const SizedBox.shrink();
    }

    return Row(
      children: [
        if (canReject)
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _isProcessing ? null : _rejectHealthRecord,
              icon: const Icon(Icons.cancel, size: 20),
              label: Text(
                'Reject',
                style: GoogleFonts.inter(fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: MemoryHubColors.red600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        if (canApprove && canReject) const SizedBox(width: 16),
        if (canApprove)
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _isProcessing ? null : _approveHealthRecord,
              icon: const Icon(Icons.check_circle, size: 20),
              label: Text(
                'Approve',
                style: GoogleFonts.inter(fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.blue[700]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.inter(fontSize: 14),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String label;

    switch (status.toLowerCase()) {
      case 'approved':
        color = Colors.green;
        label = 'Approved';
        break;
      case 'rejected':
        color = Colors.red;
        label = 'Rejected';
        break;
      default:
        color = Colors.orange;
        label = 'Pending';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  String _formatDate(dynamic date) {
    try {
      if (date is String) {
        final dateTime = DateTime.parse(date);
        return DateFormat('MMM d, yyyy h:mm a').format(dateTime);
      }
      return date.toString();
    } catch (e) {
      return date.toString();
    }
  }

  String _formatType(String type) {
    return type.split('_').map((word) {
      return word[0].toUpperCase() + word.substring(1);
    }).join(' ');
  }

  String _formatSeverity(String severity) {
    return severity[0].toUpperCase() + severity.substring(1);
  }
}
