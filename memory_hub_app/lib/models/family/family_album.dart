class FamilyAlbum {
  final String id;
  final String title;
  final String? description;
  final String? coverPhoto;
  final String privacy;
  final String createdBy;
  final String? createdByName;
  final List<String> familyCircleIds;
  final List<String> memberIds;
  final int photosCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  FamilyAlbum({
    required this.id,
    required this.title,
    this.description,
    this.coverPhoto,
    required this.privacy,
    required this.createdBy,
    this.createdByName,
    required this.familyCircleIds,
    required this.memberIds,
    required this.photosCount,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FamilyAlbum.fromJson(Map<String, dynamic> json) {
    return FamilyAlbum(
      id: json['id'] ?? json['_id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      coverPhoto: json['cover_photo'],
      privacy: json['privacy'] ?? 'private',
      createdBy: json['created_by'] ?? '',
      createdByName: json['created_by_name'],
      familyCircleIds: List<String>.from(json['family_circle_ids'] ?? []),
      memberIds: List<String>.from(json['member_ids'] ?? []),
      photosCount: json['photos_count'] ?? 0,
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'cover_photo': coverPhoto,
      'privacy': privacy,
      'created_by': createdBy,
      'created_by_name': createdByName,
      'family_circle_ids': familyCircleIds,
      'member_ids': memberIds,
      'photos_count': photosCount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class AlbumPhoto {
  final String id;
  final String photoUrl;
  final String? caption;
  final String uploadedBy;
  final String? uploadedByName;
  final int likesCount;
  final DateTime uploadedAt;

  AlbumPhoto({
    required this.id,
    required this.photoUrl,
    this.caption,
    required this.uploadedBy,
    this.uploadedByName,
    required this.likesCount,
    required this.uploadedAt,
  });

  factory AlbumPhoto.fromJson(Map<String, dynamic> json) {
    return AlbumPhoto(
      id: json['id'] ?? json['_id'] ?? '',
      photoUrl: json['url'] ?? json['photo_url'] ?? '',
      caption: json['caption'],
      uploadedBy: json['uploaded_by'] ?? '',
      uploadedByName: json['uploaded_by_name'],
      likesCount: json['likes_count'] ?? 0,
      uploadedAt: DateTime.parse(json['uploaded_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  int get commentsCount => 0;
}
