import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:permission_handler/permission_handler.dart';
import '../core/providers/pos_provider.dart';
import '../core/providers/auth_provider.dart';
import '../core/services/dio_service.dart';
import 'product_grid.dart';
import 'cart_sidebar.dart';
import 'layout/pos_layout.dart';
import 'modals/payment_modal.dart';
import 'modals/order_success_modal.dart';
import 'widgets/skeleton.dart';
import 'modals/discount_modal.dart';
import 'widgets/offline_indicator.dart';
import 'widgets/app_toast.dart';

class PosScreen extends ConsumerStatefulWidget {
  const PosScreen({super.key});

  @override
  ConsumerState<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends ConsumerState<PosScreen> {
  bool _showPaymentModal = false;
  bool _showSuccessModal = false;
  bool _paymentLoading = false;

  Map<String, dynamic>? _completedOrder;

  // Printer logic
  final BlueThermalPrinter _printer = BlueThermalPrinter.instance;
  bool _connected = false;
  List<BluetoothDevice> _devices = [];
  BluetoothDevice? _selectedDevice;

  @override
  void initState() {
    super.initState();
    _initPrinter();
  }

  Future<void> _initPrinter() async {
    if (kIsWeb) return;
    try {
      if (await Permission.bluetoothScan.request().isGranted &&
          await Permission.bluetoothConnect.request().isGranted &&
          await Permission.location.request().isGranted) {
        bool? isConnected = await _printer.isConnected;
        if (mounted) {
          setState(() {
            _connected = isConnected ?? false;
          });
        }
        _getDevices();
      }
    } catch (e) {
      debugPrint("Printer init error: $e");
    }
  }

  Future<void> _getDevices() async {
    try {
      List<BluetoothDevice> devices = await _printer.getBondedDevices();
      if (mounted) {
        setState(() {
          _devices = devices;
          if (devices.isNotEmpty) {
            // Optional: auto-select first device or logic to load saved device
            // _selectedDevice = devices.first;
          }
        });
      }
    } catch (e) {
      debugPrint("Printer get devices error: $e");
    }
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
    setState(() {
      _showPaymentModal = true;
    });
  }

  Future<void> _saveBill() async {
    final state = ref.read(posProvider);
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

      if (orderId != null) {
        // Update existing pending bill
        await dio.put('/orders/$orderId', data: orderData);
      } else {
        // Create new pending bill
        await dio.post('/orders', data: orderData);
      }

      // Clear cart and close
      final notifier = ref.read(posProvider.notifier);
      notifier.clearCart();
      notifier.setCartOpen(false);
      notifier.fetchPendingCount();

      if (mounted) {
        AppToast.show(
          context,
          'Bill saved! You can resume payment later.',
          type: ToastType.info,
        );
      }
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

      dynamic response;
      if (orderId != null) {
        // Update existing order to PAID
        response = await dio.put('/orders/$orderId', data: orderData);
      } else {
        // Create new PAID order
        response = await dio.post('/orders', data: orderData);
      }

      final responseData = response.data;

      if (responseData is! Map) {
        throw Exception("Invalid server response format: $responseData");
      }

      final order =
          responseData['order'] ?? responseData['data'] ?? responseData;

      if (order is! Map) {
        throw Exception("Invalid order data format in response");
      }

      // Add change from payment
      order['change'] = paymentData['change'];

      // Ensure order_number is present for the modal
      if (order['order_number'] == null && state.currentOrderNumber != null) {
        order['order_number'] = state.currentOrderNumber;
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

      setState(() {
        _paymentLoading = false;
        _showPaymentModal = false;
        _completedOrder = order as Map<String, dynamic>;
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

  void _handleNewOrder() {
    final notifier = ref.read(posProvider.notifier);
    notifier.clearCart();
    setState(() {
      _showSuccessModal = false;
      _completedOrder = null;
      notifier.setCartOpen(false);
    });
  }

  Future<void> _handlePrint() async {
    if (kIsWeb) {
      if (mounted) {
        AppToast.show(
          context,
          'Printing not supported on Web',
          type: ToastType.warning,
        );
      }
      return;
    }
    // Check permissions first
    if (!await Permission.bluetoothScan.request().isGranted ||
        !await Permission.bluetoothConnect.request().isGranted ||
        !await Permission.location.request().isGranted) {
      if (mounted) {
        AppToast.show(
          context,
          'Bluetooth permissions required to print',
          type: ToastType.error,
        );
      }
      return;
    }

    // Basic Print Implementation
    if (!_connected) {
      await _initPrinter();
      if (_devices.isNotEmpty) {
        _selectedDevice =
            _devices.first; // Auto select first for simplicity now
        try {
          await _printer.connect(_selectedDevice!);
          _connected = true;
        } catch (e) {
          if (mounted) {
            AppToast.show(
              context,
              "Cannot connect to printer: $e",
              type: ToastType.error,
            );
          }
          return;
        }
      } else {
        if (mounted) {
          AppToast.show(
            context,
            "No Bluetooth printers found",
            type: ToastType.warning,
          );
        }
        return;
      }
    }

    if (_connected && _completedOrder != null) {
      try {
        // Simple Receipt Printing Logic - Text based
        // In real production, we'd use line commands for layout
        _printer.printNewLine();
        _printer.printCustom("POS RECEIPT", 3, 1);
        _printer.printNewLine();
        _printer.printCustom(_completedOrder!['order_number'] ?? 'Order', 1, 1);
        _printer.printNewLine();

        final items = _completedOrder!['items'] as List<dynamic>? ?? [];
        for (var item in items) {
          String name = item['product_name'] ?? 'Item';
          String qty = (item['quantity'] ?? 1).toString();
          String total = item['total_price']?.toString() ?? '0';
          _printer.printLeftRight("$qty x $name", total, 0);
        }
        _printer.printNewLine();
        _printer.printCustom("Total: ${_completedOrder!['grand_total']}", 1, 1);
        _printer.printNewLine();
        _printer.printNewLine();
        _printer.paperCut();
      } catch (e) {
        if (mounted) {
          AppToast.show(context, "Print error: $e", type: ToastType.error);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(posProvider);
    final notifier = ref.read(posProvider.notifier);
    final authState = ref.watch(authProvider);
    final screenWidth = MediaQuery.of(context).size.width;

    return PosLayout(
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
                      const OfflineIndicator(),
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
                                  onTap: () => notifier.selectCategory(cat.id),
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
                onSaveBill: _saveBill,
              ),
            ),

          // Floating Cart Button (when cart closed)
          if (!state.isCartOpen)
            Positioned(
              bottom: 24,
              right: 24,
              child: FloatingActionButton.extended(
                onPressed: () => notifier.setCartOpen(true),
                backgroundColor: const Color(0xFF5a6c37),
                elevation: 8,
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(LucideIcons.shoppingBag, color: Colors.white),
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
                            border: Border.all(color: Colors.white, width: 2),
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
                    : const Text('Cart', style: TextStyle(color: Colors.white)),
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

          // Order Success Modal
          OrderSuccessModal(
            isOpen: _showSuccessModal,
            order: _completedOrder,
            settings: authState.settings,
            onNewOrder: _handleNewOrder,
            onPrint: _handlePrint,
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
        ],
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
