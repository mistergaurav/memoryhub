class GenealogyPerson {
  final String id;
  final String firstName;
  final String? middleName;
  final String lastName;
  final String? maidenName;
  final String gender;
  final DateTime? dateOfBirth;
  final String? placeOfBirth;
  final DateTime? dateOfDeath;
  final String? placeOfDeath;
  final bool isDeceased;
  final String? biography;
  final String? photoUrl;
  final int generation;
  final String? occupation;
  final List<String> familyCircleIds;
  final String createdBy;
  final String? createdByName;
  
  // New health summary fields
  final int? age;
  final int? lifespan;
  final int healthRecordsCount;
  final List<String> hereditaryConditions;
  
  final DateTime createdAt;
  final DateTime updatedAt;

  GenealogyPerson({
    required this.id,
    required this.firstName,
    this.middleName,
    required this.lastName,
    this.maidenName,
    required this.gender,
    this.dateOfBirth,
    this.placeOfBirth,
    this.dateOfDeath,
    this.placeOfDeath,
    required this.isDeceased,
    this.biography,
    this.photoUrl,
    required this.generation,
    this.occupation,
    required this.familyCircleIds,
    required this.createdBy,
    this.createdByName,
    this.age,
    this.lifespan,
    this.healthRecordsCount = 0,
    this.hereditaryConditions = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  String get fullName {
    final parts = [firstName, middleName, lastName].where((part) => part != null && part.isNotEmpty);
    return parts.join(' ');
  }

  String get displayName {
    if (maidenName != null && maidenName!.isNotEmpty) {
      return '$firstName $lastName (née $maidenName)';
    }
    return fullName;
  }

  static List<String> _parseStringList(dynamic value) {
    if (value == null) return [];
    
    if (value is List) {
      return value.map((item) {
        if (item is String) {
          return item;
        } else if (item is Map) {
          return item['id']?.toString() ?? item['name']?.toString() ?? '';
        }
        return item.toString();
      }).where((s) => s.isNotEmpty).toList();
    }
    
    if (value is String) {
      return [value];
    }
    
    return [];
  }

  factory GenealogyPerson.fromJson(Map<String, dynamic> json) {
    return GenealogyPerson(
      id: json['id'] ?? json['_id'] ?? '',
      firstName: json['first_name'] ?? '',
      middleName: json['middle_name'],
      lastName: json['last_name'] ?? '',
      maidenName: json['maiden_name'],
      gender: json['gender'] ?? 'unknown',
      dateOfBirth: json['date_of_birth'] != null 
          ? DateTime.parse(json['date_of_birth']) 
          : null,
      placeOfBirth: json['place_of_birth'],
      dateOfDeath: json['date_of_death'] != null 
          ? DateTime.parse(json['date_of_death']) 
          : null,
      placeOfDeath: json['place_of_death'],
      isDeceased: json['is_deceased'] ?? false,
      biography: json['biography'],
      photoUrl: json['photo_url'],
      generation: json['generation'] ?? 0,
      occupation: json['occupation'],
      familyCircleIds: _parseStringList(json['family_circle_ids']),
      createdBy: json['created_by'] ?? '',
      createdByName: json['created_by_name'],
      age: json['age'],
      lifespan: json['lifespan'],
      healthRecordsCount: json['health_records_count'] ?? 0,
      hereditaryConditions: _parseStringList(json['hereditary_conditions']),
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'first_name': firstName,
      'middle_name': middleName,
      'last_name': lastName,
      'maiden_name': maidenName,
      'gender': gender,
      'date_of_birth': dateOfBirth?.toIso8601String(),
      'place_of_birth': placeOfBirth,
      'date_of_death': dateOfDeath?.toIso8601String(),
      'place_of_death': placeOfDeath,
      'is_deceased': isDeceased,
      'biography': biography,
      'photo_url': photoUrl,
      'generation': generation,
      'occupation': occupation,
      'family_circle_ids': familyCircleIds,
      'created_by': createdBy,
      'created_by_name': createdByName,
      'age': age,
      'lifespan': lifespan,
      'health_records_count': healthRecordsCount,
      'hereditary_conditions': hereditaryConditions,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
