class VaultFile {
  final String id;
  final String name;
  final String? description;
  final List<String> tags;
  final String privacy;
  final String ownerId;
  final String? ownerName;
  final String? ownerAvatar;
  final String filePath;
  final String fileType;
  final int fileSize;
  final String mimeType;
  final bool isFavorite;
  final int downloadCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? downloadUrl;

  VaultFile({
    required this.id,
    required this.name,
    this.description,
    this.tags = const [],
    this.privacy = 'private',
    required this.ownerId,
    this.ownerName,
    this.ownerAvatar,
    required this.filePath,
    required this.fileType,
    required this.fileSize,
    required this.mimeType,
    this.isFavorite = false,
    this.downloadCount = 0,
    required this.createdAt,
    required this.updatedAt,
    this.downloadUrl,
  });

  factory VaultFile.fromJson(Map<String, dynamic> json) {
    return VaultFile(
      id: json['id'] ?? json['_id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      tags: json['tags'] != null ? List<String>.from(json['tags']) : [],
      privacy: json['privacy'] ?? 'private',
      ownerId: json['owner_id'] ?? '',
      ownerName: json['owner_name'],
      ownerAvatar: json['owner_avatar'],
      filePath: json['file_path'] ?? '',
      fileType: json['file_type'] ?? 'other',
      fileSize: json['file_size'] ?? 0,
      mimeType: json['mime_type'] ?? '',
      isFavorite: json['is_favorite'] ?? false,
      downloadCount: json['download_count'] ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
      downloadUrl: json['download_url'],
    );
  }

  String get formattedSize {
    if (fileSize < 1024) {
      return '$fileSize B';
    } else if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(2)} KB';
    } else if (fileSize < 1024 * 1024 * 1024) {
      return '${(fileSize / (1024 * 1024)).toStringAsFixed(2)} MB';
    } else {
      return '${(fileSize / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    }
  }
}

class VaultStats {
  final int totalFiles;
  final int totalSize;
  final Map<String, int> byType;

  VaultStats({
    required this.totalFiles,
    required this.totalSize,
    this.byType = const {},
  });

  factory VaultStats.fromJson(Map<String, dynamic> json) {
    return VaultStats(
      totalFiles: json['total_files'] ?? 0,
      totalSize: json['total_size'] ?? 0,
      byType: json['by_type'] != null
          ? Map<String, int>.from(json['by_type'])
          : {},
    );
  }

  String get formattedTotalSize {
    if (totalSize < 1024) {
      return '$totalSize B';
    } else if (totalSize < 1024 * 1024) {
      return '${(totalSize / 1024).toStringAsFixed(2)} KB';
    } else if (totalSize < 1024 * 1024 * 1024) {
      return '${(totalSize / (1024 * 1024)).toStringAsFixed(2)} MB';
    } else {
      return '${(totalSize / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    }
  }
}
