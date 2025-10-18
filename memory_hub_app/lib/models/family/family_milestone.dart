class FamilyMilestone {
  final String id;
  final String title;
  final String? description;
  final String category;
  final DateTime milestoneDate;
  final String? photoUrl;
  final String createdBy;
  final String? createdByName;
  final List<String> familyMemberIds;
  final Map<String, dynamic>? celebrationDetails;
  final int likesCount;
  final int commentsCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  FamilyMilestone({
    required this.id,
    required this.title,
    this.description,
    required this.category,
    required this.milestoneDate,
    this.photoUrl,
    required this.createdBy,
    this.createdByName,
    required this.familyMemberIds,
    this.celebrationDetails,
    required this.likesCount,
    required this.commentsCount,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FamilyMilestone.fromJson(Map<String, dynamic> json) {
    return FamilyMilestone(
      id: json['id'] ?? json['_id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      category: json['category'] ?? 'general',
      milestoneDate: DateTime.parse(json['milestone_date'] ?? DateTime.now().toIso8601String()),
      photoUrl: json['photo_url'],
      createdBy: json['created_by'] ?? '',
      createdByName: json['created_by_name'],
      familyMemberIds: List<String>.from(json['family_member_ids'] ?? []),
      celebrationDetails: json['celebration_details'],
      likesCount: json['likes_count'] ?? 0,
      commentsCount: json['comments_count'] ?? 0,
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
    );
  }
}
