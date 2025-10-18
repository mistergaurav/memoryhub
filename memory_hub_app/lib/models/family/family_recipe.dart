class FamilyRecipe {
  final String id;
  final String title;
  final String? description;
  final String? photoUrl;
  final List<String> ingredients;
  final List<String> instructions;
  final int prepTime;
  final int cookTime;
  final int servings;
  final String difficulty;
  final String? origin;
  final String createdBy;
  final String? createdByName;
  final List<String> familyCircleIds;
  final List<String> tags;
  final int likesCount;
  final int savesCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  FamilyRecipe({
    required this.id,
    required this.title,
    this.description,
    this.photoUrl,
    required this.ingredients,
    required this.instructions,
    required this.prepTime,
    required this.cookTime,
    required this.servings,
    required this.difficulty,
    this.origin,
    required this.createdBy,
    this.createdByName,
    required this.familyCircleIds,
    required this.tags,
    required this.likesCount,
    required this.savesCount,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FamilyRecipe.fromJson(Map<String, dynamic> json) {
    return FamilyRecipe(
      id: json['id'] ?? json['_id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      photoUrl: json['photo_url'],
      ingredients: List<String>.from(json['ingredients'] ?? []),
      instructions: List<String>.from(json['instructions'] ?? []),
      prepTime: json['prep_time'] ?? 0,
      cookTime: json['cook_time'] ?? 0,
      servings: json['servings'] ?? 1,
      difficulty: json['difficulty'] ?? 'medium',
      origin: json['origin'],
      createdBy: json['created_by'] ?? '',
      createdByName: json['created_by_name'],
      familyCircleIds: List<String>.from(json['family_circle_ids'] ?? []),
      tags: List<String>.from(json['tags'] ?? []),
      likesCount: json['likes_count'] ?? 0,
      savesCount: json['saves_count'] ?? 0,
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
    );
  }
}
