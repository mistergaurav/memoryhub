class GenealogyTreeNode {
  final String id;
  final String personId;
  final String firstName;
  final String lastName;
  final String? middleName;
  final String gender;
  final int generation;
  final int position;
  final String? photoUrl;
  final List<String> parentIds;
  final List<String> childrenIds;
  final List<String> spouseIds;
  final DateTime? birthDate;
  final DateTime? deathDate;
  final String? relationshipToRoot;
  final DateTime createdAt;
  final DateTime updatedAt;

  GenealogyTreeNode({
    required this.id,
    required this.personId,
    required this.firstName,
    required this.lastName,
    this.middleName,
    required this.gender,
    required this.generation,
    required this.position,
    this.photoUrl,
    this.parentIds = const [],
    this.childrenIds = const [],
    this.spouseIds = const [],
    this.birthDate,
    this.deathDate,
    this.relationshipToRoot,
    required this.createdAt,
    required this.updatedAt,
  });

  String get fullName {
    final parts = [firstName, middleName, lastName].where((part) => part != null && part.isNotEmpty);
    return parts.join(' ');
  }

  factory GenealogyTreeNode.fromJson(Map<String, dynamic> json) {
    return GenealogyTreeNode(
      id: json['id'] ?? json['_id'] ?? '',
      personId: json['person_id'] ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      middleName: json['middle_name'],
      gender: json['gender'] ?? 'unknown',
      generation: json['generation'] ?? 0,
      position: json['position'] ?? 0,
      photoUrl: json['photo_url'],
      parentIds: List<String>.from(json['parent_ids'] ?? []),
      childrenIds: List<String>.from(json['children_ids'] ?? []),
      spouseIds: List<String>.from(json['spouse_ids'] ?? []),
      birthDate: json['birth_date'] != null 
          ? DateTime.parse(json['birth_date']) 
          : null,
      deathDate: json['death_date'] != null 
          ? DateTime.parse(json['death_date']) 
          : null,
      relationshipToRoot: json['relationship_to_root'],
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'person_id': personId,
      'first_name': firstName,
      'last_name': lastName,
      'middle_name': middleName,
      'gender': gender,
      'generation': generation,
      'position': position,
      'photo_url': photoUrl,
      'parent_ids': parentIds,
      'children_ids': childrenIds,
      'spouse_ids': spouseIds,
      'birth_date': birthDate?.toIso8601String(),
      'death_date': deathDate?.toIso8601String(),
      'relationship_to_root': relationshipToRoot,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
