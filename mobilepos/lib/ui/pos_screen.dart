import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../core/providers/pos_provider.dart';
import '../core/providers/auth_provider.dart';
import '../core/providers/settings_provider.dart';
import '../core/models/cart_item.dart';
import '../core/services/dio_service.dart';
import 'product_grid.dart';
import 'cart_sidebar.dart';
import 'layout/pos_layout.dart';
import 'modals/payment_modal.dart';
import 'modals/split_bill_modal.dart';
import 'modals/order_success_modal.dart';
import 'widgets/skeleton.dart';
import 'modals/discount_modal.dart';
import 'widgets/app_toast.dart';
import '../core/services/sync_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';
import 'package:screenshot/screenshot.dart';
import '../core/services/hive_service.dart';
import 'package:flutter/services.dart';
import 'receipt/receipt_widget.dart';
import 'receipt/order_ticket_widget.dart';
import 'dart:ui' as ui;

class PosScreen extends ConsumerStatefulWidget {
  const PosScreen({super.key});

  @override
  ConsumerState<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends ConsumerState<PosScreen> {
  final ScreenshotController _receiptScreenshotController =
      ScreenshotController();
  final ScreenshotController _orderScreenshotController =
      ScreenshotController();
  bool _showPaymentModal = false;
  bool _showSplitBillModal = false;
  bool _showSuccessModal = false;
  bool _paymentLoading = false;
  bool _isOffline = false;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  Map<String, dynamic>? _completedOrder;

  @override
  void initState() {
    super.initState();
    _checkInitialConnectivity();
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) {
      if (mounted) {
        setState(() {
          _isOffline = results.contains(ConnectivityResult.none);
        });
        if (!_isOffline) {
          SyncService().syncPendingOrders();
        }
      }
    });
  }

  Future<void> _checkInitialConnectivity() async {
    final results = await Connectivity().checkConnectivity();
    if (mounted) {
      setState(() {
        _isOffline = results.contains(ConnectivityResult.none);
      });
    }
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  String _formatCurrency(double amount) {
    final format = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return format.format(amount);
  }

  void _handleCharge() {
    final state = ref.read(posProvider);
    if (state.selectedCustomer == null ||
        state.selectedCustomer!.name.trim().isEmpty) {
      AppToast.show(
        context,
        'Nama customer wajib diisi sebelum melakukan pembayaran!',
        type: ToastType.warning,
      );
      return;
    }

    setState(() {
      _showPaymentModal = true;
    });
  }

  void _handleSplitBill() {
    setState(() {
      _showSplitBillModal = true;
    });
  }

  bool _hasCartChanged(List<CartItem> current, List<CartItem> original) {
    if (current.length != original.length) return true;

    for (int i = 0; i < current.length; i++) {
      final c = current[i];
      final o = original[i];

      if (c.productId != o.productId) return true;
      if (c.quantity != o.quantity) return true;
      
      // Handle null vs empty string for notes
      final cNote = c.note ?? '';
      final oNote = o.note ?? '';
      if (cNote != oNote) return true;

      // Deep compare modifiers
      if (c.modifiers.length != o.modifiers.length) return true;
      
      // Create a sorted list of optionIds to compare regardless of order
      final cMods = c.modifiers.map((m) => m.optionId).toList()..sort();
      final oMods = o.modifiers.map((m) => m.optionId).toList()..sort();
      
      for (int j = 0; j < cMods.length; j++) {
        if (cMods[j] != oMods[j]) return true;
      }
    }
    return false;
  }

  Future<void> _saveBill() async {
    final state = ref.read(posProvider);

    if (state.selectedCustomer == null ||
        state.selectedCustomer!.name.trim().isEmpty) {
      AppToast.show(
        context,
        'Nama customer wajib diisi sebelum menyimpan tagihan!',
        type: ToastType.warning,
      );
      return;
    }

    final dio = ref.read(dioProvider);
    final orderId = state.currentOrderId;

    try {
      final orderData = {
        'customer_id': state.selectedCustomer?.id,
        'customer_name': state.selectedCustomer?.name ?? 'Guest',
        'order_type': state.orderType.toLowerCase().replaceAll(' ', '_'),
        'items': state.cart.map((item) {
          return {
            'product_id': item.productId,
            'name': item.name,
            'quantity': item.quantity,
            'price': item.unitPrice,
            'note': item.note,
            'modifiers': item.modifiers.map((m) {
              return {
                'modifier_id': m.modifierId,
                'modifier_name': m.name,
                'name': m.name,
                'option_id': m.optionId,
                'option_name': m.optionName,
                'price': m.price,
              };
            }).toList(),
          };
        }).toList(),
        'subtotal': state.subTotal,
        'tax_amount': state.tax,
        'grand_total': state.total,
        'payment_method': 'pending',
        'payment_status': 'pending',
      };

      dynamic orderToPrint = orderData;

      if (_isOffline) {
        await HiveService.savePendingOrder(orderData);
        // Add fake order number for offline printing
        orderToPrint['order_number'] = state.currentOrderNumber ?? 'OFF-TXN';
        if (mounted) {
          AppToast.show(
            context,
            'Offline: Bill saved locally. Waiting for connection.',
            type: ToastType.warning,
          );
        }
      } else {
        dynamic response;
        if (orderId != null) {
          // Update existing pending bill
          response = await dio.put('/orders/$orderId', data: orderData);
        } else {
          // Create new pending bill
          response = await dio.post('/orders', data: orderData);
        }

        final responseData = response.data;
        if (responseData is Map) {
          orderToPrint =
              responseData['order'] ?? responseData['data'] ?? responseData;
        }

        if (mounted) {
          AppToast.show(
            context,
            'Bill saved! You can resume payment later.',
            type: ToastType.info,
          );
        }
      }

      // Auto Print Order Ticket only if there are changes or it's a new bill
      if (orderId == null || _hasCartChanged(state.cart, state.originalCart)) {
        final ticketImage = await _orderScreenshotController.captureFromWidget(
          Material(
            child: Directionality(
              textDirection: ui.TextDirection.ltr,
              child: OrderTicketWidget(
                order: orderToPrint,
                isAdditional: orderId != null,
              ),
            ),
          ),
          delay: const Duration(milliseconds: 300),
          pixelRatio: 3.0,
        );

        ref.read(settingsProvider.notifier).printOrderTicket(
          orderToPrint,
          isAdditional: orderId != null,
          screenshot: ticketImage,
        );
      }

      // Clear cart and close
      final notifier = ref.read(posProvider.notifier);
      notifier.clearCart();
      notifier.setCartOpen(false);
      notifier.fetchPendingCount();

      notifier.fetchPendingCount();
    } catch (e) {
      if (mounted) {
        AppToast.show(
          context,
          'Failed to save bill: $e',
          type: ToastType.error,
        );
      }
    }
  }

  Future<void> _processPayment(Map<String, dynamic> paymentData) async {
    final state = ref.read(posProvider);
    final dio = ref.read(dioProvider);
    final orderId = state.currentOrderId;

    setState(() => _paymentLoading = true);

    try {
      final orderData = {
        'customer_id': state.selectedCustomer?.id,
        'customer_name': state.selectedCustomer?.name ?? 'Guest',
        'order_type': state.orderType.toLowerCase().replaceAll(' ', '_'),
        'items': state.cart.map((item) {
          return {
            'product_id': item.productId,
            'name': item.name,
            'quantity': item.quantity,
            'price': item.unitPrice,
            'note': item.note,
            'modifiers': item.modifiers.map((m) {
              return {
                'modifier_id': m.modifierId,
                'modifier_name': m.name,
                'name': m.name,
                'option_id': m.optionId,
                'option_name': m.optionName,
                'price': m.price,
              };
            }).toList(),
          };
        }).toList(),
        'subtotal': state.subTotal,
        'tax_amount': state.tax,
        'grand_total': state.total,
        'payment_method': paymentData['method'],
        'payment_status': 'paid',
        'amount_paid': paymentData['amount_paid'],
        'change': paymentData['change'],
      };

      dynamic order;
      if (_isOffline) {
        await HiveService.savePendingOrder(orderData);
        orderData['change'] = paymentData['change'];
        orderData['order_number'] = state.currentOrderNumber ?? 'OFF-TXN';
        order = orderData;
        if (mounted) {
          AppToast.show(
            context,
            'Offline: Payment saved locally.',
            type: ToastType.warning,
          );
        }
      } else {
        dynamic response;
        if (orderId != null) {
          response = await dio.put('/orders/$orderId', data: orderData);
        } else {
          response = await dio.post('/orders', data: orderData);
        }

        final responseData = response.data;
        if (responseData is! Map) {
          throw Exception("Invalid server response format");
        }

        order = responseData['order'] ?? responseData['data'] ?? responseData;
        if (order is! Map) {
          throw Exception("Invalid order data format in response");
        }
        order['change'] = paymentData['change'];

        if (order['order_number'] == null && state.currentOrderNumber != null) {
          order['order_number'] = state.currentOrderNumber;
        }
      }

      // HYDRATE NAMES: Overwrite response item names with local cart names
      // because backend might return default product name.
      try {
        if (order['items'] != null && order['items'] is List) {
          List items = order['items'];
          // Assuming order is preserved (FIFO).
          // Start from end? No, usually same order.
          // Map by matching product_id and modifiers?
          // Simplest assumption: Indices match if length matches.
          if (items.length == state.cart.length) {
            for (int i = 0; i < items.length; i++) {
              items[i]['product_name'] = state.cart[i].name;
              items[i]['name'] = state.cart[i].name;
            }
          }
        }
      } catch (_) {
        // Fallback to backend names if matching fails
      }

      // Auto Print Order Ticket

      final ticketImage = await _orderScreenshotController.captureFromWidget(
        Material(
          child: Directionality(
            textDirection: ui.TextDirection.ltr,
            child: OrderTicketWidget(
              order: order,
              isAdditional: orderId != null,
            ),
          ),
        ),
        delay: const Duration(milliseconds: 300),
        pixelRatio: 3.0,
      );

      ref.read(settingsProvider.notifier).printOrderTicket(
            order,
            isAdditional: orderId != null,
            screenshot: ticketImage,
          );

      setState(() {
        _paymentLoading = false;
        _showPaymentModal = false;
        _completedOrder = order;
        _showSuccessModal = true;
      });
      ref.read(posProvider.notifier).fetchPendingCount();
    } catch (e) {
      setState(() => _paymentLoading = false);
      if (mounted) {
        AppToast.show(context, 'Payment failed: $e', type: ToastType.error);
      }
    }
  }

  Future<void> _processSplitBillPayment(
    List<Map<String, dynamic>> payments,
  ) async {
    final state = ref.read(posProvider);
    final dio = ref.read(dioProvider);
    final orderId = state.currentOrderId;

    setState(() => _paymentLoading = true);

    try {
      final orderData = {
        'customer_id': state.selectedCustomer?.id,
        'customer_name': state.selectedCustomer?.name ?? 'Guest',
        'order_type': state.orderType.toLowerCase().replaceAll(' ', '_'),
        'items': state.cart.map((item) {
          return {
            'product_id': item.productId,
            'name': item.name,
            'quantity': item.quantity,
            'price': item.unitPrice,
            'note': item.note,
            'modifiers': item.modifiers.map((m) {
              return {
                'modifier_id': m.modifierId,
                'modifier_name': m.name,
                'name': m.name,
                'option_id': m.optionId,
                'option_name': m.optionName,
                'price': m.price,
              };
            }).toList(),
          };
        }).toList(),
        'subtotal': state.subTotal,
        'tax_amount': state.tax,
        'grand_total': state.total,
        // Send the first payment's method as a fallback for old API compatibility
        'payment_method': payments.isNotEmpty
            ? payments.first['method']
            : 'cash',
        'payment_status': 'paid',
        'payments': payments, // Send array of payments
      };

      dynamic order;
      if (_isOffline) {
        await HiveService.savePendingOrder(orderData);
        double totalPaid = payments.fold(
          0.0,
          (sum, p) => sum + (p['amount'] as double),
        );
        orderData['change'] = (totalPaid - state.total).clamp(
          0.0,
          double.infinity,
        );
        orderData['order_number'] = state.currentOrderNumber ?? 'OFF-TXN';
        order = orderData;
        if (mounted) {
          AppToast.show(
            context,
            'Offline: Split Bill Payment saved locally.',
            type: ToastType.warning,
          );
        }
      } else {
        dynamic response;
        if (orderId != null) {
          response = await dio.put('/orders/$orderId', data: orderData);
        } else {
          response = await dio.post('/orders', data: orderData);
        }

        final responseData = response.data;
        if (responseData is! Map) {
          throw Exception("Invalid server response format");
        }

        order = responseData['order'] ?? responseData['data'] ?? responseData;
        if (order is! Map) {
          throw Exception("Invalid order data format in response");
        }

        // Calculate change
        double totalPaid = payments.fold(
          0.0,
          (sum, p) => sum + (p['amount'] as double),
        );
        order['change'] = (totalPaid - state.total).clamp(0.0, double.infinity);

        if (order['order_number'] == null && state.currentOrderNumber != null) {
          order['order_number'] = state.currentOrderNumber;
        }
      }

      try {
        if (order['items'] != null && order['items'] is List) {
          List items = order['items'];
          if (items.length == state.cart.length) {
            for (int i = 0; i < items.length; i++) {
              items[i]['product_name'] = state.cart[i].name;
              items[i]['name'] = state.cart[i].name;
            }
          }
        }
      } catch (_) {}

      // Auto Print Order Ticket

      final ticketImage = await _orderScreenshotController.captureFromWidget(
        Material(
          child: Directionality(
            textDirection: ui.TextDirection.ltr,
            child: OrderTicketWidget(
              order: order,
              isAdditional: orderId != null,
            ),
          ),
        ),
        delay: const Duration(milliseconds: 300),
        pixelRatio: 3.0,
      );

      ref.read(settingsProvider.notifier).printOrderTicket(
            order,
            isAdditional: orderId != null,
            screenshot: ticketImage,
          );

      setState(() {
        _paymentLoading = false;
        _showSplitBillModal = false;
        _completedOrder = order;
        _showSuccessModal = true;
      });
      ref.read(posProvider.notifier).fetchPendingCount();
    } catch (e) {
      setState(() => _paymentLoading = false);
      if (mounted) {
        AppToast.show(
          context,
          'Split Bill payment failed: $e',
          type: ToastType.error,
        );
      }
    }
  }

  void _handleNewOrder() {
    final notifier = ref.read(posProvider.notifier);
    notifier.clearCart();
    setState(() {
      _showSuccessModal = false;
      _completedOrder = null;
      notifier.setCartOpen(false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(posProvider);
    final notifier = ref.read(posProvider.notifier);
    final authState = ref.watch(authProvider);
    final screenWidth = MediaQuery.of(context).size.width;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        SystemChannels.platform.invokeMethod('SystemNavigator.pop');
      },
      child: PosLayout(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Main Content - Positioned to shrink/resize
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              top: 0,
              bottom: 0,
              left: 0,
              // If cart is open, shrink content (400px for desktop, 360px for mobile)
              right: state.isCartOpen ? (screenWidth >= 1024 ? 400 : 360) : 0,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Search Bar
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        bottom: BorderSide(color: Colors.grey[100]!),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            constraints: const BoxConstraints(maxWidth: 400),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: TextField(
                              onChanged: (value) =>
                                  notifier.setSearchQuery(value),
                              decoration: InputDecoration(
                                hintText: "Search menu",
                                hintStyle: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 14,
                                ),
                                prefixIcon: Icon(
                                  LucideIcons.search,
                                  color: Colors.grey[400],
                                  size: 20,
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Consumer(
                          builder: (context, ref, _) {
                            if (_isOffline) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red[50],
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.red[200]!),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      LucideIcons.wifiOff,
                                      size: 14,
                                      color: Colors.red[700],
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Offline Mode',
                                      style: TextStyle(
                                        color: Colors.red[700],
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ],
                    ),
                  ),

                  // Categories
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                    child: state.loading
                        ? _buildCategorySkeleton()
                        : SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            child: Row(
                              children: [
                                _buildCategoryChip(
                                  label: 'Popular',
                                  isSelected: state.selectedCategoryId == null,
                                  onTap: () => notifier.selectCategory(null),
                                ),
                                ...state.categories.map(
                                  (cat) => _buildCategoryChip(
                                    label: cat.name,
                                    isSelected:
                                        state.selectedCategoryId == cat.id,
                                    onTap: () =>
                                        notifier.selectCategory(cat.id),
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),

                  // Product Grid
                  const Expanded(child: ProductGrid()),
                ],
              ),
            ),

            // Cart Sidebar
            // Desktop: Slide in from right (controlled by parent AnimatedPositioned)
            if (screenWidth >= 1024)
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                top: 0,
                bottom: 0,
                width: 400,
                right: state.isCartOpen ? 0 : -400,
                child: CartSidebar(
                  isOverlay: false, // Desktop uses parent positioning
                  isOpen: state.isCartOpen,
                  showBackdrop: false,
                  onClose: () => notifier.setCartOpen(false),
                  onCharge: _handleCharge,
                  onSplitBill: _handleSplitBill,
                  onSaveBill: _saveBill,
                ),
              )
            // Mobile/Tablet: Overlay without backdrop (so user can still add items)
            else
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                top: 0,
                bottom: 0,
                width: 360, // Smaller width for mobile
                right: state.isCartOpen ? 0 : -360,
                child: CartSidebar(
                  isOverlay: false, // Don't use internal overlay
                  isOpen: state.isCartOpen,
                  showBackdrop:
                      false, // No backdrop - user can still click products
                  onClose: () => notifier.setCartOpen(false),
                  onCharge: _handleCharge,
                  onSplitBill: _handleSplitBill,
                  onSaveBill: _saveBill,
                ),
              ),

            // Floating Cart Button (when cart closed)
            if (!state.isCartOpen)
              Positioned(
                bottom: 32, // Increased bottom spacing
                right: 24,
                child: SafeArea(
                  // Added SafeArea to respect bottom nav bar
                  child: FloatingActionButton.extended(
                    onPressed: () => notifier.setCartOpen(true),
                    backgroundColor: const Color(0xFF5a6c37),
                    elevation: 8,
                    icon: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        const Icon(
                          LucideIcons.shoppingBag,
                          color: Colors.white,
                        ),
                        if (state.cart.isNotEmpty)
                          Positioned(
                            top: -8,
                            right: -8,
                            child: Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  '${state.cart.length}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    label: state.cart.isNotEmpty
                        ? Text(
                            _formatCurrency(state.total),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : const Text(
                            'Cart',
                            style: TextStyle(color: Colors.white),
                          ),
                  ),
                ),
              ),

            // Payment Modal
            PaymentModal(
              isOpen: _showPaymentModal,
              totalAmount: state.total,
              loading: _paymentLoading,
              orderNumber: state.currentOrderNumber,
              onClose: () => setState(() => _showPaymentModal = false),
              onProcess: _processPayment,
            ),

            // Split Bill Modal
            SplitBillModal(
              isOpen: _showSplitBillModal,
              totalAmount: state.total,
              loading: _paymentLoading,
              onClose: () => setState(() => _showSplitBillModal = false),
              onProcess: _processSplitBillPayment,
            ),

            // Order Success Modal
            OrderSuccessModal(
              isOpen: _showSuccessModal,
              order: _completedOrder,
              settings: authState.settings,
              onNewOrder: _handleNewOrder,
              onPrint: () async {
                if (_completedOrder == null) return;
                
                final receiptImage = await _receiptScreenshotController.captureFromWidget(
                  Material(
                    child: Directionality(
                      textDirection: ui.TextDirection.ltr,
                      child: ReceiptWidget(
                        order: _completedOrder!,
                        settings: authState.settings,
                      ),
                    ),
                  ),
                  delay: const Duration(milliseconds: 300),
                  pixelRatio: 3.0,
                );
                
                ref
                    .read(settingsProvider.notifier)
                    .printReceipt(_completedOrder!, authState.settings, screenshot: receiptImage);
              },
              onSendWhatsApp: (phone) async {
                if (_completedOrder == null) return;
                final orderId = _completedOrder!['id'];

                // Clean phone number
                final cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
                final waPhone = cleanPhone.startsWith('0')
                    ? '62${cleanPhone.substring(1)}'
                    : cleanPhone;

                try {
                  final dio = ref.read(dioProvider);
                  await dio.post(
                    '/orders/$orderId/whatsapp-receipt',
                    data: {'phone': waPhone},
                  );
                  // Success is handled by the caller (Modal) via try/catch
                } catch (e) {
                  // Error is handled by the caller (Modal) via rethrow
                  rethrow;
                }
              },
            ),

            // Shift Modal (Blocking)

            // Discount Modal
            DiscountModal(
              isOpen: state.isDiscountModalOpen,
              onClose: () => notifier.toggleDiscountModal(false),
            ),

            // Hidden Screenshot Widgets
            Positioned(
              left: -1000, // Hide off-screen
              child: Screenshot(
                controller: _receiptScreenshotController,
                child: ReceiptWidget(
                  order: _completedOrder ?? {},
                  settings: authState.settings,
                ),
              ),
            ),
            Positioned(
              left: -1000, // Hide off-screen
              child: Screenshot(
                controller: _orderScreenshotController,
                child: OrderTicketWidget(
                  order: _completedOrder ?? {}, // Using _completedOrder as a proxy or current state
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySkeleton() {
    return const CategoryListSkeleton(itemCount: 6);
  }

  Widget _buildCategoryChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      child: Material(
        color: isSelected
            ? const Color(0xFF5a6c37).withValues(alpha: 0.1)
            : Colors.white,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? const Color(0xFF5a6c37) : Colors.grey[200]!,
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? const Color(0xFF5a6c37) : Colors.grey[600],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
