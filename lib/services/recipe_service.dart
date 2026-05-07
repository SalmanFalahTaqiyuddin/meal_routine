import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/recipe_model.dart';

class RecipeService {
  static Future<List<Recipe>> getRecipes() async {
    try {
      final res = await http.get(
        Uri.parse('${AppConfig.baseUrl}/recipes'),
        headers: {'Content-Type': 'application/json'},
      );
      final data = jsonDecode(res.body);
      if (data['success'] == true) {
        return (data['data'] as List).map((e) => Recipe.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<Recipe?> getRecipeDetail(int id) async {
    try {
      final res = await http.get(
        Uri.parse('${AppConfig.baseUrl}/recipes/$id'),
        headers: {'Content-Type': 'application/json'},
      );
      final data = jsonDecode(res.body);
      if (data['success'] == true) {
        return Recipe.fromJson(data['data']);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<bool> createRecipe(Recipe recipe) async {
    try {
      final res = await http.post(
        Uri.parse('${AppConfig.baseUrl}/recipes'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(recipe.toJson()),
      );
      final data = jsonDecode(res.body);
      return data['success'] == true;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> deleteRecipe(int id) async {
    try {
      final res = await http.delete(
        Uri.parse('${AppConfig.baseUrl}/recipes/$id'),
        headers: {'Content-Type': 'application/json'},
      );
      final data = jsonDecode(res.body);
      return data['success'] == true;
    } catch (e) {
      return false;
    }
  }

  static Future<List<Recipe>> getMyRecipes() async {
    try {
      final res = await http.get(
        Uri.parse('${AppConfig.baseUrl}/profile/recipes'),
        headers: {'Content-Type': 'application/json'},
      );
      final data = jsonDecode(res.body);
      if (data['success'] == true) {
        return (data['data'] as List).map((e) => Recipe.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}
