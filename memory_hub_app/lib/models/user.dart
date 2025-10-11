class User {
  final String id;
  final String email;
  final String? fullName;
  final String? avatarUrl;
  final String? bio;
  final bool isActive;
  final String role;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, int>? stats;

  User({
    required this.id,
    required this.email,
    this.fullName,
    this.avatarUrl,
    this.bio,
    this.isActive = true,
    this.role = 'user',
    required this.createdAt,
    required this.updatedAt,
    this.stats,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? json['_id'] ?? '',
      email: json['email'] ?? '',
      fullName: json['full_name'],
      avatarUrl: json['avatar_url'],
      bio: json['bio'],
      isActive: json['is_active'] ?? true,
      role: json['role'] ?? 'user',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
      stats: json['stats'] != null
          ? Map<String, int>.from(json['stats'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'avatar_url': avatarUrl,
      'bio': bio,
      'is_active': isActive,
      'role': role,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'stats': stats,
    };
  }
}

class UserUpdate {
  final String? email;
  final String? fullName;
  final String? bio;

  UserUpdate({
    this.email,
    this.fullName,
    this.bio,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (email != null) data['email'] = email;
    if (fullName != null) data['full_name'] = fullName;
    if (bio != null) data['bio'] = bio;
    return data;
  }
}

class AuthTokens {
  final String accessToken;
  final String refreshToken;
  final String tokenType;

  AuthTokens({
    required this.accessToken,
    required this.refreshToken,
    this.tokenType = 'bearer',
  });

  factory AuthTokens.fromJson(Map<String, dynamic> json) {
    return AuthTokens(
      accessToken: json['access_token'] ?? '',
      refreshToken: json['refresh_token'] ?? '',
      tokenType: json['token_type'] ?? 'bearer',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'access_token': accessToken,
      'refresh_token': refreshToken,
      'token_type': tokenType,
    };
  }
}
