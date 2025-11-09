import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../design_system.dart';
import '../data/health_records_repository.dart';
import '../models/health_record.dart';
import '../../../models/family/health_record_reminder.dart';
import '../../../widgets/shimmer_loading.dart';

class HealthRecordDetailsScreen extends StatefulWidget {
  final String recordId;

  const HealthRecordDetailsScreen({
    Key? key,
    required this.recordId,
  }) : super(key: key);

  @override
  State<HealthRecordDetailsScreen> createState() => _HealthRecordDetailsScreenState();
}

class _HealthRecordDetailsScreenState extends State<HealthRecordDetailsScreen> {
  final HealthRecordsRepository _repository = HealthRecordsRepository();
  HealthRecord? _record;
  List<HealthRecordReminder> _reminders = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRecordDetails();
  }

  Future<void> _loadRecordDetails() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final record = await _repository.getRecordById(widget.recordId);
      final remindersData = await _repository.getReminders(recordId: widget.recordId);
      final reminders = remindersData
          .map((json) => HealthRecordReminder.fromJson(json as Map<String, dynamic>))
          .toList();

      if (!mounted) return;
      
      setState(() {
        _record = record;
        _reminders = reminders;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _error = 'Failed to load health record details';
        _isLoading = false;
      });
    }
  }

  Future<void> _handleSkipReminder(String reminderId) async {
    try {
      await _repository.skipReminder(reminderId);
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Reminder skipped'),
          backgroundColor: HealthRecordsDesignSystem.successGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(HealthRecordsDesignSystem.radiusMedium),
          ),
        ),
      );
      await _loadRecordDetails();
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to skip reminder: $e'),
          backgroundColor: HealthRecordsDesignSystem.errorRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(HealthRecordsDesignSystem.radiusMedium),
          ),
        ),
      );
    }
  }

  Future<void> _handleRemoveReminder(String reminderId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Reminder'),
        content: const Text('Are you sure you want to remove this reminder?'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(HealthRecordsDesignSystem.radiusMedium),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: HealthRecordsDesignSystem.errorRed,
              foregroundColor: Colors.white,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _repository.deleteReminder(reminderId);
        
        if (!mounted) return;
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Reminder removed'),
            backgroundColor: HealthRecordsDesignSystem.successGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(HealthRecordsDesignSystem.radiusMedium),
            ),
          ),
        );
        await _loadRecordDetails();
      } catch (e) {
        if (!mounted) return;
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to remove reminder: $e'),
            backgroundColor: HealthRecordsDesignSystem.errorRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(HealthRecordsDesignSystem.radiusMedium),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HealthRecordsDesignSystem.backgroundColor,
      body: _isLoading ? _buildLoadingState() : _error != null ? _buildErrorState() : _buildContent(),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(HealthRecordsDesignSystem.tealAccent),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 64,
            color: HealthRecordsDesignSystem.errorRed,
          ),
          const SizedBox(height: HealthRecordsDesignSystem.spacing16),
          Text(
            _error ?? 'An error occurred',
            style: HealthRecordsDesignSystem.textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: HealthRecordsDesignSystem.spacing24),
          ElevatedButton.icon(
            onPressed: _loadRecordDetails,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: HealthRecordsDesignSystem.tealAccent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: HealthRecordsDesignSystem.spacing24,
                vertical: HealthRecordsDesignSystem.spacing12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(HealthRecordsDesignSystem.radiusMedium),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_record == null) return const SizedBox.shrink();

    return CustomScrollView(
      slivers: [
        _buildAppBar(),
        SliverPadding(
          padding: const EdgeInsets.all(HealthRecordsDesignSystem.spacing16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _buildMainInfoCard(),
              const SizedBox(height: HealthRecordsDesignSystem.spacing16),
              _buildSubjectInfoCard(),
              const SizedBox(height: HealthRecordsDesignSystem.spacing16),
              _buildDetailsCard(),
              if (_record!.medications.isNotEmpty) ...[
                const SizedBox(height: HealthRecordsDesignSystem.spacing16),
                _buildMedicationsCard(),
              ],
              if (_record!.notes != null && _record!.notes!.isNotEmpty) ...[
                const SizedBox(height: HealthRecordsDesignSystem.spacing16),
                _buildNotesCard(),
              ],
              const SizedBox(height: HealthRecordsDesignSystem.spacing16),
              _buildCreatorCard(),
              if (_record!.assignedUserIds.isNotEmpty) ...[
                const SizedBox(height: HealthRecordsDesignSystem.spacing16),
                _buildAssignedUsersCard(),
              ],
              if (_reminders.isNotEmpty) ...[
                const SizedBox(height: HealthRecordsDesignSystem.spacing16),
                _buildRemindersCard(),
              ],
              const SizedBox(height: HealthRecordsDesignSystem.spacing32),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 180,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: HealthRecordsDesignSystem.surfaceColor,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded, color: HealthRecordsDesignSystem.textPrimary),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(
          left: HealthRecordsDesignSystem.spacing48,
          bottom: HealthRecordsDesignSystem.spacing16,
        ),
        title: Text(
          _record!.title,
          style: HealthRecordsDesignSystem.textTheme.titleLarge?.copyWith(
            color: HealthRecordsDesignSystem.textPrimary,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                HealthRecordsDesignSystem.deepCobalt.withOpacity(0.05),
                HealthRecordsDesignSystem.tealAccent.withOpacity(0.05),
                HealthRecordsDesignSystem.surfaceColor,
              ],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -30,
                top: 40,
                child: Icon(
                  _getRecordTypeIcon(_record!.recordType),
                  size: 120,
                  color: HealthRecordsDesignSystem.tealAccent.withOpacity(0.08),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainInfoCard() {
    return Container(
      decoration: BoxDecoration(
        color: HealthRecordsDesignSystem.surfaceColor,
        borderRadius: BorderRadius.circular(HealthRecordsDesignSystem.radiusLarge),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(HealthRecordsDesignSystem.spacing20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(HealthRecordsDesignSystem.spacing12),
                decoration: BoxDecoration(
                  color: HealthRecordsDesignSystem.tealAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(HealthRecordsDesignSystem.radiusMedium),
                ),
                child: Icon(
                  _getRecordTypeIcon(_record!.recordType),
                  color: HealthRecordsDesignSystem.tealAccent,
                  size: 28,
                ),
              ),
              const SizedBox(width: HealthRecordsDesignSystem.spacing12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatRecordType(_record!.recordType),
                      style: HealthRecordsDesignSystem.textTheme.labelMedium?.copyWith(
                        color: HealthRecordsDesignSystem.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('MMMM d, yyyy').format(_record!.recordDate),
                      style: HealthRecordsDesignSystem.textTheme.bodyMedium?.copyWith(
                        color: HealthRecordsDesignSystem.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (_record!.severity != null)
                _buildSeverityBadge(_record!.severity!),
            ],
          ),
          if (_record!.description != null && _record!.description!.isNotEmpty) ...[
            const SizedBox(height: HealthRecordsDesignSystem.spacing16),
            Text(
              _record!.description!,
              style: HealthRecordsDesignSystem.textTheme.bodyMedium?.copyWith(
                color: HealthRecordsDesignSystem.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSubjectInfoCard() {
    return Container(
      decoration: BoxDecoration(
        color: HealthRecordsDesignSystem.surfaceColor,
        borderRadius: BorderRadius.circular(HealthRecordsDesignSystem.radiusLarge),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(HealthRecordsDesignSystem.spacing20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.person_outline_rounded,
                color: HealthRecordsDesignSystem.tealAccent,
                size: 20,
              ),
              const SizedBox(width: HealthRecordsDesignSystem.spacing8),
              Text(
                'Subject Information',
                style: HealthRecordsDesignSystem.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: HealthRecordsDesignSystem.spacing16),
          _buildInfoRow(
            'Subject Type',
            _formatSubjectType(_record!.subjectType),
            Icons.category_outlined,
          ),
          if (_record!.subjectName != null && _record!.subjectName!.isNotEmpty)
            _buildInfoRow(
              'Subject Name',
              _record!.subjectName!,
              Icons.badge_outlined,
            ),
        ],
      ),
    );
  }

  Widget _buildDetailsCard() {
    return Container(
      decoration: BoxDecoration(
        color: HealthRecordsDesignSystem.surfaceColor,
        borderRadius: BorderRadius.circular(HealthRecordsDesignSystem.radiusLarge),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(HealthRecordsDesignSystem.spacing20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.medical_information_outlined,
                color: HealthRecordsDesignSystem.tealAccent,
                size: 20,
              ),
              const SizedBox(width: HealthRecordsDesignSystem.spacing8),
              Text(
                'Medical Details',
                style: HealthRecordsDesignSystem.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: HealthRecordsDesignSystem.spacing16),
          if (_record!.provider != null && _record!.provider!.isNotEmpty)
            _buildInfoRow(
              'Healthcare Provider',
              _record!.provider!,
              Icons.local_hospital_outlined,
            ),
          if (_record!.location != null && _record!.location!.isNotEmpty)
            _buildInfoRow(
              'Location',
              _record!.location!,
              Icons.location_on_outlined,
            ),
          if (_record!.diagnosis != null && _record!.diagnosis!.isNotEmpty)
            _buildInfoRow(
              'Diagnosis',
              _record!.diagnosis!,
              Icons.assignment_outlined,
            ),
          if (_record!.treatment != null && _record!.treatment!.isNotEmpty)
            _buildInfoRow(
              'Treatment',
              _record!.treatment!,
              Icons.healing_outlined,
            ),
        ],
      ),
    );
  }

  Widget _buildMedicationsCard() {
    return Container(
      decoration: BoxDecoration(
        color: HealthRecordsDesignSystem.surfaceColor,
        borderRadius: BorderRadius.circular(HealthRecordsDesignSystem.radiusLarge),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(HealthRecordsDesignSystem.spacing20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.medication_outlined,
                color: HealthRecordsDesignSystem.tealAccent,
                size: 20,
              ),
              const SizedBox(width: HealthRecordsDesignSystem.spacing8),
              Text(
                'Medications',
                style: HealthRecordsDesignSystem.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: HealthRecordsDesignSystem.spacing12),
          ..._record!.medications.map((medication) => Padding(
                padding: const EdgeInsets.only(bottom: HealthRecordsDesignSystem.spacing8),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: HealthRecordsDesignSystem.tealAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: HealthRecordsDesignSystem.spacing12),
                    Expanded(
                      child: Text(
                        medication,
                        style: HealthRecordsDesignSystem.textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildNotesCard() {
    return Container(
      decoration: BoxDecoration(
        color: HealthRecordsDesignSystem.surfaceColor,
        borderRadius: BorderRadius.circular(HealthRecordsDesignSystem.radiusLarge),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(HealthRecordsDesignSystem.spacing20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.notes_outlined,
                color: HealthRecordsDesignSystem.tealAccent,
                size: 20,
              ),
              const SizedBox(width: HealthRecordsDesignSystem.spacing8),
              Text(
                'Additional Notes',
                style: HealthRecordsDesignSystem.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: HealthRecordsDesignSystem.spacing12),
          Text(
            _record!.notes!,
            style: HealthRecordsDesignSystem.textTheme.bodyMedium?.copyWith(
              color: HealthRecordsDesignSystem.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreatorCard() {
    return Container(
      decoration: BoxDecoration(
        color: HealthRecordsDesignSystem.surfaceColor,
        borderRadius: BorderRadius.circular(HealthRecordsDesignSystem.radiusLarge),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(HealthRecordsDesignSystem.spacing20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.person_add_outlined,
                color: HealthRecordsDesignSystem.tealAccent,
                size: 20,
              ),
              const SizedBox(width: HealthRecordsDesignSystem.spacing8),
              Text(
                'Record Information',
                style: HealthRecordsDesignSystem.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: HealthRecordsDesignSystem.spacing16),
          _buildInfoRow(
            'Created By',
            _record!.createdByName ?? 'Unknown',
            Icons.person_outline,
          ),
          _buildInfoRow(
            'Created At',
            DateFormat('MMM d, yyyy \'at\' h:mm a').format(_record!.createdAt),
            Icons.access_time_outlined,
          ),
        ],
      ),
    );
  }

  Widget _buildAssignedUsersCard() {
    return Container(
      decoration: BoxDecoration(
        color: HealthRecordsDesignSystem.surfaceColor,
        borderRadius: BorderRadius.circular(HealthRecordsDesignSystem.radiusLarge),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(HealthRecordsDesignSystem.spacing20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.people_outline_rounded,
                color: HealthRecordsDesignSystem.tealAccent,
                size: 20,
              ),
              const SizedBox(width: HealthRecordsDesignSystem.spacing8),
              Text(
                'Assigned Users',
                style: HealthRecordsDesignSystem.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: HealthRecordsDesignSystem.spacing12),
          Text(
            '${_record!.assignedUserIds.length} user(s) assigned',
            style: HealthRecordsDesignSystem.textTheme.bodyMedium?.copyWith(
              color: HealthRecordsDesignSystem.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRemindersCard() {
    return Container(
      decoration: BoxDecoration(
        color: HealthRecordsDesignSystem.surfaceColor,
        borderRadius: BorderRadius.circular(HealthRecordsDesignSystem.radiusLarge),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(HealthRecordsDesignSystem.spacing20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.notifications_outlined,
                color: HealthRecordsDesignSystem.tealAccent,
                size: 20,
              ),
              const SizedBox(width: HealthRecordsDesignSystem.spacing8),
              Text(
                'Reminders',
                style: HealthRecordsDesignSystem.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: HealthRecordsDesignSystem.spacing12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: HealthRecordsDesignSystem.tealAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(HealthRecordsDesignSystem.radiusSmall),
                ),
                child: Text(
                  '${_reminders.length}',
                  style: HealthRecordsDesignSystem.textTheme.labelSmall?.copyWith(
                    color: HealthRecordsDesignSystem.tealAccent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: HealthRecordsDesignSystem.spacing16),
          ..._reminders.map((reminder) => _buildReminderItem(reminder)),
        ],
      ),
    );
  }

  Widget _buildReminderItem(HealthRecordReminder reminder) {
    final isOverdue = reminder.dueAt.isBefore(DateTime.now());
    final statusColor = reminder.status == 'completed'
        ? HealthRecordsDesignSystem.successGreen
        : isOverdue
            ? HealthRecordsDesignSystem.errorRed
            : HealthRecordsDesignSystem.tealAccent;

    return Container(
      margin: const EdgeInsets.only(bottom: HealthRecordsDesignSystem.spacing12),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(HealthRecordsDesignSystem.radiusMedium),
        border: Border.all(
          color: statusColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(HealthRecordsDesignSystem.spacing16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reminder.title,
                      style: HealthRecordsDesignSystem.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('MMM d, yyyy \'at\' h:mm a').format(reminder.dueAt),
                      style: HealthRecordsDesignSystem.textTheme.bodySmall?.copyWith(
                        color: HealthRecordsDesignSystem.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: HealthRecordsDesignSystem.spacing12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(HealthRecordsDesignSystem.radiusSmall),
                ),
                child: Text(
                  _formatReminderStatus(reminder.status),
                  style: HealthRecordsDesignSystem.textTheme.labelSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (reminder.description != null && reminder.description!.isNotEmpty) ...[
            const SizedBox(height: HealthRecordsDesignSystem.spacing8),
            Text(
              reminder.description!,
              style: HealthRecordsDesignSystem.textTheme.bodyMedium?.copyWith(
                color: HealthRecordsDesignSystem.textSecondary,
              ),
            ),
          ],
          if (reminder.status != 'completed') ...[
            const SizedBox(height: HealthRecordsDesignSystem.spacing12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _handleSkipReminder(reminder.id),
                    icon: const Icon(Icons.check_circle_outline, size: 18),
                    label: const Text('Skip'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: HealthRecordsDesignSystem.successGreen,
                      side: BorderSide(color: HealthRecordsDesignSystem.successGreen),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(HealthRecordsDesignSystem.radiusMedium),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: HealthRecordsDesignSystem.spacing8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _handleRemoveReminder(reminder.id),
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('Remove'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: HealthRecordsDesignSystem.errorRed,
                      side: BorderSide(color: HealthRecordsDesignSystem.errorRed),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(HealthRecordsDesignSystem.radiusMedium),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: HealthRecordsDesignSystem.spacing12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 18,
            color: HealthRecordsDesignSystem.textSecondary,
          ),
          const SizedBox(width: HealthRecordsDesignSystem.spacing12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: HealthRecordsDesignSystem.textTheme.labelSmall?.copyWith(
                    color: HealthRecordsDesignSystem.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: HealthRecordsDesignSystem.textTheme.bodyMedium?.copyWith(
                    color: HealthRecordsDesignSystem.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeverityBadge(String severity) {
    Color color;
    String label;
    switch (severity.toLowerCase()) {
      case 'critical':
        color = HealthRecordsDesignSystem.errorRed;
        label = 'Critical';
        break;
      case 'high':
        color = Colors.orange;
        label = 'High';
        break;
      case 'moderate':
        color = Colors.amber;
        label = 'Moderate';
        break;
      case 'low':
        color = HealthRecordsDesignSystem.successGreen;
        label = 'Low';
        break;
      default:
        color = HealthRecordsDesignSystem.textSecondary;
        label = severity;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: HealthRecordsDesignSystem.spacing12,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(HealthRecordsDesignSystem.radiusSmall),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Text(
        label,
        style: HealthRecordsDesignSystem.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  IconData _getRecordTypeIcon(String recordType) {
    switch (recordType.toLowerCase()) {
      case 'medical':
        return Icons.medical_services_rounded;
      case 'vaccination':
        return Icons.vaccines_rounded;
      case 'allergy':
        return Icons.warning_amber_rounded;
      case 'medication':
        return Icons.medication_rounded;
      case 'condition':
        return Icons.health_and_safety_rounded;
      case 'procedure':
        return Icons.healing_rounded;
      case 'lab_result':
        return Icons.science_rounded;
      case 'appointment':
        return Icons.event_rounded;
      default:
        return Icons.description_rounded;
    }
  }

  String _formatRecordType(String recordType) {
    return recordType.replaceAll('_', ' ').split(' ').map((word) => word[0].toUpperCase() + word.substring(1)).join(' ');
  }

  String _formatSubjectType(String subjectType) {
    switch (subjectType.toLowerCase()) {
      case 'self':
        return 'Myself';
      case 'family':
        return 'Family Member';
      case 'friend':
        return 'Friend';
      default:
        return subjectType;
    }
  }

  String _formatReminderStatus(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Pending';
      case 'completed':
        return 'Completed';
      case 'snoozed':
        return 'Snoozed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }
}
