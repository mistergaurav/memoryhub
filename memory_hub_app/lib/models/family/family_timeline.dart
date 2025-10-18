class TimelineEvent {
  final String id;
  final String title;
  final String? description;
  final DateTime eventDate;
  final String eventType;
  final String? photoUrl;
  final String createdBy;
  final String? createdByName;
  final List<String> familyCircleIds;
  final List<String> taggedMembers;
  final int likesCount;
  final int commentsCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  TimelineEvent({
    required this.id,
    required this.title,
    this.description,
    required this.eventDate,
    required this.eventType,
    this.photoUrl,
    required this.createdBy,
    this.createdByName,
    required this.familyCircleIds,
    required this.taggedMembers,
    required this.likesCount,
    required this.commentsCount,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TimelineEvent.fromJson(Map<String, dynamic> json) {
    return TimelineEvent(
      id: json['id'] ?? json['_id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      eventDate: DateTime.parse(json['event_date'] ?? DateTime.now().toIso8601String()),
      eventType: json['event_type'] ?? 'general',
      photoUrl: json['photo_url'],
      createdBy: json['created_by'] ?? '',
      createdByName: json['created_by_name'],
      familyCircleIds: List<String>.from(json['family_circle_ids'] ?? []),
      taggedMembers: List<String>.from(json['tagged_members'] ?? []),
      likesCount: json['likes_count'] ?? 0,
      commentsCount: json['comments_count'] ?? 0,
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
    );
  }
}
