class UserSearchResult {
  final String id;
  final String fullName;
  final String? email;
  final String? avatarUrl;
  final String relationType;

  UserSearchResult({
    required this.id,
    required this.fullName,
    this.email,
    this.avatarUrl,
    required this.relationType,
  });

  factory UserSearchResult.fromJson(Map<String, dynamic> json) {
    return UserSearchResult(
      id: json['id'] ?? json['_id'] ?? '',
      fullName: json['full_name'] ?? json['name'] ?? '',
      email: json['email'],
      avatarUrl: json['avatar_url'],
      relationType: json['relation_type'] ?? 'family',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'email': email,
      'avatar_url': avatarUrl,
      'relation_type': relationType,
    };
  }
}
