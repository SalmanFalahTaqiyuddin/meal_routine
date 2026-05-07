class Recipe {
  final int id;
  final String name;
  final String image;
  final String duration;
  final List<String> ingredients;
  final List<String> steps;
  final bool isCustom;

  Recipe({
    required this.id,
    required this.name,
    required this.image,
    required this.duration,
    required this.ingredients,
    required this.steps,
    this.isCustom = false,
  });

  factory Recipe.fromJson(Map<String, dynamic> json) => Recipe(
    id: json['id'],
    name: json['name'],
    image: json['image'] ?? '',
    duration: json['duration'],
    ingredients: List<String>.from(json['ingredients'] ?? []),
    steps: List<String>.from(json['steps'] ?? []),
    isCustom: json['is_custom'] ?? false,
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    'image': image,
    'duration': duration,
    'ingredients': ingredients,
    'steps': steps,
    'is_custom': isCustom,
  };
}
