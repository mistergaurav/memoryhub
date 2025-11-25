enum NotificationType {
  like,
  comment,
  follow,
  hubInvite,
  mention,
  memoryShare,
  healthRecordAssignment,
  healthReminderAssignment,
  healthRecordApproved,
  healthRecordRejected,
  genealogyApprovalRequest,
  genealogyRequestApproved,
  genealogyRequestRejected;

  String toJson() {
    switch (this) {
      case NotificationType.like:
        return 'like';
      case NotificationType.comment:
        return 'comment';
      case NotificationType.follow:
        return 'follow';
      case NotificationType.hubInvite:
        return 'hub_invite';
      case NotificationType.mention:
        return 'mention';
      case NotificationType.memoryShare:
        return 'memory_share';
      case NotificationType.healthRecordAssignment:
        return 'health_record_assigned';
      case NotificationType.healthReminderAssignment:
        return 'health_reminder_assignment';
      case NotificationType.healthRecordApproved:
        return 'health_record_approved';
      case NotificationType.healthRecordRejected:
        return 'health_record_rejected';
      case NotificationType.genealogyApprovalRequest:
        return 'genealogy_approval_request';
      case NotificationType.genealogyRequestApproved:
        return 'genealogy_request_approved';
      case NotificationType.genealogyRequestRejected:
        return 'genealogy_request_rejected';
    }
  }

  static NotificationType fromJson(String value) {
    switch (value) {
      case 'like':
        return NotificationType.like;
      case 'comment':
        return NotificationType.comment;
      case 'follow':
        return NotificationType.follow;
      case 'hub_invite':
        return NotificationType.hubInvite;
      case 'mention':
        return NotificationType.mention;
      case 'memory_share':
        return NotificationType.memoryShare;
      case 'health_record_assigned':
        return NotificationType.healthRecordAssignment;
      case 'health_reminder_assignment':
        return NotificationType.healthReminderAssignment;
      case 'health_record_approved':
        return NotificationType.healthRecordApproved;
      case 'health_record_rejected':
        return NotificationType.healthRecordRejected;
      case 'genealogy_approval_request':
        return NotificationType.genealogyApprovalRequest;
      case 'genealogy_request_approved':
        return NotificationType.genealogyRequestApproved;
      case 'genealogy_request_rejected':
        return NotificationType.genealogyRequestRejected;
      default:
        print('⚠️ Unknown notification type: $value, defaulting to comment');
        return NotificationType.comment;
    }
  }
}

class Notification {
  final String id;
  final NotificationType type;
  final String title;
  final String message;
  final String? targetType;
  final String? targetId;
  final String actorId;
  final String? actorName;
  final String? actorAvatar;
  final bool isRead;
  final DateTime createdAt;
  
  final String? healthRecordId;
  final String? assignerId;
  final String? assignerName;
  final String? approvalStatus;
  final Map<String, dynamic>? metadata;

  Notification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    this.targetType,
    this.targetId,
    required this.actorId,
    this.actorName,
    this.actorAvatar,
    this.isRead = false,
    required this.createdAt,
    this.healthRecordId,
    this.assignerId,
    this.assignerName,
    this.approvalStatus,
    this.metadata,
  });

  factory Notification.fromJson(Map<String, dynamic> json) {
    return Notification(
      id: json['id'] as String,
      type: NotificationType.fromJson(json['type'] as String),
      title: json['title'] as String,
      message: json['message'] as String,
      targetType: json['target_type'] as String?,
      targetId: json['target_id'] as String?,
      actorId: json['actor_id'] as String,
      actorName: json['actor_name'] as String?,
      actorAvatar: json['actor_avatar'] as String?,
      isRead: json['is_read'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      healthRecordId: json['health_record_id'] as String?,
      assignerId: json['assigner_id'] as String?,
      assignerName: json['assigner_name'] as String?,
      approvalStatus: json['approval_status'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toJson(),
      'title': title,
      'message': message,
      'target_type': targetType,
      'target_id': targetId,
      'actor_id': actorId,
      'actor_name': actorName,
      'actor_avatar': actorAvatar,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
      'health_record_id': healthRecordId,
      'assigner_id': assignerId,
      'assigner_name': assignerName,
      'approval_status': approvalStatus,
      'metadata': metadata,
    };
  }

  Notification copyWith({
    String? id,
    NotificationType? type,
    String? title,
    String? message,
    String? targetType,
    String? targetId,
    String? actorId,
    String? actorName,
    String? actorAvatar,
    bool? isRead,
    DateTime? createdAt,
    String? healthRecordId,
    String? assignerId,
    String? assignerName,
    String? approvalStatus,
    Map<String, dynamic>? metadata,
  }) {
    return Notification(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      targetType: targetType ?? this.targetType,
      targetId: targetId ?? this.targetId,
      actorId: actorId ?? this.actorId,
      actorName: actorName ?? this.actorName,
      actorAvatar: actorAvatar ?? this.actorAvatar,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      healthRecordId: healthRecordId ?? this.healthRecordId,
      assignerId: assignerId ?? this.assignerId,
      assignerName: assignerName ?? this.assignerName,
      approvalStatus: approvalStatus ?? this.approvalStatus,
      metadata: metadata ?? this.metadata,
    );
  }
}
