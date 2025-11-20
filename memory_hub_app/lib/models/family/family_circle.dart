class FamilyCircle {
  final String id;
  final String name;
  final String? description;
  final String circleType;
  final String? avatarUrl;
  final String? color;
  final String ownerId;
  final int memberCount;
  final List<CircleMember> members;
  final DateTime createdAt;
  final DateTime updatedAt;

  FamilyCircle({
    required this.id,
    required this.name,
    this.description,
    required this.circleType,
    this.avatarUrl,
    this.color,
    required this.ownerId,
    required this.memberCount,
    required this.members,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FamilyCircle.fromJson(Map<String, dynamic> json) {
    return FamilyCircle(
      id: json['id'] ?? json['_id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      circleType: json['circle_type'] ?? 'custom',
      avatarUrl: json['avatar_url'],
      color: json['color'],
      ownerId: json['owner_id'] ?? '',
      memberCount: json['member_count'] ?? 0,
      members: (json['members'] as List<dynamic>?)
              ?.map((m) => CircleMember.fromJson(m as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'circle_type': circleType,
      'avatar_url': avatarUrl,
      'color': color,
      'owner_id': ownerId,
      'member_count': memberCount,
      'members': members.map((m) => m.toJson()).toList(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  String get displayCircleType {
    switch (circleType.toLowerCase()) {
      case 'immediate_family':
        return 'Immediate Family';
      case 'extended_family':
        return 'Extended Family';
      case 'close_friends':
        return 'Close Friends';
      case 'work_friends':
        return 'Work Friends';
      case 'custom':
        return 'Custom';
      default:
        return circleType;
    }
  }
}

class CircleMember {
  final String id;
  final String name;
  final String? avatar;
  final String? relationshipLabel;

  CircleMember({
    required this.id,
    required this.name,
    this.avatar,
    this.relationshipLabel,
  });

  factory CircleMember.fromJson(Map<String, dynamic> json) {
    return CircleMember(
      id: json['user_id'] ?? json['id'] ?? '',
      name: json['display_name'] ?? json['name'] ?? 'Unknown',
      avatar: json['avatar_url'] ?? json['avatar'],
      relationshipLabel: json['relationship_label'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'avatar': avatar,
      'relationship_label': relationshipLabel,
    };
  }
}

class FamilyCircleCreate {
  final String name;
  final String? description;
  final String circleType;
  final String? avatarUrl;
  final String? color;
  final List<String> memberIds;

  FamilyCircleCreate({
    required this.name,
    this.description,
    this.circleType = 'custom',
    this.avatarUrl,
    this.color,
    this.memberIds = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'circle_type': circleType,
      'avatar_url': avatarUrl,
      'color': color,
      'member_ids': memberIds,
    };
  }
}

class FamilyCircleUpdate {
  final String? name;
  final String? description;
  final String? circleType;
  final String? avatarUrl;
  final String? color;

  FamilyCircleUpdate({
    this.name,
    this.description,
    this.circleType,
    this.avatarUrl,
    this.color,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (name != null) data['name'] = name;
    if (description != null) data['description'] = description;
    if (circleType != null) data['circle_type'] = circleType;
    if (avatarUrl != null) data['avatar_url'] = avatarUrl;
    if (color != null) data['color'] = color;
    return data;
  }
}
