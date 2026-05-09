class ParsedIngredient {
  final double qty;
  final String unit;
  final String name;
  final String raw;

  ParsedIngredient({
    required this.qty,
    required this.unit,
    required this.name,
    required this.raw,
  });

  /// Parse string ingredient mentah seperti "500gr daging ayam"
  /// menjadi komponen qty, unit, dan name
  factory ParsedIngredient.fromString(String raw) {
    final regex = RegExp(
      r'^(\d+(?:[.,]\d+)?)\s*(kg|gr|g|ml|l|liter|sdm|sdt|buah|siung|lembar|butir|bungkus|sachet|ikat|batang|potong|slice|iris|genggam)?\s*(.+)$',
      caseSensitive: false,
    );
    final match = regex.firstMatch(raw.trim());
    if (match != null) {
      final qty = double.tryParse(
            match.group(1)!.replaceAll(',', '.'),
          ) ??
          1;
      final unit = match.group(2)?.toLowerCase() ?? '';
      final name = match.group(3)!.trim().toLowerCase();
      return ParsedIngredient(qty: qty, unit: unit, name: name, raw: raw);
    }
    // Tidak ada angka → qty=1, no unit
    return ParsedIngredient(
      qty: 1,
      unit: '',
      name: raw.trim().toLowerCase(),
      raw: raw,
    );
  }
}