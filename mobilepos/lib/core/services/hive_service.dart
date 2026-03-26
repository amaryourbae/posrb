import 'package:hive_flutter/hive_flutter.dart';
import '../models/product.dart';
import '../models/category.dart';

/// Service to handle all Hive (local storage) operations.
class HiveService {
  static const String productsBox = 'products';
  static const String categoriesBox = 'categories';
  static const String pendingOrdersBox = 'pending_orders';
  static const String settingsBox = 'settings';
  static const String syncQueueBox = 'sync_queue';

  static Future<void> init() async {
    await Hive.initFlutter();

    // Open boxes
    await Hive.openBox<Map>(productsBox);
    await Hive.openBox<Map>(categoriesBox);
    await Hive.openBox<Map>(pendingOrdersBox);
    await Hive.openBox(settingsBox);
    await Hive.openBox<Map>(syncQueueBox);
  }

  // ----- Products -----
  static Box<Map> get _productsBox => Hive.box<Map>(productsBox);

  static Future<void> cacheProducts(List<Product> products) async {
    await _productsBox.clear();
    for (var product in products) {
      await _productsBox.put(product.id, product.toJson());
    }
    await _settingsBox.put(
      'products_last_sync',
      DateTime.now().toIso8601String(),
    );
  }

  static List<Product> getCachedProducts() {
    return _productsBox.values
        .map((json) => Product.fromJson(Map<String, dynamic>.from(json)))
        .toList();
  }

  // ----- Categories -----
  static Box<Map> get _categoriesBox => Hive.box<Map>(categoriesBox);

  static Future<void> cacheCategories(List<Category> categories) async {
    await _categoriesBox.clear();
    for (var category in categories) {
      await _categoriesBox.put(category.id, category.toJson());
    }
    await _settingsBox.put(
      'categories_last_sync',
      DateTime.now().toIso8601String(),
    );
  }

  static List<Category> getCachedCategories() {
    return _categoriesBox.values
        .map((json) => Category.fromJson(Map<String, dynamic>.from(json)))
        .toList();
  }

  // ----- Pending Orders (Offline Orders) -----
  static Box<Map> get _pendingOrdersBox => Hive.box<Map>(pendingOrdersBox);

  static Future<void> savePendingOrder(Map<String, dynamic> orderData) async {
    final String tempId = 'OFF-${DateTime.now().millisecondsSinceEpoch}';
    orderData['temp_id'] = tempId;
    orderData['synced'] = false;
    await _pendingOrdersBox.put(tempId, orderData);
  }

  static List<Map<String, dynamic>> getPendingOrders() {
    return _pendingOrdersBox.values
        .map((e) => Map<String, dynamic>.from(e))
        .where((order) => order['synced'] != true)
        .toList();
  }

  static Future<void> markOrderSynced(String tempId) async {
    final order = _pendingOrdersBox.get(tempId);
    if (order != null) {
      order['synced'] = true;
      await _pendingOrdersBox.put(tempId, order);
    }
  }

  static Future<void> removePendingOrder(String tempId) async {
    await _pendingOrdersBox.delete(tempId);
  }

  // ----- Settings -----
  static Box get _settingsBox => Hive.box(settingsBox);

  static DateTime? getLastSync(String key) {
    final value = _settingsBox.get('${key}_last_sync');
    return value != null ? DateTime.tryParse(value) : null;
  }

  static bool getSoundEnabled() {
    return _settingsBox.get('sound_enabled', defaultValue: true);
  }

  static Future<void> setSoundEnabled(bool enabled) async {
    await _settingsBox.put('sound_enabled', enabled);
  }

  static bool getAutoPrintEnabled() {
    return _settingsBox.get('auto_print_enabled', defaultValue: false);
  }

  static Future<void> setAutoPrintEnabled(bool enabled) async {
    await _settingsBox.put('auto_print_enabled', enabled);
  }

  // ----- Sync Queue -----
  static Box<Map> get _syncQueueBox => Hive.box<Map>(syncQueueBox);

  static Future<void> addToSyncQueue(Map<String, dynamic> request) async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    await _syncQueueBox.put(id, request);
  }

  static List<MapEntry<dynamic, Map<String, dynamic>>> getSyncQueue() {
    return _syncQueueBox
        .toMap()
        .entries
        .map((e) => MapEntry(e.key, Map<String, dynamic>.from(e.value)))
        .toList();
  }

  static Future<void> removeFromSyncQueue(dynamic key) async {
    await _syncQueueBox.delete(key);
  }
}
