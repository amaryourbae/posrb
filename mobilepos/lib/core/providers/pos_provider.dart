import 'package:flutter/foundation.dart' hide Category;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../models/product.dart';
import '../models/cart_item.dart';
import '../models/category.dart';
import '../models/customer.dart';
import '../models/discount.dart';
import '../services/dio_service.dart';
import '../services/hive_service.dart';
import '../models/sales_type.dart';
import '../services/sync_service.dart';

// State class for POS
class PosState {
  final bool loading;
  final List<Product> products;
  final List<Category> categories;
  final List<Discount> discounts;
  final List<CartItem> cart;
  final List<Customer> customers;
  final String? error;
  final double taxRate;
  final double serviceChargeRate;
  final String? currentOrderNumber;
  final String? currentOrderId;
  final int pendingCount;
  final List<SalesType> salesTypes;
  final SalesType? selectedSalesType;
  final Map<String, dynamic> settings;

  // selections
  final String? selectedCategoryId;
  final Customer? selectedCustomer;
  final Discount? activeDiscount;
  final String orderType;
  final String searchQuery;
  final Map<String, dynamic>? shift;
  final bool isShiftModalOpen;
  final String shiftModalMode;

  // UI State
  final bool isPendingBillsOpen;
  final bool isDiscountModalOpen;
  final bool isCartOpen;
  final bool isCashMovementModalOpen;
  final List<String> unseenOrderIds;
  final int offlinePendingCount;
  final List<CartItem> originalCart;

  PosState({
    this.loading = false,
    this.products = const [],
    this.categories = const [],
    this.discounts = const [],
    this.cart = const [],
    this.customers = const [],
    this.error,
    this.taxRate = 10.0,
    this.serviceChargeRate = 0.0,
    this.currentOrderNumber,
    this.currentOrderId,
    this.selectedCategoryId,
    this.selectedCustomer,
    this.activeDiscount,
    this.orderType = 'Dine In',
    this.searchQuery = '',
    this.isPendingBillsOpen = false,
    this.isDiscountModalOpen = false,
    this.isCartOpen = false,
    this.shift,
    this.isShiftModalOpen = false,
    this.shiftModalMode = 'start',
    this.pendingCount = 0,
    this.isCashMovementModalOpen = false,
    this.salesTypes = const [],
    this.selectedSalesType,
    this.unseenOrderIds = const [],
    this.offlinePendingCount = 0,
    this.originalCart = const [],
    this.settings = const {},
  });

