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
  
  final String? genealogyPersonId;
  final String? genealogyPersonName;
  final bool isHereditary;
  final String? inheritancePattern;
  final int? ageOfOnset;
  final List<String> affectedRelatives;
  final List<String> affectedRelativesNames;
  final String? geneticTestResults;
  
  final String subjectType;
  final String? subjectUserId;
  final String? subjectName;
  final String? subjectFamilyMemberId;
  final String? subjectFriendCircleId;
  final List<String> assignedUserIds;
  
  final String? location;
  final String? severity;
  final List<String> medications;
  final String? notes;
  final bool isConfidential;
  
  final List<dynamic> reminders;
  
  final String createdBy;
  final String? createdByName;
  final List<String> familyCircleIds;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  final String? approvalStatus;
  final String? approvedBy;
  final DateTime? approvedAt;
  final String? rejectionReason;

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
    this.affectedRelativesNames = const [],
    this.geneticTestResults,
    this.subjectType = 'self',
    this.subjectUserId,
    this.subjectName,
    this.subjectFamilyMemberId,
    this.subjectFriendCircleId,
    this.assignedUserIds = const [],
    this.location,
    this.severity,
    this.medications = const [],
    this.notes,
    this.isConfidential = true,
    this.reminders = const [],
    required this.createdBy,
    this.createdByName,
    this.familyCircleIds = const [],
    required this.createdAt,
    required this.updatedAt,
    this.approvalStatus = 'draft',
    this.approvedBy,
    this.approvedAt,
    this.rejectionReason,
  });

  factory HealthRecord.fromJson(Map<String, dynamic> json) {
    return HealthRecord(
      id: json['id'] ?? json['_id'] ?? '',
      recordType: json['record_type'] ?? 'general',
      title: json['title'] ?? '',
      description: json['description'],
      recordDate: DateTime.parse(json['record_date'] ?? json['date'] ?? DateTime.now().toIso8601String()),
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
      affectedRelativesNames: List<String>.from(json['affected_relatives_names'] ?? []),
      geneticTestResults: json['genetic_test_results'],
      subjectType: json['subject_type'] ?? 'self',
      subjectUserId: json['subject_user_id'],
      subjectName: json['subject_name'],
      subjectFamilyMemberId: json['subject_family_member_id'],
      subjectFriendCircleId: json['subject_friend_circle_id'],
      assignedUserIds: List<String>.from(json['assigned_user_ids'] ?? []),
      location: json['location'],
      severity: json['severity'],
      medications: List<String>.from(json['medications'] ?? []),
      notes: json['notes'],
      isConfidential: json['is_confidential'] ?? true,
      reminders: json['reminders'] ?? [],
      createdBy: json['created_by'] ?? '',
      createdByName: json['created_by_name'],
      familyCircleIds: List<String>.from(json['family_circle_ids'] ?? []),
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
      approvalStatus: json['approval_status'] ?? 'draft',
      approvedBy: json['approved_by'],
      approvedAt: json['approved_at'] != null ? DateTime.parse(json['approved_at']) : null,
      rejectionReason: json['rejection_reason'],
    );
  }

  String getSubjectDisplay() {
    switch (subjectType.toLowerCase()) {
      case 'self':
        return 'For: Myself';
      case 'family':
        return 'For: ${subjectName ?? 'Family Member'}';
      case 'friend':
        return 'For: ${subjectName ?? 'Friend'}';
      default:
        return 'For: ${subjectName ?? 'Unknown'}';
    }
  }

  bool get hasReminders => reminders.isNotEmpty;
  
  bool get isPendingApproval => approvalStatus == 'pending_approval';
  bool get isApproved => approvalStatus == 'approved';
  bool get isRejected => approvalStatus == 'rejected';

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
      'affected_relatives_names': affectedRelativesNames,
      'genetic_test_results': geneticTestResults,
      'subject_type': subjectType,
      'subject_user_id': subjectUserId,
      'subject_name': subjectName,
      'subject_family_member_id': subjectFamilyMemberId,
      'subject_friend_circle_id': subjectFriendCircleId,
      'assigned_user_ids': assignedUserIds,
      'location': location,
      'severity': severity,
      'medications': medications,
      'notes': notes,
      'is_confidential': isConfidential,
      'reminders': reminders,
      'created_by': createdBy,
      'created_by_name': createdByName,
      'family_circle_ids': familyCircleIds,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'approval_status': approvalStatus,
      'approved_by': approvedBy,
      'approved_at': approvedAt?.toIso8601String(),
      'rejection_reason': rejectionReason,
    };
  }
}
