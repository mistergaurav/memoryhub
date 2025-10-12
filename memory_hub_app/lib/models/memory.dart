class Memory {
  final String id;
  final String title;
  final String content;
  final List<String> mediaUrls;
  final List<String> tags;
  final String privacy;
  final Map<String, double>? location;
  final String? mood;
  final String ownerId;
  final String? ownerName;
  final String? ownerAvatar;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int viewCount;
  final int likeCount;
  final int commentCount;
  final bool isLiked;
  final bool isBookmarked;

  Memory({
    required this.id,
    required this.title,
    required this.content,
    this.mediaUrls = const [],
    this.tags = const [],
    this.privacy = 'private',
    this.location,
    this.mood,
    required this.ownerId,
    this.ownerName,
    this.ownerAvatar,
    required this.createdAt,
    required this.updatedAt,
    this.viewCount = 0,
    this.likeCount = 0,
    this.commentCount = 0,
    this.isLiked = false,
    this.isBookmarked = false,
  });

  factory Memory.fromJson(Map<String, dynamic> json) {
    return Memory(
      id: json['id'] ?? json['_id'] ?? '',
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      mediaUrls: json['media_urls'] != null
          ? List<String>.from(json['media_urls'])
          : [],
      tags: json['tags'] != null ? List<String>.from(json['tags']) : [],
      privacy: json['privacy'] ?? 'private',
      location: json['location'] != null
          ? Map<String, double>.from(json['location'])
          : null,
      mood: json['mood'],
      ownerId: json['owner_id'] ?? '',
      ownerName: json['owner_name'],
      ownerAvatar: json['owner_avatar'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
      viewCount: json['view_count'] ?? 0,
      likeCount: json['like_count'] ?? 0,
      commentCount: json['comment_count'] ?? 0,
      isLiked: json['is_liked'] ?? false,
      isBookmarked: json['is_bookmarked'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'media_urls': mediaUrls,
      'tags': tags,
      'privacy': privacy,
      'location': location,
      'mood': mood,
      'owner_id': ownerId,
      'owner_name': ownerName,
      'owner_avatar': ownerAvatar,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'view_count': viewCount,
      'like_count': likeCount,
      'comment_count': commentCount,
      'is_liked': isLiked,
      'is_bookmarked': isBookmarked,
    };
  }
}

class MemoryCreate {
  final String title;
  final String content;
  final List<String> tags;
  final String privacy;
  final String? location;
  final String? mood;

  MemoryCreate({
    required this.title,
    required this.content,
    this.tags = const [],
    this.privacy = 'private',
    this.location,
    this.mood,
  });

  // Note: This method is not currently used. Tags are JSON-encoded in ApiService.createMemory
  Map<String, dynamic> toFormData() {
    return {
      'title': title,
      'content': content,
      'tags': tags,  // Keep as list for potential future use
      'privacy': privacy,
      if (location != null) 'location': location,
      if (mood != null) 'mood': mood,
    };
  }
}