  PosState copyWith({
    bool? loading,
    List<Product>? products,
    List<Category>? categories,
    List<CartItem>? cart,
    List<Customer>? customers,
    String? error,
    double? taxRate,
    double? serviceChargeRate,
    String? selectedCategoryId,
    Customer? selectedCustomer,
    Discount? activeDiscount,
    String? orderType,
    String? searchQuery,
    bool? isPendingBillsOpen,
    bool? isDiscountModalOpen,
    bool? isCartOpen,
    bool clearCustomer = false,
    bool clearCategory = false,
    bool clearDiscount = false,
    List<Discount>? discounts,
    String? currentOrderNumber,
    bool clearOrderNumber = false,
    String? currentOrderId,
    bool? clearOrderId = false,
    Map<String, dynamic>? shift,
    bool clearShift = false,
    bool? isShiftModalOpen,
    String? shiftModalMode,
    int? pendingCount,
    bool? isCashMovementModalOpen,
    List<SalesType>? salesTypes,
    SalesType? selectedSalesType,
    bool clearSalesType = false,
    List<String>? unseenOrderIds,
    int? offlinePendingCount,
    List<CartItem>? originalCart,
    Map<String, dynamic>? settings,
  }) {
    return PosState(
      loading: loading ?? this.loading,
      products: products ?? this.products,
      categories: categories ?? this.categories,
      discounts: discounts ?? this.discounts,
      cart: cart ?? this.cart,
      customers: customers ?? this.customers,
      error: error,
      taxRate: taxRate ?? this.taxRate,
      serviceChargeRate: serviceChargeRate ?? this.serviceChargeRate,
      currentOrderNumber: clearOrderNumber
          ? null
          : (currentOrderNumber ?? this.currentOrderNumber),
      currentOrderId: (clearOrderId == true)
          ? null
          : (currentOrderId ?? this.currentOrderId),
      selectedCategoryId: clearCategory
          ? null
          : (selectedCategoryId ?? this.selectedCategoryId),
      selectedCustomer: clearCustomer
          ? null
          : (selectedCustomer ?? this.selectedCustomer),
      activeDiscount: clearDiscount
          ? null
          : (activeDiscount ?? this.activeDiscount),
      orderType: orderType ?? this.orderType,
      searchQuery: searchQuery ?? this.searchQuery,
      isPendingBillsOpen: isPendingBillsOpen ?? this.isPendingBillsOpen,
      isDiscountModalOpen: isDiscountModalOpen ?? this.isDiscountModalOpen,
      isCartOpen: isCartOpen ?? this.isCartOpen,
      shift: clearShift ? null : (shift ?? this.shift),
      isShiftModalOpen: isShiftModalOpen ?? this.isShiftModalOpen,
      shiftModalMode: shiftModalMode ?? this.shiftModalMode,
      pendingCount: pendingCount ?? this.pendingCount,
      isCashMovementModalOpen:
          isCashMovementModalOpen ?? this.isCashMovementModalOpen,
      salesTypes: salesTypes ?? this.salesTypes,
      selectedSalesType: clearSalesType
          ? null
          : (selectedSalesType ?? this.selectedSalesType),
      unseenOrderIds: unseenOrderIds ?? this.unseenOrderIds,
      offlinePendingCount: offlinePendingCount ?? this.offlinePendingCount,
      originalCart: originalCart ?? this.originalCart,
      settings: settings ?? this.settings,
    );
  }

  double get subTotal => cart.fold(0, (sum, item) => sum + item.totalPrice);

  double get discountAmount {
    if (activeDiscount == null) return 0;

    // Validate min purchase
    if (activeDiscount!.minPurchase > 0 &&
        subTotal < activeDiscount!.minPurchase) {
      return 0;
    }

    if (activeDiscount!.type == 'fixed') {
      return activeDiscount!.value > subTotal
          ? subTotal
          : activeDiscount!.value;
    } else {
      return subTotal * (activeDiscount!.value / 100);
    }
  }

  double get serviceCharge {
    final baseAmount = (subTotal - discountAmount) > 0
        ? (subTotal - discountAmount)
        : 0.0;
    return baseAmount * (serviceChargeRate / 100);
  }

  double get tax {
    final taxableAmount = (subTotal - discountAmount + serviceCharge) > 0
        ? (subTotal - discountAmount + serviceCharge)
        : 0.0;
    return taxableAmount * (taxRate / 100);
  }

  double get total => (subTotal - discountAmount + serviceCharge + tax) > 0
      ? (subTotal - discountAmount + serviceCharge + tax)
      : 0;

