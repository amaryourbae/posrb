class CartItem {
  final String cartId;
  final String productId;
  final String name;
  final double basePrice;
  final double unitPrice;
  final int quantity;
  final List<CartModifier> modifiers;
  final String? note;
  final String? imageUrl;

  CartItem({
    required this.cartId,
    required this.productId,
    required this.name,
    required this.basePrice,
    required this.unitPrice,
    required this.quantity,
    this.modifiers = const [],
    this.note,
    this.imageUrl,
  });

  double get totalPrice => unitPrice * quantity;

  CartItem copyWith({int? quantity}) {
    return CartItem(
      cartId: cartId,
      productId: productId,
      name: name,
      basePrice: basePrice,
      unitPrice: unitPrice,
      quantity: quantity ?? this.quantity,
      modifiers: modifiers,
      note: note,
      imageUrl: imageUrl,
    );
  }
}

class CartModifier {
  final String modifierId;
  final String optionId;
  final String name;
  final String optionName;
  final double price;
  final bool showInUi;

  CartModifier({
    required this.modifierId,
    required this.optionId,
    required this.name,
    required this.optionName,
    required this.price,
    this.showInUi = true,
  });

  /// Returns display name like "Normal Ice" instead of just "Normal"
  /// Combines optionName with modifier name for barista clarity
  String get displayName {
    final opt = optionName;
    final mod = name;

    // Skip "Available" modifier (handled separately for product name)
    if (mod == 'Available') return opt;

    // Special case for Dairy: just show option (e.g. "Oat Milk", not "Oat Milk Dairy")
    if (mod == 'Dairy') return opt;

    // If option already contains part of modifier, return as-is
    // e.g., "Less Ice" already has "Ice" in it
    final modWords = mod.split(' ');
    for (final word in modWords) {
      if (word.length > 2 && opt.toLowerCase().contains(word.toLowerCase())) {
        return opt;
      }
    }

    // Combine: "Normal" + "Ice Cube" → "Normal Ice"
    // Use first word of modifier for cleaner display
    final modShort = modWords.first;
    return '$opt $modShort';
  }
}
