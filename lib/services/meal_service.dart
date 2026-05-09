import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/meal_model.dart';
import 'storage_service.dart';

class MealService {
  static Future<bool> addMeal({
    required String name,
    required String duration,
    required String image,
    required String mealType,
    required String dateKey,
    List<String> ingredients = const [],
    List<String> steps = const [],
    int? recipeId, // ✅ TAMBAH
  }) async {
    final meal = Meal(
      id: DateTime.now().millisecondsSinceEpoch,
      recipeId: recipeId, // ✅ TAMBAH
      name: name,
      duration: duration,
      image: image,
      mealType: mealType,
      ingredients: ingredients,
      steps: steps,
    );

    await StorageService.addMeal(dateKey, meal.toJson());

    try {
      await http.post(
        Uri.parse('${AppConfig.baseUrl}/meals'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'duration': duration,
          'image': image,
          'meal_type': mealType,
          'ingredients': ingredients,
          'steps': steps,
          if (recipeId != null) 'recipe_id': recipeId,
        }),
      );
    } catch (_) {}

    return true;
  }

  static Future<bool> deleteMeal(String dateKey, int id) async {
    await StorageService.removeMeal(dateKey, id);
    try {
      await http.delete(
        Uri.parse('${AppConfig.baseUrl}/meals/$id'),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (_) {}
    return true;
  }

  static Future<List<Meal>> getMealsByKey(String key) async {
    final store = await StorageService.loadMeals();
    final list = store[key] ?? [];
    return list.map((e) => Meal.fromJson(e)).toList();
  }

  static Future<Set<String>> getAllMealKeys() async {
    final store = await StorageService.loadMeals();
    return store.entries
        .where((e) => e.value.isNotEmpty)
        .map((e) => e.key)
        .toSet();
  }
}
