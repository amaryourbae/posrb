import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart' hide Category;
import '../services/dio_service.dart';
import '../models/product.dart';
import '../models/category.dart';

class MenuState {
  final List<Product> products;
  final List<Category> categories;
  final bool isLoading;
  final String searchQuery;
  final String activeCategoryId;

  MenuState({
    this.products = const [],
    this.categories = const [],
    this.isLoading = false,
    this.searchQuery = '',
    this.activeCategoryId = 'all',
  });

  MenuState copyWith({
    List<Product>? products,
    List<Category>? categories,
    bool? isLoading,
    String? searchQuery,
    String? activeCategoryId,
  }) {
    return MenuState(
      products: products ?? this.products,
      categories: categories ?? this.categories,
      isLoading: isLoading ?? this.isLoading,
      searchQuery: searchQuery ?? this.searchQuery,
      activeCategoryId: activeCategoryId ?? this.activeCategoryId,
    );
  }
}

class MenuNotifier extends StateNotifier<MenuState> {
  final Ref ref;

  MenuNotifier(this.ref) : super(MenuState());

  Future<void> fetchCategories() async {
    try {
      final dio = ref.read(dioProvider);
      final response = await dio.get('/admin/categories');
      final data = response.data['data'] as List;
      final categories = data.map((e) => Category.fromJson(e)).toList();
      state = state.copyWith(categories: categories);
    } catch (e) {
      debugPrint('Error fetching categories: $e');
    }
  }

  Future<void> fetchProducts() async {
    state = state.copyWith(isLoading: true);
    try {
      final dio = ref.read(dioProvider);
      var url = '/admin/products?per_page=50';

      if (state.searchQuery.isNotEmpty) {
        url += '&search=${state.searchQuery}';
      }

      if (state.activeCategoryId != 'all') {
        url += '&category_id=${state.activeCategoryId}';
      }

      final response = await dio.get(url);
      final data = response.data['data'] is List
          ? response.data['data']
          : response
                .data['data']['data']; // Handle pagination structure if needed

      final products = (data as List).map((e) => Product.fromJson(e)).toList();
      state = state.copyWith(products: products, isLoading: false);
    } catch (e) {
      debugPrint('Error fetching products: $e');
      state = state.copyWith(isLoading: false);
    }
  }

  void setSearchQuery(String query) {
    if (state.searchQuery == query) return;
    state = state.copyWith(searchQuery: query);
    fetchProducts();
  }

  void setActiveCategory(String categoryId) {
    if (state.activeCategoryId == categoryId) return;
    state = state.copyWith(activeCategoryId: categoryId);
    fetchProducts();
  }

  Future<bool> createProduct(Map<String, dynamic> data, File? image) async {
    state = state.copyWith(isLoading: true);
    try {
      final dio = ref.read(dioProvider);

      final formData = FormData.fromMap({
        ...data,
        'is_available': data['is_available'] == true ? 1 : 0,
        if (image != null) 'image': await MultipartFile.fromFile(image.path),
      });

      await dio.post('/admin/products', data: formData);
      await fetchProducts();
      return true;
    } catch (e) {
      debugPrint('Error creating product: $e');
      state = state.copyWith(isLoading: false);
      return false;
    }
  }

  Future<bool> updateProduct(
    String id,
    Map<String, dynamic> data,
    File? image,
  ) async {
    state = state.copyWith(isLoading: true);
    try {
      final dio = ref.read(dioProvider);

      final formData = FormData.fromMap({
        ...data,
        '_method': 'PUT',
        'is_available': data['is_available'] == true ? 1 : 0,
        if (image != null) 'image': await MultipartFile.fromFile(image.path),
      });

      await dio.post('/admin/products/$id', data: formData);
      await fetchProducts();
      return true;
    } catch (e) {
      debugPrint('Error updating product: $e');
      state = state.copyWith(isLoading: false);
      return false;
    }
  }

  Future<bool> deleteProduct(String id) async {
    try {
      final dio = ref.read(dioProvider);
      await dio.delete('/admin/products/$id');
      await fetchProducts();
      return true;
    } catch (e) {
      debugPrint('Error deleting product: $e');
      return false;
    }
  }
}

final menuProvider = StateNotifierProvider<MenuNotifier, MenuState>((ref) {
  return MenuNotifier(ref);
});
