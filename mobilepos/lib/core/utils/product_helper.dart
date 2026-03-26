class ProductHelper {


  static List<dynamic> getVisibleModifiers(List<dynamic> modifiers) {
    if (modifiers.isEmpty) return [];
    return modifiers.where((m) {
      final name = (m['name'] ?? m['modifier_name'] ?? '').toString().toLowerCase();
      final optName = (m['option_name'] ?? '').toString();
      
      // Heuristic fallback for old orders without modifier_name attached
      if (name.isEmpty) {
        if (['Iced', 'Hot'].contains(optName)) return false;
        if (['Reguler', 'Large', 'Small', 'Regular'].contains(optName)) return false;
      }

      // Hide 'Available' (Iced/Hot) and 'Size/Ukuran' since they are merged into product name
      return name != 'available' && name != 'size' && name != 'ukuran';
    }).toList();
  }

  /// Returns product name with modifiers (e.g. "Iced Americano")
  static String getFormattedProductName(String baseName, List<dynamic> modifiers) {
    String finalName = baseName;

    if (modifiers.isEmpty) return finalName;

    // Prepend 'Available' modifier (Iced/Hot)
    final availableMod = modifiers.firstWhere(
      (m) => (m['name'] ?? m['modifier_name'] ?? '').toString().toLowerCase() == 'available',
      orElse: () => null,
    );

    if (availableMod != null) {
      final option = availableMod['option_name'] ?? '';
      if (option.isNotEmpty) {
        finalName = "$option $finalName";
      }
    }

    // Append 'Size'/'Ukuran' modifier (Reguler/Large)
    final sizeMod = modifiers.firstWhere(
      (m) {
        final n = (m['name'] ?? m['modifier_name'] ?? '').toString().toLowerCase();
        return n == 'size' || n == 'ukuran';
      },
      orElse: () => null,
    );

    if (sizeMod != null) {
      final option = sizeMod['option_name'] ?? '';
      if (option.isNotEmpty) {
        finalName = "$finalName $option";
      }
    }

    return finalName;
  }

  /// Returns a clean display name for a modifier (e.g. "Normal Ice", "Reguler Size")
  static String getModifierDisplayName(dynamic modifier) {
    final option = modifier['option_name'] ?? '';
    final name = modifier['name'] ?? modifier['modifier_name'] ?? '';

    if (name == 'Available') return option;

    // Special case: just show option for certain categories if they already sound complete
    if (name == 'Dairy') return option;

    // If option already contains the category name, just return option
    // (e.g. "Less Ice" already contains "Ice")
    final modWords = name.split(' ');
    for (final word in modWords) {
      if (word.length > 2 && option.toLowerCase().contains(word.toLowerCase())) {
        return option;
      }
    }

    // Combine: "Normal" + "Ice Cube" -> "Normal Ice"
    // Use first word of category for cleaner display
    final modShort = modWords.first;
    return '$option $modShort';
  }
}