  // Filtered Products Getter
  List<Product> get filteredProducts {
    return products.where((product) {
      final matchesCategory =
          selectedCategoryId == null ||
          product.categoryId == selectedCategoryId;
      final matchesSearch =
          searchQuery.isEmpty ||
          product.name.toLowerCase().contains(searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();
  }
}

// Controller
class PosNotifier extends StateNotifier<PosState> {
  final Dio dio;

  PosNotifier(this.dio) : super(PosState()) {
    SyncService().init(dio); // Initialize background sync service
    
    // Listen to sync queue changes to update pending count or trigger data refresh
    SyncService().pendingCountStream.listen((count) {
       if (mounted) {
         state = state.copyWith(offlinePendingCount: count);
       }
    });
    
    fetchInitialData();
  }

  Future<void> fetchInitialData() async {
    state = state.copyWith(loading: true);
    try {
      await Future.wait([
        fetchProducts(),
        fetchCategories(),
        fetchDiscounts(),
        fetchSettings(),
        fetchCurrentShift(),
        fetchPendingCount(),
        fetchSalesTypes(),
      ]);
      
      // Initial offline count
      state = state.copyWith(
        loading: false,
        offlinePendingCount: HiveService.getPendingOrders().length,
      );
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  Future<void> fetchSettings() async {
    try {
      final response = await dio.get('/public/settings');
      dynamic data = response.data;

      // Unwrap
      if (data is Map<String, dynamic> && data.containsKey('data')) {
        data = data['data'];
      }

      if (data is Map) {
        final taxRate =
            double.tryParse(data['tax_rate']?.toString() ?? '10') ?? 10.0;
        final serviceRate =
            double.tryParse(data['service_charge_rate']?.toString() ?? '0') ??
            0.0;

        state = state.copyWith(
          taxRate: taxRate,
          serviceChargeRate: serviceRate,
          settings: data as Map<String, dynamic>,
        );
      }
    } catch (e) {
      // Use default settings if fail
    }
  }

  Future<void> fetchProducts() async {
    try {
      final response = await dio.get('/admin/products?per_page=200');
      // Handle different response formats (List, Paginated Object, Standard Wrapper)
      List data = [];
      final resData = response.data;

      if (resData is List) {
        data = resData;
      } else if (resData is Map) {
        if (resData['success'] == true && resData['data'] != null) {
          // Standard Wrapper
          final wrappedData = resData['data'];
          if (wrappedData is List) {
            data = wrappedData;
          } else if (wrappedData is Map && wrappedData['data'] != null) {
            // Paginated inside wrapper
            data = wrappedData['data'];
            // Could also access wrappedData['current_page'] etc
          }
        } else if (resData['data'] != null) {
          // Legacy Paginated or simple wrapper
          final nestedData = resData['data'];
          if (nestedData is List) {
            data = nestedData;
          } else if (nestedData is Map && nestedData['data'] != null) {
            // Double nested? (Wrapper -> Paginator -> Items)
            data = nestedData['data'];
          }
        }
      }

      final products = data.map((e) => Product.fromJson(e)).toList();
      state = state.copyWith(products: products);

      // Cache to Hive for offline use
      await HiveService.cacheProducts(products);
    } catch (e) {
      // Try to load from cache on failure
      final cached = HiveService.getCachedProducts();
      if (cached.isNotEmpty) {
        state = state.copyWith(
          products: cached,
          error: 'Offline: Using cached data',
        );
      } else {
        state = state.copyWith(error: 'Failed to load products: $e');
      }
    }
  }

  Future<void> fetchCategories() async {
    try {
      final response = await dio.get('/admin/categories');
      // Handle different response formats
      List data = [];
      dynamic resData = response.data;

      // Unwrap
      if (resData is Map<String, dynamic> && resData.containsKey('data')) {
        resData = resData['data'];
      }

      if (resData is List) {
        data = resData;
      }
      final categories = data.map((e) => Category.fromJson(e)).toList();
      state = state.copyWith(categories: categories);

      // Cache to Hive for offline use
      await HiveService.cacheCategories(categories);
    } catch (e) {
      // Try to load from cache on failure
      final cached = HiveService.getCachedCategories();
      if (cached.isNotEmpty) {
        state = state.copyWith(categories: cached);
      } else {
        state = state.copyWith(error: 'Failed to load categories: $e');
      }
    }
  }

  Future<void> fetchDiscounts() async {
    try {
      final response = await dio.get('/public/promos');
      List data;
      if (response.data is List) {
        data = response.data;
      } else {
        data = [];
      }
      final discounts = data.map((e) => Discount.fromJson(e)).toList();
      state = state.copyWith(discounts: discounts);
    } catch (e) {
      debugPrint('Error fetching pending count: $e');
    }
  }

  Future<void> fetchSalesTypes() async {
    try {
      final response = await dio.get('/admin/sales-types');
      if (response.data['status'] == 'success') {
        final List data = response.data['data'];
        final types = data.map((e) => SalesType.fromJson(e)).toList();
        state = state.copyWith(salesTypes: types);

        // Auto-select Dine In or first active
        if (state.selectedSalesType == null && types.isNotEmpty) {
          final def = types.firstWhere(
            (t) => t.slug == 'dine_in',
            orElse: () => types.first,
          );
          setSalesType(def);
        }
      }
    } catch (e) {
      debugPrint('Error fetching sales types: $e');
    }
  }

  Future<List<Customer>> searchCustomers(String query) async {
    if (query.isEmpty) {
      // state = state.copyWith(customers: []); // Avoid state update
      return [];
    }

    try {
      final response = await dio.get(
        '/admin/customers',
        queryParameters: {'search': query},
      );

      dynamic rawData = response.data;
      List data = [];

      // Handle wrapper
      if (rawData is Map<String, dynamic> && rawData.containsKey('data')) {
        rawData = rawData['data']; // First level

        // Handle Pagination inside
        if (rawData is Map<String, dynamic> && rawData.containsKey('data')) {
          rawData = rawData['data'];
        }
      }

      if (rawData is List) {
        data = rawData;
      }

      final customers = data.map((e) => Customer.fromJson(e)).toList();
      // state = state.copyWith(customers: customers); // Avoid state update to prevent Autocomplete crash
      return customers;
    } catch (e) {
      // debugPrint("Customer search error: $e");
      return [];
    }
  }

  /// Search customers and update state (for synchronous Autocomplete pattern)
  void searchCustomersAndUpdateState(String query) async {
    if (query.isEmpty) {
      state = state.copyWith(customers: []);
      return;
    }

    try {
      final response = await dio.get(
        '/admin/customers',
        queryParameters: {'search': query},
      );

      dynamic rawData = response.data;
      List data = [];

      if (rawData is Map<String, dynamic> && rawData.containsKey('data')) {
        rawData = rawData['data'];
        if (rawData is Map<String, dynamic> && rawData.containsKey('data')) {
          rawData = rawData['data'];
        }
      }

      if (rawData is List) {
        data = rawData;
      }

      final customers = data.map((e) => Customer.fromJson(e)).toList();
      state = state.copyWith(customers: customers);
    } catch (e) {
      // Silent fail
    }
  }

  void addUnseenOrderId(String id) {
    if (!state.unseenOrderIds.contains(id)) {
      state = state.copyWith(unseenOrderIds: [...state.unseenOrderIds, id]);
    }
  }

  void markOrderAsSeen(String id) {
    if (state.unseenOrderIds.contains(id)) {
      state = state.copyWith(
        unseenOrderIds: state.unseenOrderIds
            .where((orderId) => orderId != id)
            .toList(),
      );
    }
  }

  void selectCategory(String? categoryId) {
    state = state.copyWith(
      selectedCategoryId: categoryId,
      clearCategory: categoryId == null,
    );
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void selectCustomer(Customer? customer) {
    state = state.copyWith(
      selectedCustomer: customer,
      clearCustomer: customer == null,
    );
  }

  void setOrderType(String type) {
    state = state.copyWith(orderType: type);
    // Find matching sales type by name
    try {
      final matching = state.salesTypes.firstWhere(
        (t) => t.name.toLowerCase() == type.toLowerCase(),
      );
      setSalesType(matching);
    } catch (_) {
      // If no match, keep current selectedSalesType
    }
  }

  void setSalesType(SalesType? type) {
    if (type == null) {
      state = state.copyWith(clearSalesType: true);
      return;
    }

    state = state.copyWith(selectedSalesType: type, orderType: type.name);

    // If there's items in cart, update their prices according to new sales type
    if (state.cart.isNotEmpty) {
      final newCart = state.cart.map((item) {
        final product = state.products.firstWhere(
          (p) => p.id == item.productId,
        );
        final newBasePrice = product.getPriceForSalesType(type.slug);

        // Update modifier prices for the new sales type
        final newModifiers = item.modifiers.map((m) {
          try {
            final modifier = product.modifiers.firstWhere(
              (mod) => mod.id == m.modifierId,
            );
            final option = modifier.options.firstWhere(
              (opt) => opt.id == m.optionId,
            );
            return m.copyWith(price: option.getPriceForSalesType(type.slug));
          } catch (_) {
            return m;
          }
        }).toList();

        final modifiersTotal = newModifiers.fold<double>(
          0.0,
          (sum, m) => sum + m.price,
        );

        return item.copyWith(
          basePrice: newBasePrice,
          unitPrice: newBasePrice + modifiersTotal,
          modifiers: newModifiers,
        );
      }).toList();
      state = state.copyWith(cart: newCart);
    }
  }

  void addToCart(
    Product product, {
    int quantity = 1,
    List<CartModifier> modifiers = const [],
    String? note,
  }) {
    if (state.shift == null) {
      toggleShiftModal(true, 'start');
      return;
    }

    final cartModifiers = modifiers.map((mod) {
      // Only hide "Available" (used for Iced/Hot prefix in product name)
      bool showInUi = mod.name != 'Available';

      // Re-resolve the price based on current sales type to be sure
      double resolvedPrice = mod.price;
      try {
        final modifier = product.modifiers.firstWhere(
          (m) => m.id == mod.modifierId,
        );
        final option = modifier.options.firstWhere((o) => o.id == mod.optionId);
        resolvedPrice = option.getPriceForSalesType(
          state.selectedSalesType?.slug,
        );
      } catch (_) {}

      return CartModifier(
        modifierId: mod.modifierId,
        optionId: mod.optionId,
        name: mod.name,
        optionName: mod.optionName,
        price: resolvedPrice,
        showInUi: showInUi,
      );
    }).toList();

    // Calculate unit price from transformed modifiers
    double basePriceValue = product.getPriceForSalesType(
      state.selectedSalesType?.slug,
    );
    double unitPrice = basePriceValue;
    for (var mod in cartModifiers) {
      unitPrice += mod.price;
    }

    // Generate Hash for uniqueness
    final modIds =
        cartModifiers.map((e) => "${e.modifierId}:${e.optionId}").toList()
          ..sort();
    final modKey = modIds.join('-');
    final cartId = modKey.isEmpty ? product.id : "${product.id}-$modKey";

    final existingIndex = state.cart.indexWhere(
      (item) => item.cartId == cartId,
    );

    List<CartItem> newCart;
    if (existingIndex >= 0) {
      newCart = List.from(state.cart);
      final existing = newCart[existingIndex];
      newCart[existingIndex] = existing.copyWith(
        quantity: existing.quantity + quantity,
      );
    } else {
      String finalName = product.name;
      final availableMod = cartModifiers.firstWhere(
        (m) => (m.name == 'Available' || m.name == 'Jenis'),
        orElse: () => CartModifier(
          modifierId: '',
          optionId: '',
          name: '',
          optionName: '',
          price: 0,
        ),
      );

      if (availableMod.name.isNotEmpty && availableMod.optionName.isNotEmpty) {
        finalName = "${availableMod.optionName} ${product.name}";
      }

      // Add new
      newCart = [
        ...state.cart,
        CartItem(
          cartId: cartId,
          productId: product.id,
          name: finalName,
          basePrice: basePriceValue,
          unitPrice: unitPrice,
          quantity: quantity,
          modifiers: cartModifiers,
          note: note,
          imageUrl: product.imageUrl,
        ),
      ];
    }

    state = state.copyWith(cart: newCart);
  }

  void updateQuantity(String cartId, int newQty) {
    if (newQty <= 0) {
      removeFromCart(cartId);
      return;
    }
    final newCart = state.cart.map((item) {
      if (item.cartId == cartId) {
        return item.copyWith(quantity: newQty);
      }
      return item;
    }).toList();
    state = state.copyWith(cart: newCart);
  }

  void removeFromCart(String cartId) {
    final newCart = state.cart.where((item) => item.cartId != cartId).toList();
    state = state.copyWith(cart: newCart);
  }

  Future<void> checkout({
    required String paymentMethod,
    required double amountPaid,
  }) async {
    if (state.cart.isEmpty) {
      throw Exception("Cart is empty");
    }

    state = state.copyWith(loading: true);

    try {
      // Normalize order type string
      final apiOrderType = state.orderType.toLowerCase().replaceAll(' ', '_');

      final orderData = {
        'items': state.cart.map((item) {
          return {
            'product_id': item.productId,
            'name': item.name,
            'quantity': item.quantity,
            'unit_price': item.unitPrice,
            'total_price': item.totalPrice,
            'note': item.note,
            'modifiers': item.modifiers.map((mod) {
              return {
                'modifier_id': mod.modifierId,
                'modifier_option_id': mod.optionId,
                'price': mod.price,
                'name': mod.name,
                'option_name': mod.optionName,
              };
            }).toList(),
          };
        }).toList(),
        'subtotal': state.subTotal,
        'tax': state.tax,
        'service_charge': state.serviceCharge,
        'grand_total': state.total,

        // Discount fields
        'discount_id': state.activeDiscount?.id,
        'discount_amount': state.discountAmount,

        'payment_method': paymentMethod,
        'amount_paid': amountPaid,
        'change': amountPaid - state.total,
        'order_type': apiOrderType,
        'sales_type_id': state.selectedSalesType?.id,
        'payment_status': 'paid',
        'customer_name': state.selectedCustomer?.name ?? 'Walk-in Customer',
        'customer_id': state.selectedCustomer?.isGuest == true
            ? null
            : state.selectedCustomer?.id,
        // Add timestamp for offline tracking
        'created_at': DateTime.now().toIso8601String(),
      };

      await dio.post('/orders', data: orderData);

      // Clear cart on success
      clearCart();
      selectCustomer(null);

      state = state.copyWith(loading: false);
    } catch (e) {
      bool isNetworkError = false;

      if (e is DioException) {
        if (e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout ||
            e.type == DioExceptionType.sendTimeout ||
            e.type == DioExceptionType.connectionError ||
            e.type == DioExceptionType.unknown) {
          isNetworkError = true;
        }
      }

      if (isNetworkError) {
        // Fallback to offline storage
        debugPrint('Network error during checkout. Saving order offline.');

        // Regenerate orderData for offline (needs same format as try block)
        final apiOrderType = state.orderType.toLowerCase().replaceAll(' ', '_');
        final orderData = {
          'items': state.cart.map((item) {
            return {
              'product_id': item.productId,
              'name': item.name,
              'quantity': item.quantity,
              'unit_price': item.unitPrice,
              'total_price': item.totalPrice,
              'note': item.note,
              'modifiers': item.modifiers.map((mod) {
                return {
                  'modifier_id': mod.modifierId,
                  'modifier_option_id': mod.optionId,
                  'price': mod.price,
                  'name': mod.name,
                  'option_name': mod.optionName,
                };
              }).toList(),
            };
          }).toList(),
          'subtotal': state.subTotal,
          'tax': state.tax,
          'service_charge': state.serviceCharge,
          'grand_total': state.total,
          'discount_id': state.activeDiscount?.id,
          'discount_amount': state.discountAmount,
          'payment_method': paymentMethod,
          'amount_paid': amountPaid,
          'change': amountPaid - state.total,
          'order_type': apiOrderType,
          'payment_status': 'paid',
          'customer_name': state.selectedCustomer?.name ?? 'Walk-in Customer',
          'customer_id': state.selectedCustomer?.isGuest == true
              ? null
              : state.selectedCustomer?.id,
          'created_at': DateTime.now().toIso8601String(),
        };

        try {
          // Save offline
          await HiveService.savePendingOrder(orderData);

          // Clear cart on offline success
          clearCart();
          selectCustomer(null);

          state = state.copyWith(
            loading: false,
            offlinePendingCount: HiveService.getPendingOrders().length,
          );
          return; // Exit normally without rethrowing
        } catch (hiveError) {
          state = state.copyWith(
            loading: false,
            error: 'Offline Storage Error: $hiveError',
          );
          rethrow;
        }
      }

      // If it's not a network error (e.g., 400 Bad Request, 500 Server Error)
      state = state.copyWith(loading: false, error: e.toString());
      rethrow;
    }
  }

  void loadBillToCart(Map<String, dynamic> bill) {
    // Clear existing cart
    clearCart();

    // Load items from bill
    final items = bill['items'] as List<dynamic>? ?? [];
    final List<CartItem> cartItems = [];

    // Use products to resolve missing modifier names
    final products = state.products;

    for (final item in items) {
      // Find product definition
      Product? product;
      try {
        product = products.firstWhere(
          (p) => p.id == item['product_id']?.toString(),
        );
      } catch (_) {}

      final modifiers = (item['modifiers'] as List<dynamic>? ?? []).map((m) {
        String modName = m['modifier_name'] ?? m['name'] ?? '';
        final optName = m['option_name'] ?? m['name'] ?? '';

        // Try to resolve name from product definition if missing
        if ((modName.isEmpty || modName == 'null') && product != null) {
          final modId = m['modifier_id']?.toString();
          if (modId != null) {
            try {
              final def = product.modifiers.firstWhere(
                (d) => d.id.toString() == modId,
              );
              modName = def.name;
            } catch (_) {}
          }
        }

        bool showInUi = true;
        if (modName == 'Available' ||
            (modName.isEmpty && ['Iced', 'Hot'].contains(optName))) {
          showInUi = false;
        }

        return CartModifier(
          modifierId: m['modifier_id']?.toString() ?? '',
          optionId:
              m['modifier_option_id']?.toString() ??
              m['option_id']?.toString() ??
              '',
          name: modName,
          optionName: optName,
          price: double.tryParse(m['price']?.toString() ?? '0') ?? 0,
          showInUi: showInUi,
        );
      }).toList();

      final modifiersTotal = modifiers.fold<double>(
        0,
        (sum, m) => sum + m.price,
      );

      final quantity = int.tryParse(item['quantity']?.toString() ?? '1') ?? 1;

      double totalPrice =
          double.tryParse(item['total_price']?.toString() ?? '') ?? 0;
      double derivedUnitPrice = quantity > 0 ? totalPrice / quantity : 0;

      double fullUnitPrice = 0;
      if (derivedUnitPrice > 0) {
        fullUnitPrice = derivedUnitPrice;
      } else {
        fullUnitPrice =
            double.tryParse(item['unit_price']?.toString() ?? '') ??
            double.tryParse(item['price']?.toString() ?? '0') ??
            0;
      }

      final basePrice = fullUnitPrice - modifiersTotal;

      String productName = item['product_name'] ?? item['name'] ?? '';
      for (var mod in modifiers) {
        if (mod.name == 'Available') {
          final optName = mod.optionName;
          if (['Iced', 'Hot'].contains(optName) &&
              !productName.contains(optName)) {
            productName = '$optName $productName';
          }
          break;
        }
      }

      cartItems.add(
        CartItem(
          cartId:
              DateTime.now().millisecondsSinceEpoch.toString() +
              item['id'].toString(),
          productId: item['product_id']?.toString() ?? '',
          name: productName,
          basePrice: basePrice,
          unitPrice: fullUnitPrice,
          quantity: quantity,
          modifiers: modifiers,
          note: item['note'],
        ),
      );
    }

    state = state.copyWith(
      cart: cartItems,
      originalCart: cartItems,
    );

    if (bill['order_number'] != null) {
      state = state.copyWith(currentOrderNumber: bill['order_number']);
    }

    if (bill['id'] != null) {
      state = state.copyWith(currentOrderId: bill['id'].toString());
    }

    if (bill['customer'] != null) {
      final customer = Customer.fromJson(bill['customer']);
      selectCustomer(customer);
    } else if (bill['customer_name'] != null &&
        bill['customer_name'] != 'Guest') {
      final guest = Customer.guest(bill['customer_name']);
      selectCustomer(guest);
    }

    if (bill['order_type'] != null) {
      final orderType = bill['order_type'].toString();
      final formatted = orderType
          .replaceAll('_', ' ')
          .split(' ')
          .map((word) {
            if (word.isEmpty) return '';
            return word[0].toUpperCase() + word.substring(1).toLowerCase();
          })
          .join(' ');
      setOrderType(formatted);
    }
  }

  void clearCart() {
    state = state.copyWith(
      cart: [],
      clearDiscount: true,
      clearOrderNumber: true,
      clearOrderId: true,
      clearCustomer: true,
      originalCart: [],
    );
  }

  void applyDiscount(Discount discount) {
    state = state.copyWith(activeDiscount: discount);
  }

  void removeDiscount() {
    state = state.copyWith(clearDiscount: true);
  }

  void togglePendingBills(bool isOpen) {
    state = state.copyWith(isPendingBillsOpen: isOpen);
  }

  void toggleDiscountModal(bool isOpen) {
    state = state.copyWith(isDiscountModalOpen: isOpen);
  }

  void setCartOpen(bool isOpen) {
    state = state.copyWith(isCartOpen: isOpen);
  }

  Future<void> fetchCurrentShift() async {
    try {
      final response = await dio.get('/admin/shifts/current');
      final rawData = response.data;
      Map<String, dynamic>? shiftData;

      if (rawData is Map<String, dynamic> && rawData.containsKey('data')) {
        shiftData = rawData['data'];
      } else if (rawData is Map<String, dynamic>) {
        shiftData = rawData.isNotEmpty ? rawData : null;
      }

      if (shiftData != null) {
        state = state.copyWith(shift: shiftData);
      } else {
        state = state.copyWith(clearShift: true);
      }
    } catch (e) {
      state = state.copyWith(clearShift: true);
    }
  }

  Future<void> fetchPendingCount() async {
    try {
      final response = await dio.get('/admin/orders/pending-count');
      final resData = response.data;
      int count = 0;

      if (resData is Map<String, dynamic> && resData['data'] != null) {
        count = int.tryParse(resData['data']['count']?.toString() ?? '0') ?? 0;
      } else if (resData is Map<String, dynamic>) {
        count = int.tryParse(resData['count']?.toString() ?? '0') ?? 0;
      }

      state = state.copyWith(pendingCount: count);
    } catch (e) {
      debugPrint('Error fetching pending count: $e');
    }
  }

  void toggleShiftModal(bool isOpen, [String mode = 'start']) {
    state = state.copyWith(isShiftModalOpen: isOpen, shiftModalMode: mode);
  }

  void toggleCashMovementModal(bool isOpen) {
    state = state.copyWith(isCashMovementModalOpen: isOpen);
  }

  Future<void> startShift(double amount) async {
    state = state.copyWith(loading: true);
    try {
      await dio.post('/admin/shifts/start', data: {'starting_cash': amount});
      await fetchCurrentShift();
      state = state.copyWith(loading: false, isShiftModalOpen: false);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> endShift(double amount, String note) async {
    state = state.copyWith(loading: true);
    try {
      final response = await dio.post(
        '/admin/shifts/end',
        data: {'ending_cash_actual': amount, 'note': note},
      );

      state = state.copyWith(clearShift: true);
      await fetchCurrentShift();
      state = state.copyWith(loading: false, isShiftModalOpen: false);

      if (response.data is Map<String, dynamic>) {
        final data = response.data;
        if (data['data'] is Map<String, dynamic>) {
          return data['data'];
        }
        return data;
      }
      return null;
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 400) {
        final errorMsg = e.response?.data?['message'] ?? '';
        if (errorMsg.contains('No open shift found')) {
          state = state.copyWith(
            clearShift: true,
            loading: false,
            isShiftModalOpen: false,
          );
          return null;
        }
      }
      state = state.copyWith(loading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> recordCashMovement({
    required String type, // 'pay_in', 'pay_out', 'drop'
    required double amount,
    required String note,
  }) async {
    state = state.copyWith(loading: true);
    try {
      await dio.post(
        '/admin/shifts/movement',
        data: {'type': type, 'amount': amount, 'reason': note},
      );
      // Refresh shift to get updated expected_cash
      await fetchCurrentShift();
      state = state.copyWith(loading: false, isCashMovementModalOpen: false);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
      rethrow;
    }
  }
}

final posProvider = StateNotifierProvider<PosNotifier, PosState>((ref) {
  final dio = ref.watch(dioProvider);
  return PosNotifier(dio);
});
