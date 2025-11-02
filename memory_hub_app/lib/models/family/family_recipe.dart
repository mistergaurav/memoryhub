class RecipeIngredient {
  final String name;
  final String amount;
  final String? unit;

  RecipeIngredient({
    required this.name,
    required this.amount,
    this.unit,
  });

  factory RecipeIngredient.fromJson(Map<String, dynamic> json) {
    return RecipeIngredient(
      name: json['name'] ?? '',
      amount: json['amount'] ?? '',
      unit: json['unit'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'amount': amount,
      if (unit != null) 'unit': unit,
    };
  }
}

class RecipeStep {
  final int stepNumber;
  final String instruction;
  final String? photo;

  RecipeStep({
    required this.stepNumber,
    required this.instruction,
    this.photo,
  });

  factory RecipeStep.fromJson(Map<String, dynamic> json) {
    return RecipeStep(
      stepNumber: json['step_number'] ?? 0,
      instruction: json['instruction'] ?? '',
      photo: json['photo'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'step_number': stepNumber,
      'instruction': instruction,
      if (photo != null) 'photo': photo,
    };
  }
}

class FamilyRecipe {
  final String id;
  final String title;
  final String? description;
  final String category;
  final String difficulty;
  final int? prepTimeMinutes;
  final int? cookTimeMinutes;
  final int? servings;
  final List<RecipeIngredient> ingredients;
  final List<RecipeStep> steps;
  final List<String> photos;
  final String? familyNotes;
  final String? originStory;
  final String createdBy;
  final String? createdByName;
  final List<String> familyCircleIds;
  final double averageRating;
  final int timesMade;
  final int favoritesCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  FamilyRecipe({
    required this.id,
    required this.title,
    this.description,
    required this.category,
    required this.difficulty,
    this.prepTimeMinutes,
    this.cookTimeMinutes,
    this.servings,
    required this.ingredients,
    required this.steps,
    required this.photos,
    this.familyNotes,
    this.originStory,
    required this.createdBy,
    this.createdByName,
    required this.familyCircleIds,
    required this.averageRating,
    required this.timesMade,
    required this.favoritesCount,
    required this.createdAt,
    required this.updatedAt,
  });

  int get totalTime => (prepTimeMinutes ?? 0) + (cookTimeMinutes ?? 0);

  String get categoryDisplay {
    switch (category) {
      case 'main_course':
        return 'Main Course';
      case 'appetizer':
        return 'Appetizer';
      case 'dessert':
        return 'Dessert';
      case 'beverage':
        return 'Beverage';
      case 'snack':
        return 'Snack';
      case 'breakfast':
        return 'Breakfast';
      case 'salad':
        return 'Salad';
      case 'soup':
        return 'Soup';
      case 'sauce':
        return 'Sauce';
      case 'baking':
        return 'Baking';
      default:
        return 'Other';
    }
  }

  factory FamilyRecipe.fromJson(Map<String, dynamic> json) {
    return FamilyRecipe(
      id: json['id'] ?? json['_id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      category: json['category'] ?? 'other',
      difficulty: json['difficulty'] ?? 'medium',
      prepTimeMinutes: json['prep_time_minutes'],
      cookTimeMinutes: json['cook_time_minutes'],
      servings: json['servings'],
      ingredients: (json['ingredients'] as List<dynamic>?)
              ?.map((i) => RecipeIngredient.fromJson(i as Map<String, dynamic>))
              .toList() ??
          [],
      steps: (json['steps'] as List<dynamic>?)
              ?.map((s) => RecipeStep.fromJson(s as Map<String, dynamic>))
              .toList() ??
          [],
      photos: List<String>.from(json['photos'] ?? []),
      familyNotes: json['family_notes'],
      originStory: json['origin_story'],
      createdBy: json['created_by'] ?? '',
      createdByName: json['created_by_name'],
      familyCircleIds: List<String>.from(json['family_circle_ids'] ?? []),
      averageRating: (json['average_rating'] ?? 0).toDouble(),
      timesMade: json['times_made'] ?? 0,
      favoritesCount: json['favorites_count'] ?? 0,
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
    );
  }
}
