import 'package:flutter/foundation.dart';
import '../models/meal_model.dart';
import '../services/storage_service.dart';

class ScheduleProvider extends ChangeNotifier {
  Map<String, Map<String, List<Meal>>> _schedules = {};
  bool _isLoading = false;

  Map<String, Map<String, List<Meal>>> get schedules => _schedules;
  bool get isLoading => _isLoading;

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

  static const Map<int, String> _weekdayToDay = {
    1: 'Monday',
    2: 'Tuesday',
    3: 'Wednesday',
    4: 'Thursday',
    5: 'Friday',
    6: 'Saturday',
    7: 'Sunday',
  };

  Future<void> loadSchedules() async {
    _isLoading = true;

    // PERBAIKAN: Gunakan microtask agar tidak bentrok dengan proses build UI
    Future.microtask(() => notifyListeners());

    final raw = await StorageService.loadMeals();

    // Reset struktur
    final Map<String, Map<String, List<Meal>>> result = {
      for (final day in days) day: {for (final type in mealTypes) type: []},
    };

    for (final entry in raw.entries) {
      final parts = entry.key.split('|');
      if (parts.length != 2) continue;

      final dateStr = parts[0];
      final mealType = parts[1];
      if (!mealTypes.contains(mealType)) continue;

      final dateParts = dateStr.split('-');
      if (dateParts.length != 3) continue;

      final date = DateTime(
        int.parse(dateParts[0]),
        int.parse(dateParts[1]),
        int.parse(dateParts[2]),
      );

      final dayName = _weekdayToDay[date.weekday];
      if (dayName == null) continue;

      final meals = entry.value.map((m) => Meal.fromJson(m)).toList();
      result[dayName]![mealType]!.addAll(meals);
    }

    _schedules = result;
    _isLoading = false;
    notifyListeners();
  }

  List<Meal> getMeals(String day, String mealType) {
    return _schedules[day]?[mealType] ?? [];
  }

  bool hasMealsOnDay(String day) {
    final daySchedule = _schedules[day];
    if (daySchedule == null) return false;
    return mealTypes.any(
      (type) => daySchedule[type] != null && daySchedule[type]!.isNotEmpty,
    );
  }
}
