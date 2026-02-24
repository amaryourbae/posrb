import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/product.dart';
import '../../core/services/dio_service.dart';
import 'package:flutter/foundation.dart';

class InventoryState {
  final List<Product> items;
  final bool isLoading;
  final String searchQuery;
  final String filter; // 'all' or 'low_stock'

  InventoryState({
    this.items = const [],
    this.isLoading = false,
    this.searchQuery = '',
    this.filter = 'all',
  });

  InventoryState copyWith({
    List<Product>? items,
    bool? isLoading,
    String? searchQuery,
    String? filter,
  }) {
    return InventoryState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      searchQuery: searchQuery ?? this.searchQuery,
      filter: filter ?? this.filter,
    );
  }
}

class InventoryNotifier extends StateNotifier<InventoryState> {
  final Ref ref;

  InventoryNotifier(this.ref) : super(InventoryState());

  Future<void> fetchInventory() async {
    state = state.copyWith(isLoading: true);
    try {
      final dio = ref.read(dioProvider);
      var url = '/admin/pos/inventory?per_page=50';

      if (state.searchQuery.isNotEmpty) {
        url += '&search=${state.searchQuery}';
      }

      if (state.filter == 'low_stock') {
        url += '&low_stock=true';
      }

      final response = await dio.get(url);
      final rawData = response.data['data'] is List
          ? response.data['data']
          : response.data['data']['data']; // Handle pagination structure

      final items = (rawData as List).map((e) => Product.fromJson(e)).toList();
      state = state.copyWith(items: items, isLoading: false);
    } catch (e) {
      debugPrint('Error fetching inventory: $e');
      state = state.copyWith(isLoading: false);
    }
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
    fetchInventory();
  }

  void setFilter(String filter) {
    state = state.copyWith(filter: filter);
    fetchInventory();
  }

  Future<bool> updateInventory(
    String productId,
    Map<String, dynamic> data,
  ) async {
    try {
      final dio = ref.read(dioProvider);
      final response = await dio.put(
        '/admin/pos/inventory/$productId',
        data: data,
      );

      if (response.statusCode == 200) {
        // Update local state
        final updatedProductJson = response.data['data'] ?? response.data;
        final updatedProduct = Product.fromJson(updatedProductJson);

        final newItems = state.items.map((item) {
          return item.id == productId ? updatedProduct : item;
        }).toList();

        state = state.copyWith(items: newItems);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error updating inventory: $e');
      return false;
    }
  }
}

final inventoryProvider =
    StateNotifierProvider<InventoryNotifier, InventoryState>((ref) {
      return InventoryNotifier(ref);
    });
