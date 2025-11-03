class GenealogyRelationship {
  final String id;
  final String familyId;
  final String person1Id;
  final String person2Id;
  final String relationshipType;
  final String? notes;
  final DateTime createdAt;
  final String createdBy;

  GenealogyRelationship({
    required this.id,
    required this.familyId,
    required this.person1Id,
    required this.person2Id,
    required this.relationshipType,
    this.notes,
    required this.createdAt,
    required this.createdBy,
  });

  factory GenealogyRelationship.fromJson(Map<String, dynamic> json) {
    return GenealogyRelationship(
      id: json['id'] ?? json['_id'] ?? '',
      familyId: json['family_id'] ?? '',
      person1Id: json['person1_id'] ?? '',
      person2Id: json['person2_id'] ?? '',
      relationshipType: json['relationship_type'] ?? '',
      notes: json['notes'],
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      createdBy: json['created_by'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'family_id': familyId,
      'person1_id': person1Id,
      'person2_id': person2Id,
      'relationship_type': relationshipType,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'created_by': createdBy,
    };
  }
}
