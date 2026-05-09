import '../models/meal_model.dart';
import '../models/parsed_ingredient.dart';
import '../models/shopping_item.dart';

class ShoppingListBuilder {
  /// Bangun shopping list dari semua schedule.
  /// Bahan yang sama (nama + satuan identik) dijumlahkan otomatis.
  /// Contoh: "500gr daging ayam" + "250gr daging ayam" = 750gr daging ayam
  static Map<String, ShoppingItem> build(
    Map<String, Map<String, List<Meal>>> schedules,
  ) {
    final Map<String, ShoppingItem> result = {};

    for (final daySchedule in schedules.values) {
      for (final meals in daySchedule.values) {
        for (final meal in meals) {
          for (final ingredient in meal.ingredients) {
            final parsed = ParsedIngredient.fromString(ingredient);
            // key unik: nama bahan + satuan agar tidak campur "gr" dan "kg"
            final key = '${parsed.name}|${parsed.unit}';

            if (result.containsKey(key)) {
              result[key]!.totalQty += parsed.qty;
              result[key]!.sources.add(meal.name);
            } else {
              result[key] = ShoppingItem(
                name: parsed.name,
                unit: parsed.unit,
                totalQty: parsed.qty,
                sources: {meal.name},
              );
            }
          }
        }
      }
    }

    // Sort alphabetically berdasarkan nama bahan
    return Map.fromEntries(
      result.entries.toList()
        ..sort((a, b) => a.value.name.compareTo(b.value.name)),
    );
  }
}