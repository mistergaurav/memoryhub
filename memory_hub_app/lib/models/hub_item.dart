class HubItem {
  final String id;
  final String title;
  final String? description;
  final String itemType;
  final Map<String, dynamic> content;
  final List<String> tags;
  final String privacy;
  final bool isPinned;
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

  HubItem({
    required this.id,
    required this.title,
    this.description,
    required this.itemType,
    this.content = const {},
    this.tags = const [],
    this.privacy = 'private',
    this.isPinned = false,
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

  factory HubItem.fromJson(Map<String, dynamic> json) {
    return HubItem(
      id: json['id'] ?? json['_id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      itemType: json['item_type'] ?? '',
      content: json['content'] != null
          ? Map<String, dynamic>.from(json['content'])
          : {},
      tags: json['tags'] != null ? List<String>.from(json['tags']) : [],
      privacy: json['privacy'] ?? 'private',
      isPinned: json['is_pinned'] ?? false,
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
      'description': description,
      'item_type': itemType,
      'content': content,
      'tags': tags,
      'privacy': privacy,
      'is_pinned': isPinned,
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

class HubStats {
  final int totalMemories;
  final int totalFiles;
  final int totalViews;
  final int totalLikes;

  HubStats({
    this.totalMemories = 0,
    this.totalFiles = 0,
    this.totalViews = 0,
    this.totalLikes = 0,
  });

  factory HubStats.fromJson(Map<String, dynamic> json) {
    return HubStats(
      totalMemories: json['total_memories'] ?? json['memories_count'] ?? 0,
      totalFiles: json['total_files'] ?? json['files_count'] ?? 0,
      totalViews: json['total_views'] ?? 0,
      totalLikes: json['total_likes'] ?? 0,
    );
  }
}
