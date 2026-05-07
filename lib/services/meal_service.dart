import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/meal_model.dart';

class MealService {
  static Future<List<Meal>> getMeals() async {
    try {
      final res = await http.get(
        Uri.parse('${AppConfig.baseUrl}/meals'),
        headers: {'Content-Type': 'application/json'},
      );
      final data = jsonDecode(res.body);
      if (data['success'] == true) {
        return (data['data'] as List).map((e) => Meal.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<bool> addMeal({
    required String name,
    required String duration,
    required String image,
    required String mealType,
    List<String> ingredients = const [],
  }) async {
    try {
      final res = await http.post(
        Uri.parse('${AppConfig.baseUrl}/meals'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'duration': duration,
          'image': image,
          'meal_type': mealType,
          'ingredients': ingredients,
        }),
      );
      final data = jsonDecode(res.body);
      return data['success'] == true;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> deleteMeal(int id) async {
    try {
      final res = await http.delete(
        Uri.parse('${AppConfig.baseUrl}/meals/$id'),
        headers: {'Content-Type': 'application/json'},
      );
      final data = jsonDecode(res.body);
      return data['success'] == true;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> updateMeal(int id, String name, String duration) async {
    try {
      final res = await http.put(
        Uri.parse('${AppConfig.baseUrl}/meals/$id'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'name': name, 'duration': duration}),
      );
      final data = jsonDecode(res.body);
      return data['success'] == true;
    } catch (e) {
      return false;
    }
  }
}
