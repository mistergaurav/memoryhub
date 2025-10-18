class ParentalControlSettings {
  final String id;
  final String familyId;
  final Map<String, dynamic> contentFilters;
  final Map<String, dynamic> timeRestrictions;
  final bool requireApproval;
  final List<String> approverIds;
  final Map<String, dynamic> allowedFeatures;
  final DateTime createdAt;
  final DateTime updatedAt;

  ParentalControlSettings({
    required this.id,
    required this.familyId,
    required this.contentFilters,
    required this.timeRestrictions,
    required this.requireApproval,
    required this.approverIds,
    required this.allowedFeatures,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ParentalControlSettings.fromJson(Map<String, dynamic> json) {
    return ParentalControlSettings(
      id: json['id'] ?? json['_id'] ?? '',
      familyId: json['family_id'] ?? '',
      contentFilters: json['content_filters'] ?? {},
      timeRestrictions: json['time_restrictions'] ?? {},
      requireApproval: json['require_approval'] ?? false,
      approverIds: List<String>.from(json['approver_ids'] ?? []),
      allowedFeatures: json['allowed_features'] ?? {},
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
    );
  }
}

class ApprovalRequest {
  final String id;
  final String userId;
  final String? userName;
  final String actionType;
  final String resourceType;
  final String resourceId;
  final Map<String, dynamic> actionDetails;
  final String status;
  final String? approvedBy;
  final String? approvedByName;
  final DateTime? approvedAt;
  final String? rejectionReason;
  final DateTime createdAt;

  ApprovalRequest({
    required this.id,
    required this.userId,
    this.userName,
    required this.actionType,
    required this.resourceType,
    required this.resourceId,
    required this.actionDetails,
    required this.status,
    this.approvedBy,
    this.approvedByName,
    this.approvedAt,
    this.rejectionReason,
    required this.createdAt,
  });

  factory ApprovalRequest.fromJson(Map<String, dynamic> json) {
    return ApprovalRequest(
      id: json['id'] ?? json['_id'] ?? '',
      userId: json['user_id'] ?? '',
      userName: json['user_name'],
      actionType: json['action_type'] ?? '',
      resourceType: json['resource_type'] ?? '',
      resourceId: json['resource_id'] ?? '',
      actionDetails: json['action_details'] ?? {},
      status: json['status'] ?? 'pending',
      approvedBy: json['approved_by'],
      approvedByName: json['approved_by_name'],
      approvedAt: json['approved_at'] != null
          ? DateTime.parse(json['approved_at'])
          : null,
      rejectionReason: json['rejection_reason'],
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }
}
