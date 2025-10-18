class LegacyLetter {
  final String id;
  final String title;
  final String content;
  final String recipientType;
  final List<String> recipientIds;
  final String deliveryType;
  final DateTime? scheduledDelivery;
  final String? deliveryConditions;
  final bool isSealed;
  final String createdBy;
  final String? createdByName;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deliveredAt;

  LegacyLetter({
    required this.id,
    required this.title,
    required this.content,
    required this.recipientType,
    required this.recipientIds,
    required this.deliveryType,
    this.scheduledDelivery,
    this.deliveryConditions,
    required this.isSealed,
    required this.createdBy,
    this.createdByName,
    required this.createdAt,
    required this.updatedAt,
    this.deliveredAt,
  });

  factory LegacyLetter.fromJson(Map<String, dynamic> json) {
    return LegacyLetter(
      id: json['id'] ?? json['_id'] ?? '',
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      recipientType: json['recipient_type'] ?? 'individual',
      recipientIds: List<String>.from(json['recipient_ids'] ?? []),
      deliveryType: json['delivery_type'] ?? 'scheduled',
      scheduledDelivery: json['scheduled_delivery'] != null
          ? DateTime.parse(json['scheduled_delivery'])
          : null,
      deliveryConditions: json['delivery_conditions'],
      isSealed: json['is_sealed'] ?? false,
      createdBy: json['created_by'] ?? '',
      createdByName: json['created_by_name'],
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
      deliveredAt: json['delivered_at'] != null
          ? DateTime.parse(json['delivered_at'])
          : null,
    );
  }
}
