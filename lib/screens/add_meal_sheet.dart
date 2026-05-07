import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../models/meal_model.dart';
import '../models/recipe_model.dart';
import '../services/recipe_service.dart';
import '../services/meal_service.dart';
import 'create_recipe_screen.dart';

class AddMealSheet extends StatefulWidget {
  final String mealType;

  const AddMealSheet({super.key, required this.mealType});

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

  void _toggleSelect(Recipe recipe) {
    setState(() {
      if (_selected.any((r) => r.id == recipe.id)) {
        _selected.removeWhere((r) => r.id == recipe.id);
      } else {
        _selected.add(recipe);
      }
    });
  }

  void _saveMeals() async {
    if (_selected.isEmpty) return;
    setState(() => _saving = true);

    // Kirim ke API Mockoon
    for (final r in _selected) {
      await MealService.addMeal(
        name: r.name,
        duration: r.duration,
        image: r.image,
        mealType: widget.mealType,
        ingredients: r.ingredients,
      );
    }

    // Buat list Meal dari resep yang dipilih
    final addedMeals = _selected.asMap().entries.map((e) {
      return Meal(
        id: DateTime.now().millisecondsSinceEpoch + e.key,
        name: e.value.name,
        duration: e.value.duration,
        image: e.value.image,
        mealType: widget.mealType,
        ingredients: e.value.ingredients,
      );
    }).toList();

    setState(() => _saving = false);

    if (mounted) {
      // ✅ Return data meal ke home screen
      Navigator.pop(context, addedMeals);
    }
  }

  void _goToCreateRecipe() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateRecipeScreen()),
    );
    // Reload resep setelah buat resep baru
    _loadRecipes();
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

          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.borderColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Judul
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
                  borderSide: BorderSide(color: AppTheme.borderColor),
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
                      final isSelected = _selected.any((s) => s.id == r.id);

                      return GestureDetector(
                        onTap: () => _toggleSelect(r),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.primaryGreen.withOpacity(0.05)
                                : Colors.white,
                            border: Border.all(
                              color: isSelected
                                  ? AppTheme.primaryGreen
                                  : AppTheme.borderColor,
                              width: isSelected ? 1.5 : 1,
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              // Gambar
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: r.image.isNotEmpty
                                    ? Image.network(
                                        r.image,
                                        width: 50,
                                        height: 50,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            _placeholder(),
                                      )
                                    : _placeholder(),
                              ),
                              const SizedBox(width: 12),

                              // Info
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

                              // Checkbox
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppTheme.primaryGreen,
                                  ),
                                  color: isSelected
                                      ? AppTheme.primaryGreen
                                      : Colors.transparent,
                                ),
                                child: isSelected
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
