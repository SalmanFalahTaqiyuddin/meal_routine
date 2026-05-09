import 'dart:io';
import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../models/meal_model.dart';
import '../models/recipe_model.dart';
import '../services/recipe_service.dart';

class MealDetailScreen extends StatefulWidget {
  final Meal meal;
  const MealDetailScreen({super.key, required this.meal});

  @override
  State<MealDetailScreen> createState() => _MealDetailScreenState();
}

class _MealDetailScreenState extends State<MealDetailScreen> {
  Recipe? _recipe;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    // Kalau steps sudah ada langsung pakai
    if (widget.meal.steps.isNotEmpty) {
      setState(() {
        _recipe = Recipe(
          id: widget.meal.id,
          name: widget.meal.name,
          image: widget.meal.image,
          duration: widget.meal.duration,
          ingredients: widget.meal.ingredients,
          steps: widget.meal.steps,
          isCustom: widget.meal.recipeId == null,
        );
        _loading = false;
      });
      return;
    }

    // Cari by recipeId (bukan meal.id yang timestamp)
    final lookupId = widget.meal.recipeId ?? widget.meal.id;
    final recipe = await RecipeService.getRecipeDetail(lookupId);

    setState(() {
      _recipe =
          recipe ??
          Recipe(
            id: widget.meal.id,
            name: widget.meal.name,
            image: widget.meal.image,
            duration: widget.meal.duration,
            ingredients: widget.meal.ingredients,
            steps: const [],
            isCustom: false,
          );
      _loading = false;
    });
  }

  Widget _buildImage(String image) {
    if (image.isEmpty) {
      return Container(
        height: 200,
        color: AppTheme.borderColor,
        child: const Icon(Icons.fastfood, size: 60),
      );
    }
    if (image.startsWith('http')) {
      return Image.network(
        image,
        height: 200,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          height: 200,
          color: AppTheme.borderColor,
          child: const Icon(Icons.fastfood, size: 60),
        ),
      );
    }
    return Image.file(
      File(image),
      height: 200,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        height: 200,
        color: AppTheme.borderColor,
        child: const Icon(Icons.fastfood, size: 60),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(title: Text(widget.meal.name)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _recipe == null
          ? const Center(child: Text('Detail tidak ditemukan'))
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: _buildImage(widget.meal.image),
                ),
                const SizedBox(height: 16),
                Text(
                  widget.meal.name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Estimasi: ${widget.meal.duration}',
                  style: const TextStyle(color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 24),

                // Bahan
                const Text(
                  'Alat & Bahan',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                _recipe!.ingredients.isEmpty
                    ? const Text(
                        'Tidak ada bahan tersedia.',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 14,
                        ),
                      )
                    : Column(
                        children: _recipe!.ingredients
                            .map(
                              (i) => Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.circle,
                                      size: 6,
                                      color: AppTheme.primaryGreen,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        i,
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                      ),
                const SizedBox(height: 24),

                // Langkah
                const Text(
                  'Langkah-langkah',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                _recipe!.steps.isEmpty
                    ? const Text(
                        'Tidak ada langkah tersedia.',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 14,
                        ),
                      )
                    : Column(
                        children: _recipe!.steps
                            .asMap()
                            .entries
                            .map(
                              (e) => Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 6,
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 24,
                                      height: 24,
                                      decoration: const BoxDecoration(
                                        color: AppTheme.primaryGreen,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Text(
                                          '${e.key + 1}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        e.value,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          height: 1.5,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                      ),
                const SizedBox(height: 20),
              ],
            ),
    );
  }
}