class HealthRecord {
  final String id;
  final String recordType;
  final String title;
  final String? description;
  final DateTime recordDate;
  final String? diagnosis;
  final String? treatment;
  final String? provider;
  final String? facility;
  final List<String> attachments;
  final String? personId;
  final String? personName;
  
  // New genealogy fields
  final String? genealogyPersonId;
  final String? genealogyPersonName;
  final bool isHereditary;
  final String? inheritancePattern;
  final int? ageOfOnset;
  final List<String> affectedRelatives;
  
  final String createdBy;
  final String? createdByName;
  final List<String> familyCircleIds;
  final DateTime createdAt;
  final DateTime updatedAt;

  HealthRecord({
    required this.id,
    required this.recordType,
    required this.title,
    this.description,
    required this.recordDate,
    this.diagnosis,
    this.treatment,
    this.provider,
    this.facility,
    this.attachments = const [],
    this.personId,
    this.personName,
    this.genealogyPersonId,
    this.genealogyPersonName,
    this.isHereditary = false,
    this.inheritancePattern,
    this.ageOfOnset,
    this.affectedRelatives = const [],
    required this.createdBy,
    this.createdByName,
    this.familyCircleIds = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory HealthRecord.fromJson(Map<String, dynamic> json) {
    return HealthRecord(
      id: json['id'] ?? json['_id'] ?? '',
      recordType: json['record_type'] ?? 'general',
      title: json['title'] ?? '',
      description: json['description'],
      recordDate: DateTime.parse(json['record_date'] ?? DateTime.now().toIso8601String()),
      diagnosis: json['diagnosis'],
      treatment: json['treatment'],
      provider: json['provider'],
      facility: json['facility'],
      attachments: List<String>.from(json['attachments'] ?? []),
      personId: json['person_id'],
      personName: json['person_name'],
      genealogyPersonId: json['genealogy_person_id'],
      genealogyPersonName: json['genealogy_person_name'],
      isHereditary: json['is_hereditary'] ?? false,
      inheritancePattern: json['inheritance_pattern'],
      ageOfOnset: json['age_of_onset'],
      affectedRelatives: List<String>.from(json['affected_relatives'] ?? []),
      createdBy: json['created_by'] ?? '',
      createdByName: json['created_by_name'],
      familyCircleIds: List<String>.from(json['family_circle_ids'] ?? []),
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'record_type': recordType,
      'title': title,
      'description': description,
      'record_date': recordDate.toIso8601String(),
      'diagnosis': diagnosis,
      'treatment': treatment,
      'provider': provider,
      'facility': facility,
      'attachments': attachments,
      'person_id': personId,
      'person_name': personName,
      'genealogy_person_id': genealogyPersonId,
      'genealogy_person_name': genealogyPersonName,
      'is_hereditary': isHereditary,
      'inheritance_pattern': inheritancePattern,
      'age_of_onset': ageOfOnset,
      'affected_relatives': affectedRelatives,
      'created_by': createdBy,
      'created_by_name': createdByName,
      'family_circle_ids': familyCircleIds,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
