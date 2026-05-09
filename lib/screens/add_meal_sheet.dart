import 'dart:io';
import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../models/meal_model.dart';
import '../models/recipe_model.dart';
import '../services/recipe_service.dart';
import '../services/meal_service.dart';
import 'create_recipe_screen.dart';

class AddMealSheet extends StatefulWidget {
  final String mealType;
  final String dateKey;

  const AddMealSheet({
    super.key,
    required this.mealType,
    required this.dateKey,
  });

  @override
  State<AddMealSheet> createState() => _AddMealSheetState();
}

class _AddMealSheetState extends State<AddMealSheet> {
  List<Recipe> _recipes = [];
  final List<Recipe> _selected = [];
  bool _loading = true;
  bool _saving = false;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _loadRecipes();
  }

  Future<void> _loadRecipes() async {
    setState(() => _loading = true);
    final recipes = await RecipeService.getRecipes();
    setState(() {
      _recipes = recipes;
      _loading = false;
    });
  }

  List<Recipe> get _filtered => _recipes
      .where((r) => r.name.toLowerCase().contains(_search.toLowerCase()))
      .toList();

  void _toggleSelect(Recipe r) {
    setState(() {
      _selected.any((s) => s.id == r.id)
          ? _selected.removeWhere((s) => s.id == r.id)
          : _selected.add(r);
    });
  }

  void _saveMeals() async {
    if (_selected.isEmpty) return;
    setState(() => _saving = true);

    final addedMeals = <Meal>[];

    for (int i = 0; i < _selected.length; i++) {
      final r = _selected[i];
      final meal = Meal(
        id: DateTime.now().millisecondsSinceEpoch + i,
        recipeId: r.id, // ✅ simpan id resep asal
        name: r.name,
        duration: r.duration,
        image: r.image,
        mealType: widget.mealType,
        ingredients: r.ingredients,
        steps: r.steps, // ✅ simpan steps
      );

      await MealService.addMeal(
        name: meal.name,
        duration: meal.duration,
        image: meal.image,
        mealType: meal.mealType,
        dateKey: widget.dateKey,
        ingredients: meal.ingredients,
        steps: meal.steps,
        recipeId: meal.recipeId,
      );

      addedMeals.add(meal);
    }

    setState(() => _saving = false);
    if (mounted) Navigator.pop(context, addedMeals);
  }

  void _goToCreateRecipe() async {
    final newRecipe = await Navigator.push<Recipe>(
      context,
      MaterialPageRoute(builder: (_) => const CreateRecipeScreen()),
    );
    if (newRecipe != null) {
      setState(() => _recipes = [..._recipes, newRecipe]);
    }
  }

  Widget _buildRecipeImage(String image) {
    if (image.isEmpty) return _placeholder();
    if (image.startsWith('http')) {
      return Image.network(
        image,
        width: 50,
        height: 50,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(),
      );
    }
    return Image.file(
      File(image),
      width: 50,
      height: 50,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _placeholder(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.borderColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Add ${widget.mealType}',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppTheme.primaryGreen,
            ),
          ),
          const SizedBox(height: 16),

          // Search
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              onChanged: (v) => setState(() => _search = v),
              decoration: InputDecoration(
                hintText: 'Cari makanan...',
                prefixIcon: const Icon(
                  Icons.search,
                  color: AppTheme.textSecondary,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(50),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(50),
                  borderSide: const BorderSide(color: AppTheme.borderColor),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Buat resep sendiri
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: GestureDetector(
              onTap: _goToCreateRecipe,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.borderColor),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text(
                    'Gak ketemu? Buat resepmu sendiri',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // List resep
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.restaurant_menu,
                          size: 48,
                          color: AppTheme.borderColor,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _search.isNotEmpty
                              ? 'Resep "$_search" tidak ditemukan'
                              : 'Belum ada resep tersedia',
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _filtered.length,
                    itemBuilder: (_, i) {
                      final r = _filtered[i];
                      final isSel = _selected.any((s) => s.id == r.id);
                      return GestureDetector(
                        onTap: () => _toggleSelect(r),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isSel
                                ? AppTheme.primaryGreen.withOpacity(0.05)
                                : Colors.white,
                            border: Border.all(
                              color: isSel
                                  ? AppTheme.primaryGreen
                                  : AppTheme.borderColor,
                              width: isSel ? 1.5 : 1,
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: _buildRecipeImage(r.image),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      r.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      'Estimasi Waktu: ${r.duration}',
                                      style: const TextStyle(
                                        color: AppTheme.textSecondary,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppTheme.primaryGreen,
                                  ),
                                  color: isSel
                                      ? AppTheme.primaryGreen
                                      : Colors.transparent,
                                ),
                                child: isSel
                                    ? const Icon(
                                        Icons.check,
                                        size: 14,
                                        color: Colors.white,
                                      )
                                    : null,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // Save button
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: (_selected.isEmpty || _saving) ? null : _saveMeals,
                child: _saving
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        _selected.isEmpty
                            ? 'Pilih makanan dulu'
                            : 'Save Meal (${_selected.length})',
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder() => Container(
    width: 50,
    height: 50,
    color: AppTheme.borderColor,
    child: const Icon(Icons.fastfood, color: AppTheme.textSecondary, size: 20),
  );
}
