import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const _mealsKey = 'local_meals';
  static const _profileKey = 'local_profile';
  static const _customRecipesKey = 'local_custom_recipes';

  // ─── MEALS ───────────────────────────────────────────────────────────────

  static Future<Map<String, List<Map<String, dynamic>>>> loadMeals() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_mealsKey);
    if (raw == null) return {};
    final decoded = Map<String, dynamic>.from(jsonDecode(raw));
    return decoded.map(
      (k, v) => MapEntry(k, List<Map<String, dynamic>>.from(v)),
    );
  }

  static Future<void> saveMeals(
    Map<String, List<Map<String, dynamic>>> store,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_mealsKey, jsonEncode(store));
  }

  static Future<void> addMeal(String key, Map<String, dynamic> meal) async {
    final store = await loadMeals();
    store[key] = [...(store[key] ?? []), meal];
    await saveMeals(store);
  }

  static Future<void> removeMeal(String key, int id) async {
    final store = await loadMeals();
    store[key]?.removeWhere((m) => m['id'] == id);
    await saveMeals(store);
  }

  static String dateKey(DateTime date, String type) {
    final d =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return '$d|$type';
  }

  // ─── PROFILE ─────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_profileKey);
    if (raw == null) return {'name': 'User', 'email': '', 'avatarPath': null};
    return Map<String, dynamic>.from(jsonDecode(raw));
  }

  /// Merge dengan data lama agar field yang tidak dikirim (misal avatarPath)
  /// tidak tertimpa. Gunakan ini untuk update sebagian field.
  static Future<void> saveProfile(Map<String, dynamic> profile) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = await loadProfile();
    final merged = {...existing, ...profile};
    await prefs.setString(_profileKey, jsonEncode(merged));
  }

  /// Simpan email user yang login — dipanggil dari LoginScreen setelah berhasil login.
  static Future<void> saveEmail(String email) async {
    await saveProfile({'email': email});
  }

  /// Simpan path foto avatar — dipanggil dari ProfileScreen saat user ganti foto.
  static Future<void> saveAvatarPath(String? path) async {
    await saveProfile({'avatarPath': path});
  }

  // ─── CUSTOM RECIPES ───────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> loadCustomRecipes() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_customRecipesKey);
    if (raw == null) return [];
    return List<Map<String, dynamic>>.from(jsonDecode(raw));
  }

  /// Simpan resep custom. Jika belum punya 'id', auto-generate dari timestamp
  /// sehingga setiap resep dijamin punya ID unik yang bisa dipakai untuk delete.
  static Future<void> addCustomRecipe(Map<String, dynamic> recipe) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = await loadCustomRecipes();

    // ✅ FIX: auto-generate ID kalau belum ada
    final recipeWithId = Map<String, dynamic>.from(recipe);
    if (recipeWithId['id'] == null) {
      recipeWithId['id'] = DateTime.now().millisecondsSinceEpoch;
    }

    existing.add(recipeWithId);
    await prefs.setString(_customRecipesKey, jsonEncode(existing));
  }

  /// Hapus resep custom berdasarkan ID.
  /// ✅ FIX: bandingkan sebagai String agar tidak gagal karena int vs num mismatch
  /// (JSON decode bisa mengembalikan num/int tergantung platform).
  static Future<void> removeCustomRecipe(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = await loadCustomRecipes();
    existing.removeWhere((r) => r['id']?.toString() == id.toString());
    await prefs.setString(_customRecipesKey, jsonEncode(existing));
  }

  /// Fallback: hapus resep custom berdasarkan nama.
  /// Dipakai untuk resep lama yang disimpan sebelum auto-generate ID diterapkan
  /// sehingga field 'id'-nya null dan tidak bisa di-match by ID.
  static Future<void> removeCustomRecipeByName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = await loadCustomRecipes();
    existing.removeWhere((r) => r['name'] == name);
    await prefs.setString(_customRecipesKey, jsonEncode(existing));
  }

  // ─── STREAK ──────────────────────────────────────────────────────────────

  static Future<int> calculateStreak() async {
    final meals = await loadMeals();

    final mealDates = meals.entries
        .where((e) => e.value.isNotEmpty)
        .map((e) => e.key.split('|')[0])
        .toSet();

    if (mealDates.isEmpty) return 0;

    int streak = 0;
    DateTime check = DateTime.now();

    while (true) {
      final key =
          '${check.year}-${check.month.toString().padLeft(2, '0')}-${check.day.toString().padLeft(2, '0')}';
      if (mealDates.contains(key)) {
        streak++;
        check = check.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }

    return streak;
  }

  // ─── CLEAR ALL ───────────────────────────────────────────────────────────

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_mealsKey);
    await prefs.remove(_customRecipesKey);
  }
}
