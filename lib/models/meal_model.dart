class Meal {
  final int id;
  final String name;
  final String image;
  final String duration;
  final String mealType;
  final List<String> ingredients;

  Meal({
    required this.id,
    required this.name,
    required this.image,
    required this.duration,
    required this.mealType,
    this.ingredients = const [],
  });

  static String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1).toLowerCase();
  }

  factory Meal.fromJson(Map<String, dynamic> json) => Meal(
    id: json['id'],
    name: json['name'],
    image: json['image'] ?? '',
    duration: json['duration'],
    mealType: _capitalize(json['meal_type'] ?? ''),
    ingredients: List<String>.from(json['ingredients'] ?? []),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'image': image,
    'duration': duration,
    'meal_type': mealType,
    'ingredients': ingredients,
  };
}
