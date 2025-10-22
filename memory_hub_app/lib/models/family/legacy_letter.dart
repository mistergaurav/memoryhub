class LegacyLetter {
  final String id;
  final String title;
  final String? content;
  final DateTime deliveryDate;
  final bool encrypt;
  final String authorId;
  final String? authorName;
  final List<String> recipientIds;
  final List<String> recipientNames;
  final List<String> attachments;
  final String status;
  final DateTime? deliveredAt;
  final int readCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  LegacyLetter({
    required this.id,
    required this.title,
    this.content,
    required this.deliveryDate,
    required this.encrypt,
    required this.authorId,
    this.authorName,
    required this.recipientIds,
    required this.recipientNames,
    required this.attachments,
    required this.status,
    this.deliveredAt,
    required this.readCount,
    required this.createdAt,
    required this.updatedAt,
  });

  factory LegacyLetter.fromJson(Map<String, dynamic> json) {
    return LegacyLetter(
      id: json['id'] ?? json['_id'] ?? '',
      title: json['title'] ?? '',
      content: json['content'],
      deliveryDate: DateTime.parse(json['delivery_date'] ?? DateTime.now().toIso8601String()),
      encrypt: json['encrypt'] ?? false,
      authorId: json['author_id'] ?? '',
      authorName: json['author_name'],
      recipientIds: List<String>.from(json['recipient_ids'] ?? []),
      recipientNames: List<String>.from(json['recipient_names'] ?? []),
      attachments: List<String>.from(json['attachments'] ?? []),
      status: json['status'] ?? 'draft',
      deliveredAt: json['delivered_at'] != null
          ? DateTime.parse(json['delivered_at'])
          : null,
      readCount: json['read_count'] ?? 0,
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
    );
  }
}

class ReceivedLetter {
  final String id;
  final String title;
  final String content;
  final DateTime deliveryDate;
  final String authorId;
  final String? authorName;
  final List<String> attachments;
  final DateTime deliveredAt;
  final bool isRead;
  final DateTime createdAt;

  ReceivedLetter({
    required this.id,
    required this.title,
    required this.content,
    required this.deliveryDate,
    required this.authorId,
    this.authorName,
    required this.attachments,
    required this.deliveredAt,
    required this.isRead,
    required this.createdAt,
  });

  factory ReceivedLetter.fromJson(Map<String, dynamic> json) {
    return ReceivedLetter(
      id: json['id'] ?? json['_id'] ?? '',
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      deliveryDate: DateTime.parse(json['delivery_date'] ?? DateTime.now().toIso8601String()),
      authorId: json['author_id'] ?? '',
      authorName: json['author_name'],
      attachments: List<String>.from(json['attachments'] ?? []),
      deliveredAt: DateTime.parse(json['delivered_at'] ?? DateTime.now().toIso8601String()),
      isRead: json['is_read'] ?? false,
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }
}
