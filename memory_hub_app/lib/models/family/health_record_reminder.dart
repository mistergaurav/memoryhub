class HealthRecordReminder {
  final String id;
  final String recordId;
  final String? recordTitle;
  final String assignedUserId;
  final String? assignedUserName;
  final String reminderType;
  final String title;
  final String? description;
  final DateTime dueAt;
  final String repeatFrequency;
  final int? repeatCount;
  final List<String> deliveryChannels;
  final String status;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;

  HealthRecordReminder({
    required this.id,
    required this.recordId,
    this.recordTitle,
    required this.assignedUserId,
    this.assignedUserName,
    required this.reminderType,
    required this.title,
    this.description,
    required this.dueAt,
    required this.repeatFrequency,
    this.repeatCount,
    required this.deliveryChannels,
    required this.status,
    required this.metadata,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
  });

  factory HealthRecordReminder.fromJson(Map<String, dynamic> json) {
    return HealthRecordReminder(
      id: json['id'] ?? json['_id'] ?? '',
      recordId: json['record_id'] ?? '',
      recordTitle: json['record_title'],
      assignedUserId: json['assigned_user_id'] ?? '',
      assignedUserName: json['assigned_user_name'],
      reminderType: json['reminder_type'] ?? 'custom',
      title: json['title'] ?? '',
      description: json['description'],
      dueAt: DateTime.parse(json['due_at'] ?? DateTime.now().toIso8601String()),
      repeatFrequency: json['repeat_frequency'] ?? 'once',
      repeatCount: json['repeat_count'],
      deliveryChannels: List<String>.from(json['delivery_channels'] ?? ['in_app']),
      status: json['status'] ?? 'pending',
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
      createdBy: json['created_by'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'record_id': recordId,
      'record_title': recordTitle,
      'assigned_user_id': assignedUserId,
      'assigned_user_name': assignedUserName,
      'reminder_type': reminderType,
      'title': title,
      'description': description,
      'due_at': dueAt.toIso8601String(),
      'repeat_frequency': repeatFrequency,
      'repeat_count': repeatCount,
      'delivery_channels': deliveryChannels,
      'status': status,
      'metadata': metadata,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'created_by': createdBy,
    };
  }
}
