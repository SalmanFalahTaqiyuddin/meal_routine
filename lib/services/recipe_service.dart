import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/recipe_model.dart';
import 'storage_service.dart';

class RecipeService {
  /// Ambil semua resep dari Mockoon + resep custom lokal
  static Future<List<Recipe>> getRecipes() async {
    final List<Recipe> result = [];

    // Ambil dari Mockoon
    try {
      final res = await http.get(
        Uri.parse('${AppConfig.baseUrl}/recipes'),
        headers: {'Content-Type': 'application/json'},
      );
      final data = jsonDecode(res.body);
      if (data['success'] == true) {
        result.addAll((data['data'] as List).map((e) => Recipe.fromJson(e)));
      }
    } catch (_) {}

    // Tambah resep custom dari local storage
    final customRaw = await StorageService.loadCustomRecipes();
    result.addAll(customRaw.map((e) => Recipe.fromJson(e)));

    return result;
  }

  /// Detail resep dari Mockoon
  static Future<Recipe?> getRecipeDetail(int id) async {
    final all = await getRecipes();
    try {
      return all.firstWhere((r) => r.id == id);
    } catch (_) {}

    try {
      final res = await http.get(
        Uri.parse('${AppConfig.baseUrl}/recipes/$id'),
        headers: {'Content-Type': 'application/json'},
      );
      final data = jsonDecode(res.body);
      if (data['success'] == true) {
        return Recipe.fromJson(data['data']);
      }
    } catch (_) {}

    return null;
  }

  /// Buat resep custom — simpan lokal + kirim Mockoon.
  ///
  /// ✅ FIX: StorageService.addCustomRecipe sekarang auto-generate ID dari
  /// timestamp, lalu kita load kembali resep yang baru disimpan agar
  /// objek Recipe yang dikembalikan sudah punya ID yang valid.
  static Future<bool> createRecipe(Recipe recipe) async {
    // Simpan ke local storage (ID di-generate di dalam addCustomRecipe)
    await StorageService.addCustomRecipe(recipe.toJson());

    // Kirim ke Mockoon (best effort, tidak blocking)
    try {
      await http.post(
        Uri.parse('${AppConfig.baseUrl}/recipes'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(recipe.toJson()),
      );
    } catch (_) {}

    return true;
  }

  /// Hapus resep custom berdasarkan ID.
  ///
  /// ✅ FIX: ID sekarang dijamin ada (di-generate saat createRecipe),
  /// sehingga removeCustomRecipe bisa match dengan benar.
  static Future<bool> deleteRecipe(int id) async {
    // Hapus dari local storage
    await StorageService.removeCustomRecipe(id);

    // Kirim ke Mockoon (best effort)
    try {
      await http.delete(
        Uri.parse('${AppConfig.baseUrl}/recipes/$id'),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (_) {}

    return true;
  }

  /// Ambil hanya resep custom (untuk halaman profile)
  static Future<List<Recipe>> getMyRecipes() async {
    final customRaw = await StorageService.loadCustomRecipes();
    return customRaw.map((e) => Recipe.fromJson(e)).toList();
  }
}