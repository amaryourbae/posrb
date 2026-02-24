class ProductHelper {
  /// Get visible modifiers (excluding Size and Available)
  static List<Map<String, dynamic>> getVisibleModifiers(
    List<dynamic> rawModifiers,
  ) {
    return rawModifiers.whereType<Map<String, dynamic>>().where((mod) {
      final name = (mod['modifier_name'] ?? mod['name'] ?? '').toString();
      return !isSizeModifier(name) && !isAvailableModifier(name);
    }).toList();
  }

  static bool isSizeModifier(String name) {
    return name.toLowerCase().contains('size') ||
        name.toLowerCase().contains('porsi');
  }

  static bool isAvailableModifier(String name) {
    return name.toLowerCase().contains('available') ||
        name.toLowerCase().contains('tersedia');
  }

  /// Get formatted display name for a modifier
  static String getModifierDisplayName(Map<String, dynamic> mod) {
    final optName = (mod['option_name'] ?? mod['name'] ?? '').toString();
    final modName = (mod['modifier_name'] ?? mod['name'] ?? '').toString();

    if (modName.isEmpty ||
        isSizeModifier(modName) ||
        isAvailableModifier(modName)) {
      return optName;
    }

    // Handle Ice specifically
    if (modName.toLowerCase().contains('ice')) {
      if (['Normal', 'Less', 'Extra'].contains(optName)) {
        return '$optName Ice';
      }
    }

    // Check if option already contains part of modifier
    final modWords = modName.split(' ');
    for (final word in modWords) {
      if (word.length > 2 &&
          optName.toLowerCase().contains(word.toLowerCase())) {
        return optName;
      }
    }

    // Fallback: Combine
    return '$optName ${modWords.first}';
  }

  /// Get product name with Size and Available prefixes
  static String getFormattedProductName(
    String baseName,
    List<dynamic> rawModifiers,
  ) {
    String name = baseName;
    String sizePrefix = '';
    String availablePrefix = '';

    for (var rawMod in rawModifiers) {
      if (rawMod is! Map<String, dynamic>) continue;
      final mod = rawMod;
      final modName = (mod['modifier_name'] ?? mod['name'] ?? '').toString();
      final optName = (mod['option_name'] ?? mod['name'] ?? '').toString();

      if (isSizeModifier(modName)) sizePrefix = optName;
      if (isAvailableModifier(modName)) availablePrefix = optName;
    }

    if (availablePrefix.isNotEmpty && !name.contains(availablePrefix)) {
      name = "$availablePrefix $name";
    }
    if (sizePrefix.isNotEmpty && !name.contains(sizePrefix)) {
      name = "$sizePrefix $name";
    }

    return name;
  }
}
