class Meal {
  final int id;
  final int? recipeId; // ✅ TAMBAH: id resep asal
  final String name;
  final String image;
  final String duration;
  final String mealType;
  final List<String> ingredients;
  final List<String> steps;

  Meal({
    required this.id,
    this.recipeId,
    required this.name,
    required this.image,
    required this.duration,
    required this.mealType,
    required this.ingredients,
    this.steps = const [],
  });

  factory Meal.fromJson(Map<String, dynamic> json) => Meal(
    id: json['id'] as int? ?? 0,
    recipeId: json['recipe_id'] as int?,
    name: json['name'] as String,
    image: json['image'] as String? ?? '',
    duration: json['duration'] as String,
    mealType: json['meal_type'] as String? ?? '',
    ingredients: List<String>.from(json['ingredients'] ?? []),
    steps: List<String>.from(json['steps'] ?? []),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    if (recipeId != null) 'recipe_id': recipeId,
    'name': name,
    'image': image,
    'duration': duration,
    'meal_type': mealType,
    'ingredients': ingredients,
    'steps': steps,
  };
}
