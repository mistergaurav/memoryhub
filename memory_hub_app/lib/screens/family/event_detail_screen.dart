import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../models/family/family_calendar.dart';
import '../../services/family/family_service.dart';
import '../../dialogs/family/add_event_dialog.dart';
import '../../design_system/design_tokens.dart';
import 'package:memory_hub_app/design_system/design_system.dart';

class EventDetailScreen extends StatefulWidget {
  final String eventId;
  final FamilyCalendarEvent? initialEvent;

  const EventDetailScreen({
    Key? key,
    required this.eventId,
    this.initialEvent,
  }) : super(key: key);

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  final FamilyService _familyService = FamilyService();
  FamilyCalendarEvent? _event;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.initialEvent != null) {
      _event = widget.initialEvent;
    } else {
      _loadEvent();
    }
  }

  Future<void> _loadEvent() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final event = await _familyService.getCalendarEvent(widget.eventId);
      setState(() {
        _event = event;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteEvent() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Event'),
        content: const Text('Are you sure you want to delete this event?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            label: 'Cancel',
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            label: 'Delete',
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await _familyService.deleteCalendarEvent(widget.eventId);
        if (mounted) {
          Navigator.pop(context, true);
          AppSnackbar.success(context, 'Event deleted successfully',
          );
        }
      } catch (e) {
        if (mounted) {
          AppSnackbar.error(context, 'Failed to delete event: $e',
          );
        }
      }
    }
  }

  void _showEditDialog() {
    if (_event == null) return;

    showDialog(
      context: context,
      builder: (context) => AddEventDialog(
        initialData: {
          'title': _event!.title,
          'description': _event!.description ?? '',
          'event_type': _event!.eventType,
          'event_date': _event!.startDate.toIso8601String(),
          'end_date': _event!.endDate?.toIso8601String(),
          'location': _event!.location ?? '',
          'recurrence': _event!.recurrenceRule ?? 'none',
          'reminder_minutes': _event!.reminder,
        },
        onSubmit: (data) => _handleUpdateEvent(data),
      ),
    );
  }

  Future<void> _handleUpdateEvent(Map<String, dynamic> data) async {
    try {
      final result = await _familyService.updateCalendarEvent(widget.eventId, data);
      if (mounted) {
        final conflicts = result['conflicts'] ?? 0;
        final warning = result['conflict_warning'];
        
        if (conflicts > 0 && warning != null) {
          AppSnackbar.info(context, warning);
        } else {
          AppSnackbar.success(context, 'Event updated successfully');
        }
        _loadEvent();
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.error(context, 'Failed to update event: ${e.toString().replaceAll('Exception: ', '')}',
        );
      }
    }
  }

  void _shareEvent() {
    if (_event == null) return;
    
    final eventDetails = '''
${_event!.title}
${_event!.description ?? ''}

📅 ${DateFormat('EEEE, MMMM d, yyyy').format(_event!.startDate)}
🕐 ${_event!.isAllDay ? 'All Day' : DateFormat('h:mm a').format(_event!.startDate)}
${_event!.location != null ? '📍 ${_event!.location}' : ''}
''';

    Clipboard.setData(ClipboardData(text: eventDetails));
    AppSnackbar.success(context, 'Event details copied to clipboard',
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Event Details'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _event == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Event Details'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
              const VGap.lg(),
              Text(
                _error ?? 'Event not found',
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const VGap.xl(),
              PrimaryButton(
                onPressed: _loadEvent,
                label: 'Retry',
                icon: Icons.refresh,
              ),
            ],
          ),
        ),
      );
    }

    final event = _event!;
    final gradient = _getEventGradient(event.eventType);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                event.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(color: Colors.black26, blurRadius: 2),
                  ],
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: gradient,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -30,
                      bottom: -30,
                      child: Icon(
                        _getEventIcon(event.eventType),
                        size: 140,
                        color: Colors.white.withOpacity(0.2),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.share),
                onPressed: _shareEvent,
                tooltip: 'Share event',
              ),
              if (!event.autoGenerated)
                PopupMenuButton(
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 20),
                          HGap.sm(),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 20, color: Colors.red),
                          HGap.sm(),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) {
                    if (value == 'edit') {
                      _showEditDialog();
                    } else if (value == 'delete') {
                      _deleteEvent();
                    }
                  },
                ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padded.all(
              Spacing.lg,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (event.autoGenerated) ...[
                    Container(
                      padding: Spacing.edgeInsetsSymmetric(
                        horizontal: Spacing.md,
                        vertical: Spacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.auto_awesome, 
                            size: 16, 
                            color: Colors.blue.shade700,
                          ),
                          const HGap.xs(),
                          Text(
                            'Auto-generated from Family Tree',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const VGap.lg(),
                  ],
                  _buildInfoCard(
                    icon: Icons.calendar_today,
                    title: 'Date & Time',
                    children: [
                      _buildInfoRow(
                        'Start',
                        event.isAllDay
                            ? DateFormat('EEEE, MMMM d, yyyy').format(event.startDate)
                            : DateFormat('EEEE, MMMM d, yyyy h:mm a').format(event.startDate),
                      ),
                      if (event.endDate != null) ...[
                        const VGap.sm(),
                        _buildInfoRow(
                          'End',
                          event.isAllDay
                              ? DateFormat('EEEE, MMMM d, yyyy').format(event.endDate!)
                              : DateFormat('EEEE, MMMM d, yyyy h:mm a').format(event.endDate!),
                        ),
                      ],
                      if (event.recurrenceRule != null && event.recurrenceRule != 'none') ...[
                        const VGap.sm(),
                        _buildInfoRow(
                          'Repeats',
                          _formatRecurrence(event.recurrenceRule!),
                        ),
                      ],
                    ],
                  ),
                  const VGap.lg(),
                  if (event.description != null && event.description!.isNotEmpty) ...[
                    _buildInfoCard(
                      icon: Icons.description,
                      title: 'Description',
                      children: [
                        Text(
                          event.description!,
                          style: const TextStyle(fontSize: 15, height: 1.5),
                        ),
                      ],
                    ),
                    const VGap.lg(),
                  ],
                  if (event.location != null && event.location!.isNotEmpty) ...[
                    _buildInfoCard(
                      icon: Icons.location_on,
                      title: 'Location',
                      children: [
                        Text(
                          event.location!,
                          style: const TextStyle(fontSize: 15),
                        ),
                      ],
                    ),
                    const VGap.lg(),
                  ],
                  _buildInfoCard(
                    icon: Icons.category,
                    title: 'Event Type',
                    children: [
                      Container(
                        padding: Spacing.edgeInsetsSymmetric(
                          horizontal: Spacing.md,
                          vertical: Spacing.xs,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: gradient),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _formatEventType(event.eventType),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const VGap.lg(),
                  if (event.reminder != null) ...[
                    _buildInfoCard(
                      icon: Icons.notifications_active,
                      title: 'Reminder',
                      children: [
                        Text(
                          _formatReminder(event.reminder!),
                          style: const TextStyle(fontSize: 15),
                        ),
                      ],
                    ),
                    const VGap.lg(),
                  ],
                  if (event.genealogyPersonName != null) ...[
                    _buildInfoCard(
                      icon: Icons.family_restroom,
                      title: 'Related Person',
                      children: [
                        Text(
                          event.genealogyPersonName!,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const VGap.lg(),
                  ],
                  if (event.attendeeIds.isNotEmpty) ...[
                    _buildInfoCard(
                      icon: Icons.people,
                      title: 'Attendees',
                      children: [
                        Text(
                          '${event.attendeeIds.length} ${event.attendeeIds.length == 1 ? 'person' : 'people'}',
                          style: const TextStyle(fontSize: 15),
                        ),
                      ],
                    ),
                    const VGap.lg(),
                  ],
                  _buildInfoCard(
                    icon: Icons.info_outline,
                    title: 'Details',
                    children: [
                      _buildInfoRow(
                        'Created by',
                        event.createdByName ?? 'Unknown',
                      ),
                      const VGap.sm(),
                      _buildInfoRow(
                        'Created',
                        DateFormat('MMM d, yyyy h:mm a').format(event.createdAt),
                      ),
                      if (event.createdAt != event.updatedAt) ...[
                        const VGap.sm(),
                        _buildInfoRow(
                          'Last updated',
                          DateFormat('MMM d, yyyy h:mm a').format(event.updatedAt),
                        ),
                      ],
                    ],
                  ),
                  const VGap(80),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padded.all(
        Spacing.lg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: Spacing.edgeInsetsAll(Spacing.sm),
                  decoration: BoxDecoration(
                    color: DesignTokens.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: DesignTokens.primaryColor, size: 20),
                ),
                const HGap.md(),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const VGap.md(),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 15),
          ),
        ),
      ],
    );
  }

  List<Color> _getEventGradient(String eventType) {
    switch (eventType) {
      case 'birthday':
        return [const Color(0xFFEC4899), const Color(0xFFF472B6)];
      case 'death_anniversary':
        return [const Color(0xFF6B7280), const Color(0xFF9CA3AF)];
      case 'anniversary':
        return [const Color(0xFFDB2777), const Color(0xFFEC4899)];
      case 'meeting':
      case 'gathering':
        return [const Color(0xFF7C3AED), const Color(0xFF9333EA)];
      case 'holiday':
        return [const Color(0xFFF59E0B), const Color(0xFFFBF24)];
      case 'historical_event':
        return [const Color(0xFF92400E), const Color(0xFFA16207)];
      case 'reminder':
        return [const Color(0xFF10B981), const Color(0xFF34D399)];
      default:
        return [const Color(0xFF06B6D4), const Color(0xFF22D3EE)];
    }
  }

  IconData _getEventIcon(String eventType) {
    switch (eventType) {
      case 'birthday':
        return Icons.cake;
      case 'anniversary':
      case 'death_anniversary':
        return Icons.favorite;
      case 'meeting':
      case 'gathering':
        return Icons.groups;
      case 'holiday':
        return Icons.celebration;
      case 'reminder':
        return Icons.notifications;
      default:
        return Icons.event;
    }
  }

  String _formatEventType(String eventType) {
    switch (eventType) {
      case 'birthday':
        return 'Birthday';
      case 'anniversary':
        return 'Anniversary';
      case 'death_anniversary':
        return 'Death Anniversary';
      case 'gathering':
        return 'Family Gathering';
      case 'holiday':
        return 'Holiday';
      case 'reminder':
        return 'Reminder';
      case 'historical_event':
        return 'Historical Event';
      default:
        return 'Other';
    }
  }

  String _formatRecurrence(String recurrence) {
    switch (recurrence) {
      case 'daily':
        return 'Every day';
      case 'weekly':
        return 'Every week';
      case 'monthly':
        return 'Every month';
      case 'yearly':
        return 'Every year';
      default:
        return 'Does not repeat';
    }
  }

  String _formatReminder(String reminder) {
    if (reminder.isEmpty) return 'No reminder';
    
    try {
      final minutes = int.parse(reminder);
      if (minutes == 0) return 'At time of event';
      if (minutes == 15) return '15 minutes before';
      if (minutes == 30) return '30 minutes before';
      if (minutes == 60) return '1 hour before';
      if (minutes == 1440) return '1 day before';
      if (minutes == 10080) return '1 week before';
      return '$minutes minutes before';
    } catch (e) {
      return reminder;
    }
  }
}
