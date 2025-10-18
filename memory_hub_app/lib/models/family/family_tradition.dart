class FamilyTradition {
  final String id;
  final String title;
  final String? description;
  final String category;
  final String? culturalOrigin;
  final String frequency;
  final DateTime? nextOccurrence;
  final String? photoUrl;
  final List<String> participants;
  final Map<String, dynamic>? customDetails;
  final String createdBy;
  final String? createdByName;
  final List<String> familyCircleIds;
  final DateTime createdAt;
  final DateTime updatedAt;

  FamilyTradition({
    required this.id,
    required this.title,
    this.description,
    required this.category,
    this.culturalOrigin,
    required this.frequency,
    this.nextOccurrence,
    this.photoUrl,
    required this.participants,
    this.customDetails,
    required this.createdBy,
    this.createdByName,
    required this.familyCircleIds,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FamilyTradition.fromJson(Map<String, dynamic> json) {
    return FamilyTradition(
      id: json['id'] ?? json['_id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      category: json['category'] ?? 'general',
      culturalOrigin: json['cultural_origin'],
      frequency: json['frequency'] ?? 'yearly',
      nextOccurrence: json['next_occurrence'] != null
          ? DateTime.parse(json['next_occurrence'])
          : null,
      photoUrl: json['photo_url'],
      participants: List<String>.from(json['participants'] ?? []),
      customDetails: json['custom_details'],
      createdBy: json['created_by'] ?? '',
      createdByName: json['created_by_name'],
      familyCircleIds: List<String>.from(json['family_circle_ids'] ?? []),
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
    );
  }
}
