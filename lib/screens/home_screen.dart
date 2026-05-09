import 'dart:io';
import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../models/meal_model.dart';
import '../services/meal_service.dart';
import '../services/storage_service.dart';
import 'add_meal_sheet.dart';
import 'meal_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedType = 'Breakfast';
  DateTime _selectedDate = DateTime.now();

  Map<String, List<Meal>> _mealStore = {};
  Set<String> _mealKeys = {};
  bool _loading = true;
  int _streak = 0;

  // ✅ Avatar & nama dari storage — sinkron dengan ProfileScreen
  File? _avatarFile;
  String _name = 'User';

  @override
  void initState() {
    super.initState();
    _loadFromStorage();
  }

  Future<void> _loadFromStorage() async {
    setState(() => _loading = true);

    final stored = await StorageService.loadMeals();
    final mealStore = stored.map(
      (k, v) => MapEntry(k, v.map((e) => Meal.fromJson(e)).toList()),
    );
    final streak = await StorageService.calculateStreak();

    // ✅ Baca profile (nama + avatarPath) dari storage
    final profile = await StorageService.loadProfile();
    final avatarPath = profile['avatarPath'] as String?;
    File? avatarFile;
    if (avatarPath != null && avatarPath.isNotEmpty) {
      final f = File(avatarPath);
      avatarFile = f.existsSync() ? f : null;
    }

    setState(() {
      _mealStore = mealStore;
      _mealKeys = mealStore.keys.toSet();
      _streak = streak;
      _name = profile['name'] ?? 'User';
      _avatarFile = avatarFile;
      _loading = false;
    });
  }

  String _dateKey(DateTime date, String type) =>
      StorageService.dateKey(date, type);

  String get _currentKey => _dateKey(_selectedDate, _selectedType);

  List<Meal> get _filtered => _mealStore[_currentKey] ?? [];

  List<String> get _allIngredients {
    final list = <String>[];
    for (final meal in _filtered) {
      list.addAll(meal.ingredients);
    }
    return list;
  }

  List<DateTime> get _weekDays {
    final today = DateTime.now();
    return List.generate(7, (i) => today.subtract(Duration(days: 3 - i)));
  }

  String _dayName(DateTime d) {
    const days = ['Mo', 'Tu', 'Wed', 'Th', 'Fr', 'Sa', 'Su'];
    return days[d.weekday - 1];
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool _hasAnyMeal(DateTime date) {
    return ['Breakfast', 'Lunch', 'Dinner'].any((t) {
      final k = _dateKey(date, t);
      return (_mealStore[k]?.isNotEmpty ?? false);
    });
  }

  void _openAddMeal() async {
    final added = await showModalBottomSheet<List<Meal>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          AddMealSheet(mealType: _selectedType, dateKey: _currentKey),
    );

    if (added != null && added.isNotEmpty) {
      setState(() {
        _mealStore[_currentKey] = [
          ...(_mealStore[_currentKey] ?? []),
          ...added,
        ];
        _mealKeys.add(_currentKey);
      });
      final streak = await StorageService.calculateStreak();
      setState(() => _streak = streak);
    }
  }

  void _deleteMeal(Meal meal) async {
    await MealService.deleteMeal(_currentKey, meal.id);
    setState(() {
      _mealStore[_currentKey]?.removeWhere((m) => m.id == meal.id);
      if (_mealStore[_currentKey]?.isEmpty ?? false) {
        _mealKeys.remove(_currentKey);
      }
    });
    final streak = await StorageService.calculateStreak();
    setState(() => _streak = streak);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadFromStorage,
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    _buildStreakHeader(),
                    const SizedBox(height: 20),
                    _buildCalendar(),
                    const SizedBox(height: 20),
                    _buildMealTabs(),
                    const SizedBox(height: 20),
                    _filtered.isEmpty
                        ? _buildEmptyState()
                        : _buildMealContent(),
                    const SizedBox(height: 24),
                    if (_filtered.isNotEmpty && _allIngredients.isNotEmpty)
                      _buildChecklist(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildStreakHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(50),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8),
            ],
          ),
          child: Row(
            children: [
              const Text('🔥', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Current Streak',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  Text(
                    '$_streak ${_streak == 1 ? 'day' : 'days'}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // ✅ Avatar sinkron dengan ProfileScreen — baca dari storage
        GestureDetector(
          onTap: () {
            // Pull-to-refresh sudah handle sync, tapi bisa juga navigasi ke profile
          },
          child: CircleAvatar(
            radius: 22,
            backgroundColor: AppTheme.borderColor,
            backgroundImage: _avatarFile != null
                ? FileImage(_avatarFile!)
                : null,
            child: _avatarFile == null
                ? const Icon(Icons.person, color: AppTheme.textSecondary)
                : null,
          ),
        ),
      ],
    );
  }

  Widget _buildCalendar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: _weekDays.map((date) {
        final isSelected = _isSameDay(date, _selectedDate);
        final isToday = _isSameDay(date, DateTime.now());
        final hasMeal = _hasAnyMeal(date);

        return GestureDetector(
          onTap: () => setState(() => _selectedDate = date),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 40,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFF3C6E8) : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                Text(
                  '${date.day}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: isSelected
                        ? AppTheme.primaryGreen
                        : AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _dayName(date),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
                    color: isSelected
                        ? AppTheme.primaryGreen
                        : AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: hasMeal ? AppTheme.primaryGreen : Colors.transparent,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMealTabs() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(50),
      ),
      child: Row(
        children: ['Breakfast', 'Lunch', 'Dinner'].map((type) {
          final active = _selectedType == type;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedType = type),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: active ? AppTheme.primaryGreen : Colors.transparent,
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Text(
                  type,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: active ? Colors.white : AppTheme.textSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Column(
      children: [
        GestureDetector(
          onTap: _openAddMeal,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.borderColor),
              borderRadius: BorderRadius.circular(50),
            ),
            child: Text(
              'Add your ${_selectedType.toLowerCase()} meal',
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
              ),
            ),
          ),
        ),
        const SizedBox(height: 32),
        Image.asset(
          'assets/images/empty_plate.png',
          height: 180,
          errorBuilder: (_, __, ___) => const Icon(
            Icons.restaurant,
            size: 80,
            color: AppTheme.borderColor,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Your plate is empty!',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        const SizedBox(height: 4),
        const Text(
          'Tap the button above to add your first meal.',
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildMealContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _selectedType == 'Breakfast'
                        ? 'Sarapan apa kita hari ini?'
                        : _selectedType == 'Lunch'
                        ? 'Makan siang apa hari ini?'
                        : 'Makan malam apa hari ini?',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const Text(
                    'Masak sendiri lebih seru (dan hemat), lho.',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: _openAddMeal,
              child: const Text(
                'Ubah Menu',
                style: TextStyle(
                  color: AppTheme.primaryGreen,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ..._filtered.map((meal) => _buildMealCard(meal)),
      ],
    );
  }

  Widget _buildMealCard(Meal meal) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => MealDetailScreen(meal: meal)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: _buildMealImage(meal.image),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    meal.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    'Estimasi Waktu: ${meal.duration}',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(
                Icons.delete_outline,
                color: Colors.redAccent,
                size: 20,
              ),
              onPressed: () => _deleteMeal(meal),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMealImage(String image) {
    if (image.isEmpty) return _imagePlaceholder();
    if (image.startsWith('http')) {
      return Image.network(
        image,
        width: 54,
        height: 54,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _imagePlaceholder(),
      );
    }
    return Image.file(
      File(image),
      width: 54,
      height: 54,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _imagePlaceholder(),
    );
  }

  Widget _imagePlaceholder() => Container(
    width: 54,
    height: 54,
    color: AppTheme.borderColor,
    child: const Icon(Icons.fastfood, color: AppTheme.textSecondary),
  );

  Widget _buildChecklist() {
    final ingredients = _allIngredients;
    final checked = <int>{};

    return StatefulBuilder(
      builder: (context, setLocal) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Cek dapur dulu, yuk!',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
          const Text(
            'Jangan sampai ada bumbu yang ketinggalan, ya!',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 12),
          ...ingredients.asMap().entries.map((e) {
            final isChecked = checked.contains(e.key);
            return Column(
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => setLocal(
                        () => isChecked
                            ? checked.remove(e.key)
                            : checked.add(e.key),
                      ),
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.primaryGreen),
                          color: isChecked
                              ? AppTheme.primaryGreen
                              : Colors.transparent,
                        ),
                        child: isChecked
                            ? const Icon(
                                Icons.check,
                                size: 12,
                                color: Colors.white,
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        e.value,
                        style: TextStyle(
                          fontSize: 14,
                          color: isChecked
                              ? AppTheme.textSecondary
                              : AppTheme.textPrimary,
                          decoration: isChecked
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 20),
              ],
            );
          }),
        ],
      ),
    );
  }
}
