class UserSearchResult {
  final String id;
  final String fullName;
  final String? email;
  final String? avatarUrl;
  final String relationType;
  final String? source;
  final bool requiresApproval;

  UserSearchResult({
    required this.id,
    required this.fullName,
    this.email,
    this.avatarUrl,
    required this.relationType,
    this.source,
    this.requiresApproval = false,
  });

  factory UserSearchResult.fromJson(Map<String, dynamic> json) {
    // Use full_name if available, otherwise fall back to email or username
    String displayName = json['full_name'] ?? json['name'] ?? '';
    if (displayName.isEmpty) {
      displayName = json['email'] ?? json['username'] ?? 'Unknown User';
    }
    
    return UserSearchResult(
      id: json['id'] ?? json['_id'] ?? '',
      fullName: displayName,
      email: json['email'],
      avatarUrl: json['avatar_url'],
      relationType: json['relation_type'] ?? 'family',
      source: json['source'],
      requiresApproval: json['requires_approval'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'email': email,
      'avatar_url': avatarUrl,
      'relation_type': relationType,
      'source': source,
      'requires_approval': requiresApproval,
    };
  }
}
