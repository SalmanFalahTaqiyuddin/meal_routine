import 'package:flutter/foundation.dart';
import '../helpers/db_helper.dart';
import '../models/meal_model.dart';

class ScheduleProvider extends ChangeNotifier {
  // Struktur: { 'Sunday': { 'Breakfast': [Meal, ...] } }
  Map<String, Map<String, List<Meal>>> _schedules = {};
  bool _isLoading = false;

  Map<String, Map<String, List<Meal>>> get schedules => _schedules;
  bool get isLoading => _isLoading;

  /// Daftar hari dalam urutan Minggu-Sabtu
  static const List<String> days = [
    'Sunday',
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
  ];

  static const List<String> mealTypes = ['Breakfast', 'Lunch', 'Dinner'];

  /// Load semua jadwal dari SQLite
  Future<void> loadSchedules() async {
    _isLoading = true;
    notifyListeners();

    _schedules = await DBHelper.getAllSchedules();

    _isLoading = false;
    notifyListeners();
  }

  /// Ambil meals untuk hari & meal type tertentu
  List<Meal> getMeals(String day, String mealType) {
    return _schedules[day]?[mealType] ?? [];
  }

  /// Cek apakah ada meal di hari tertentu
  bool hasMealsOnDay(String day) {
    final daySchedule = _schedules[day];
    if (daySchedule == null) return false;
    return mealTypes.any((type) =>
        daySchedule[type] != null && daySchedule[type]!.isNotEmpty);
  }

  /// Tambah meal ke jadwal
  Future<void> addMeal({
    required String day,
    required String mealType,
    required Meal meal,
  }) async {
    await DBHelper.insertSchedule(day: day, mealType: mealType, meal: meal);
    await loadSchedules();
  }

  /// Hapus semua meal di hari & meal type tertentu
  Future<void> clearMeals({
    required String day,
    required String mealType,
  }) async {
    await DBHelper.clearDayMealType(day: day, mealType: mealType);
    await loadSchedules();
  }
}
