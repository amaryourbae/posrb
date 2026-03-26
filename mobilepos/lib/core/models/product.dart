import 'dart:convert';

class Product {
  final String id;
  final String? categoryId;
  final String name;
  final double price;
  final String? imageUrl;
  final List<Modifier> modifiers;
  final bool? lowStock;
  final String? sku;
  final bool isAvailable;
  final double currentStock;
  final double minimumStockAlert;
  final bool hasRecipe;
  final bool trackStock;
  final double maxYield;
  final Map<String, double> salePrices;

  Product({
    required this.id,
    this.categoryId,
    required this.name,
    required this.price,
    this.imageUrl,
    this.modifiers = const [],
    this.lowStock,
    this.sku,
    this.isAvailable = true,
    this.currentStock = 0,
    this.minimumStockAlert = 0,
    this.hasRecipe = false,
    this.trackStock = false,
    this.maxYield = 0,
    this.salePrices = const {},
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    final Map<String, double> salePricesMap = {};
    if (json['sale_prices'] != null) {
      for (var sp in (json['sale_prices'] as List)) {
        final slug = sp['slug']?.toString();
        final priceRaw = sp['pivot']?['price'];
        if (slug != null && priceRaw != null) {
          salePricesMap[slug] = double.tryParse(priceRaw.toString()) ?? 0.0;
        }
      }
    }

    return Product(
      id: json['id'].toString(),
      categoryId: json['category_id']?.toString(),
      name: json['name'],
      price: double.tryParse(json['price'].toString()) ?? 0.0,
      imageUrl: json['image_url'] ?? json['image'],
      lowStock: json['lowStock'],
      sku: json['sku'],
      isAvailable: json['is_available'] == 1 || json['is_available'] == true,
      currentStock: double.tryParse(json['current_stock'].toString()) ?? 0.0,
      minimumStockAlert:
          double.tryParse(json['minimum_stock_alert'].toString()) ?? 0.0,
      hasRecipe: json['has_recipe'] == 1 || json['has_recipe'] == true,
      trackStock: json['track_stock'] == 1 || json['track_stock'] == true,
      maxYield: double.tryParse(json['max_yield']?.toString() ?? '0') ?? 0.0,
      modifiers:
          (json['modifiers'] as List<dynamic>?)
              ?.map((e) => Modifier.fromJson(e))
              .toList() ??
          [],
      salePrices: salePricesMap,
    );
  }

  double getPriceForSalesType(String? slug) {
    if (slug == null) return price;
    return salePrices[slug] ?? price;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'category_id': categoryId,
    'name': name,
    'price': price,
    'image_url': imageUrl,
    'lowStock': lowStock,
    'sku': sku,
    'is_available': isAvailable,
    'current_stock': currentStock,
    'minimum_stock_alert': minimumStockAlert,
    'has_recipe': hasRecipe,
    'track_stock': trackStock,
    'max_yield': maxYield,
    'modifiers': modifiers.map((m) => m.toJson()).toList(),
    'sale_prices_map': salePrices, // Simple map for local storage
  };
}

class Modifier {
  final String id;
  final String name;
  final String type;
  final bool isRequired;
  final List<ModifierOption> options;
  final String? conditionModifierId;
  final String? conditionOptionId;
  final List<String>? allowedOptions;

  Modifier({
    required this.id,
    required this.name,
    required this.type,
    required this.isRequired,
    this.options = const [],
    this.conditionModifierId,
    this.conditionOptionId,
    this.allowedOptions,
  });

  factory Modifier.fromJson(Map<String, dynamic> json) {
    final pivot = json['pivot'];
    return Modifier(
      id: json['id'].toString(),
      name: json['name'],
      type: json['type'],
      isRequired: json['is_required'] == 1 || json['is_required'] == true,
      options:
          (json['options'] as List<dynamic>?)
              ?.map((e) => ModifierOption.fromJson(e))
              .toList() ??
          [],
      conditionModifierId: pivot?['condition_modifier_id']?.toString(),
      conditionOptionId: pivot?['condition_option_id']?.toString(),
      allowedOptions: _parseAllowedOptions(pivot?['allowed_options']),
    );
  }

  static List<String>? _parseAllowedOptions(dynamic value) {
    if (value == null) return null;
    if (value is List) return value.map((e) => e.toString()).toList();
    if (value is String) {
      if (value.isEmpty) return null;
      try {
        final decoded = jsonDecode(value);
        if (decoded is List) {
          return decoded.map((e) => e.toString()).toList();
        }
      } catch (_) {}
    }
    return null;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type,
    'is_required': isRequired,
    'options': options.map((o) => o.toJson()).toList(),
    'pivot': {
      'condition_modifier_id': conditionModifierId,
      'condition_option_id': conditionOptionId,
      'allowed_options': allowedOptions,
    },
  };
}

class ModifierOption {
  final String id;
  final String name;
  final double price;
  final Map<String, double> salePrices;

  ModifierOption({
    required this.id,
    required this.name,
    required this.price,
    this.salePrices = const {},
  });

  factory ModifierOption.fromJson(Map<String, dynamic> json) {
    final Map<String, double> salePricesMap = {};
    if (json['sale_prices'] != null) {
      for (var sp in (json['sale_prices'] as List)) {
        final slug = sp['slug']?.toString();
        final priceRaw = sp['pivot']?['price'];
        if (slug != null && priceRaw != null) {
          salePricesMap[slug] = double.tryParse(priceRaw.toString()) ?? 0.0;
        }
      }
    }

    return ModifierOption(
      id: json['id'].toString(),
      name: json['name'],
      price: double.tryParse(json['price'].toString()) ?? 0.0,
      salePrices: salePricesMap,
    );
  }

  double getPriceForSalesType(String? slug) {
    if (slug == null) return price;
    return salePrices[slug] ?? price;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'price': price,
    'sale_prices_map': salePrices,
  };
}
