class Recipe {
  final int? id;
  final String name;
  final String image;
  final String duration;
  final List<String> ingredients;
  final List<String> steps;
  final bool isCustom;

  const Recipe({
    this.id,
    required this.name,
    required this.image,
    required this.duration,
    required this.ingredients,
    required this.steps,
    this.isCustom = false,
  });

  // ── Deserialisasi dari JSON (API / lokal) ──────────────────────────────
  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      id: json['id'] as int?,
      name: json['name'] as String,
      image: json['image'] as String? ?? '',
      duration: json['duration'] as String,
      ingredients: List<String>.from(json['ingredients'] ?? []),
      steps: List<String>.from(json['steps'] ?? []),
      isCustom: json['is_custom'] as bool? ?? false,
    );
  }

  // ── Serialisasi ke JSON ───────────────────────────────────────────────
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'image': image,
      'duration': duration,
      'ingredients': ingredients,
      'steps': steps,
      'is_custom': isCustom,
    };
  }

  // ── copyWith — untuk update sebagian field ────────────────────────────
  Recipe copyWith({
    int? id,
    String? name,
    String? image,
    String? duration,
    List<String>? ingredients,
    List<String>? steps,
    bool? isCustom,
  }) {
    return Recipe(
      id: id ?? this.id,
      name: name ?? this.name,
      image: image ?? this.image,
      duration: duration ?? this.duration,
      ingredients: ingredients ?? this.ingredients,
      steps: steps ?? this.steps,
      isCustom: isCustom ?? this.isCustom,
    );
  }

  // ── Equality & hashCode — supaya bisa dibandingkan / dipakai di Set ───
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Recipe &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name;

  @override
  int get hashCode => id.hashCode ^ name.hashCode;

  // ── toString — memudahkan debugging ──────────────────────────────────
  @override
  String toString() {
    return 'Recipe(id: $id, name: $name, duration: $duration, '
        'isCustom: $isCustom, ingredients: ${ingredients.length} items, '
        'steps: ${steps.length} steps)';
  }
}
