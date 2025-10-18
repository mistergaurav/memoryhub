class FamilyCalendarEvent {
  final String id;
  final String title;
  final String? description;
  final DateTime startDate;
  final DateTime? endDate;
  final bool isAllDay;
  final String? location;
  final String eventType;
  final String? recurrenceRule;
  final List<String> familyCircleIds;
  final List<String> attendeeIds;
  final String? reminder;
  final String createdBy;
  final String? createdByName;
  final DateTime createdAt;
  final DateTime updatedAt;

  FamilyCalendarEvent({
    required this.id,
    required this.title,
    this.description,
    required this.startDate,
    this.endDate,
    required this.isAllDay,
    this.location,
    required this.eventType,
    this.recurrenceRule,
    required this.familyCircleIds,
    required this.attendeeIds,
    this.reminder,
    required this.createdBy,
    this.createdByName,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FamilyCalendarEvent.fromJson(Map<String, dynamic> json) {
    return FamilyCalendarEvent(
      id: json['id'] ?? json['_id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      startDate: DateTime.parse(json['start_date'] ?? DateTime.now().toIso8601String()),
      endDate: json['end_date'] != null
          ? DateTime.parse(json['end_date'])
          : null,
      isAllDay: json['is_all_day'] ?? false,
      location: json['location'],
      eventType: json['event_type'] ?? 'general',
      recurrenceRule: json['recurrence_rule'],
      familyCircleIds: List<String>.from(json['family_circle_ids'] ?? []),
      attendeeIds: List<String>.from(json['attendee_ids'] ?? []),
      reminder: json['reminder'],
      createdBy: json['created_by'] ?? '',
      createdByName: json['created_by_name'],
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
    );
  }
}
