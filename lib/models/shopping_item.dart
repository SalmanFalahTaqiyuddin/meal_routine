class ShoppingItem {
  final String name;
  final String unit;
  double totalQty;
  Set<String> sources;

  ShoppingItem({
    required this.name,
    required this.unit,
    required this.totalQty,
    required this.sources,
  });

  /// Tampilkan qty tanpa desimal kalau bulat, misal 500 bukan 500.0
  String get displayQty {
    if (totalQty == totalQty.roundToDouble()) {
      return totalQty.toInt().toString();
    }
    return totalQty.toStringAsFixed(1);
  }

  /// Capitalize huruf pertama nama bahan
  String get displayName {
    if (name.isEmpty) return name;
    return name[0].toUpperCase() + name.substring(1);
  }

  /// Label lengkap qty + satuan, misal "500 gr" atau "3" kalau tidak ada satuan
  String get displayAmount {
    return unit.isEmpty ? displayQty : '$displayQty $unit';
  }
}