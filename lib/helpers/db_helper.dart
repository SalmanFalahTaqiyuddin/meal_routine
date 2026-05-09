import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/meal_model.dart';

class DBHelper {
  static Database? _db;

  static Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  static Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'meal_schedule.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE meal_schedule (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            day TEXT NOT NULL,
            meal_type TEXT NOT NULL,
            meal_id INTEGER NOT NULL,
            meal_name TEXT NOT NULL,
            meal_image TEXT,
            meal_duration TEXT,
            meal_ingredients TEXT
          )
        ''');
      },
    );
  }

  /// Tambah meal ke jadwal hari & meal type tertentu
  static Future<int> insertSchedule({
    required String day,
    required String mealType,
    required Meal meal,
  }) async {
    final db = await database;
    return await db.insert(
      'meal_schedule',
      {
        'day': day,
        'meal_type': mealType,
        'meal_id': meal.id,
        'meal_name': meal.name,
        'meal_image': meal.image,
        'meal_duration': meal.duration,
        'meal_ingredients': jsonEncode(meal.ingredients),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Ambil semua meal di hari & meal type tertentu
  static Future<List<Meal>> getMealsByDayAndType({
    required String day,
    required String mealType,
  }) async {
    final db = await database;
    final result = await db.query(
      'meal_schedule',
      where: 'day = ? AND meal_type = ?',
      whereArgs: [day, mealType],
    );

    return result.map((row) {
      final ingredients = row['meal_ingredients'] != null
          ? List<String>.from(jsonDecode(row['meal_ingredients'] as String))
          : <String>[];
      return Meal(
        id: row['meal_id'] as int,
        name: row['meal_name'] as String,
        image: row['meal_image'] as String? ?? '',
        duration: row['meal_duration'] as String? ?? '',
        mealType: mealType,
        ingredients: ingredients,
      );
    }).toList();
  }

  /// Ambil semua jadwal (untuk keperluan overview lengkap)
  static Future<Map<String, Map<String, List<Meal>>>> getAllSchedules() async {
    final db = await database;
    final result = await db.query('meal_schedule');

    // Struktur: { 'Monday': { 'Breakfast': [Meal, ...], ... }, ... }
    Map<String, Map<String, List<Meal>>> schedules = {};

    for (final row in result) {
      final day = row['day'] as String;
      final mealType = row['meal_type'] as String;
      final ingredients = row['meal_ingredients'] != null
          ? List<String>.from(jsonDecode(row['meal_ingredients'] as String))
          : <String>[];

      final meal = Meal(
        id: row['meal_id'] as int,
        name: row['meal_name'] as String,
        image: row['meal_image'] as String? ?? '',
        duration: row['meal_duration'] as String? ?? '',
        mealType: mealType,
        ingredients: ingredients,
      );

      schedules[day] ??= {};
      schedules[day]![mealType] ??= [];
      schedules[day]![mealType]!.add(meal);
    }

    return schedules;
  }

  /// Hapus meal dari jadwal berdasarkan row id
  static Future<void> deleteSchedule(int id) async {
    final db = await database;
    await db.delete('meal_schedule', where: 'id = ?', whereArgs: [id]);
  }

  /// Hapus semua meal di hari & meal type tertentu
  static Future<void> clearDayMealType({
    required String day,
    required String mealType,
  }) async {
    final db = await database;
    await db.delete(
      'meal_schedule',
      where: 'day = ? AND meal_type = ?',
      whereArgs: [day, mealType],
    );
  }
}
