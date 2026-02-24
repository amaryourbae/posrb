import 'dart:math';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/services/dio_service.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/order.dart';
import '../../../core/models/product.dart';
import '../../../core/models/customer.dart';
import '../../../core/providers/history_provider.dart';
import '../../receipt/receipt_widget.dart';
import 'package:screenshot/screenshot.dart';
import '../../../core/providers/pos_provider.dart';
import '../../widgets/manager_pin_dialog.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:flutter/foundation.dart';
import '../../widgets/app_toast.dart';

class TransactionDetailSheet extends ConsumerStatefulWidget {
  final Order order;
  final VoidCallback? onClose;

  const TransactionDetailSheet({super.key, required this.order, this.onClose});

  @override
  ConsumerState<TransactionDetailSheet> createState() =>
      _TransactionDetailSheetState();
}

class _TransactionDetailSheetState
    extends ConsumerState<TransactionDetailSheet> {
  final ScreenshotController _screenshotController = ScreenshotController();
  bool _isPrinting = false;

  Future<void> _handleRefund() async {
    final pin = await showDialog<String>(
      context: context,
      builder: (_) => const ManagerPinDialog(),
    );

    if (pin != null && mounted) {
      final success = await ref
          .read(historyProvider.notifier)
          .refundOrder(widget.order.id, pin);
      if (mounted) {
        if (success) {
          Navigator.pop(context); // Close sheet
          AppToast.show(
            context,
            'Order refunded successfully',
            type: ToastType.success,
          );
        } else {
          AppToast.show(
            context,
            'Refund failed. Check PIN or Network.',
            type: ToastType.error,
          );
        }
      }
    }
  }

  Future<void> _handlePrint() async {
    if (kIsWeb) return; // No thermal print on web
    setState(() => _isPrinting = true);
    try {
      final posState = ref.read(posProvider);
      final settingsMap = {
        'tax_rate': posState.taxRate,
        'service_charge_rate': posState.serviceChargeRate,
      };

      final image = await _screenshotController.captureFromWidget(
        ReceiptWidget(order: widget.order.toJson(), settings: settingsMap),
        delay: const Duration(milliseconds: 100),
        context: context,
      );

      if (!mounted) return;

      final printer = BlueThermalPrinter.instance;
      final isConnected = await printer.isConnected;
      if (!mounted) return;
      if (isConnected == true) {
        printer.printImageBytes(image);
      } else {
        AppToast.show(
          context,
          'Printer not connected',
          type: ToastType.warning,
        );
      }
    } catch (e) {
      debugPrint('Print Error: $e');
    } finally {
      if (mounted) setState(() => _isPrinting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order; // Access from widget
    return Container(
      decoration: const BoxDecoration(color: Colors.white),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with Order Number and Status
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Order Details',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      order
                          .orderNumber, // Adjusted to remove # per image if needed, or keep. Image shows "TRX-..." directly usually or labeled. Reference says "TRX-2026..." text.
                      style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                    ),
                  ],
                ),
                Row(
                  children: [
                    _buildStatusBadge(order.status),
                    const SizedBox(width: 16),
                    IconButton(
                      icon: const Icon(LucideIcons.x),
                      onPressed: () {
                        if (widget.onClose != null) {
                          widget.onClose!();
                        } else {
                          Navigator.pop(context);
                        }
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      iconSize: 24,
                      color: Colors.grey[400],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF3F4F6)),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Customer Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50], // Very light background
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(
                            color: Color(0xFFEF4444), // Red/Orange Avatar bg
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            (order.customerName ?? 'Guest')
                                .substring(
                                  0,
                                  min(
                                    2,
                                    (order.customerName ?? 'Guest').length,
                                  ),
                                )
                                .toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                order.customerName ?? 'Guest',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                order.customerPhone != null &&
                                        order.customerPhone!.isNotEmpty
                                    ? order.customerPhone!
                                    : 'No phone number provided',
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Meta Info (Order Type & Payment) - Two columns
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ORDER TYPE',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[500],
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    LucideIcons.armchair,
                                    size: 16,
                                    color: Colors.grey[700],
                                  ),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      order.orderType
                                              ?.replaceAll('_', ' ')
                                              .toUpperCase() ??
                                          'DINE IN',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: Colors.black87,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'PAYMENT',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[500],
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    LucideIcons.creditCard,
                                    size: 16,
                                    color: Colors.grey[700],
                                  ),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      order.paymentMethod.toUpperCase().isEmpty
                                          ? 'CASH'
                                          : order.paymentMethod.toUpperCase(),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: Colors.black87,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // ITEMS HEADER
                  Text(
                    'ITEMS ORDERED (${order.items.length})',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[400],
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...order.items.map((item) => _buildItemRow(item)),

                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 24),

                  // Totals
                  _buildSummaryRow(
                    'Subtotal',
                    order.subtotal ?? order.totalPrice,
                  ),
                  if ((order.discountAmount ?? 0) > 0)
                    _buildSummaryRow(
                      'Discount',
                      -(order.discountAmount ?? 0),
                      isDiscount: true,
                    ),
                  if ((order.taxAmount ?? 0) > 0)
                    _buildSummaryRow('Tax', order.taxAmount ?? 0),
                  if ((order.serviceCharge ?? 0) > 0)
                    _buildSummaryRow(
                      'Service Charge',
                      order.serviceCharge ?? 0,
                    ),

                  const SizedBox(height: 12),
                  const Divider(color: Colors.transparent), // Spacer
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'Total Paid',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        NumberFormat.currency(
                          locale: 'id',
                          symbol: 'Rp ',
                          decimalDigits: 0,
                        ).format(order.totalPrice),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                          color: Color(0xFF005c4b),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Actions
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (order.status == 'pending') ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _handleResume,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00B14F),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Resume Payment',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: _handleCancel,
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                        child: const Text('Cancel Order'),
                      ),
                    ),
                  ] else ...[
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _isPrinting ? null : _handlePrint,
                            icon: _isPrinting
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(LucideIcons.printer, size: 18),
                            label: Text(_isPrinting ? 'Printing...' : 'Print'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.black87,
                              side: BorderSide(color: Colors.grey[300]!),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _handleWhatsApp,
                            icon: const Icon(
                              LucideIcons.send,
                              size: 18,
                              color: Colors.white,
                            ),
                            label: const Text(
                              'WhatsApp',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF5a6c37),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (order.status == 'paid' ||
                        order.status == 'completed') ...[
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: TextButton(
                          onPressed: _handleRefund,
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                          child: const Text(
                            'Request Refund',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductImage(String? imageUrl) {
    final fullUrl = getFullImageUrl(imageUrl);

    if (fullUrl == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.image, size: 20, color: Colors.grey[300]),
            const SizedBox(height: 2),
            Text(
              'No Image',
              style: TextStyle(fontSize: 7, color: Colors.grey[400]),
            ),
          ],
        ),
      );
    }

    return Image.network(
      fullUrl,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Center(
          child: CircularProgressIndicator(
            value: loadingProgress.expectedTotalBytes != null
                ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                : null,
            strokeWidth: 2,
            color: Colors.grey[300],
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.imageOff, size: 20, color: Colors.grey[300]),
            const SizedBox(height: 2),
            Text(
              'Error',
              style: TextStyle(fontSize: 7, color: Colors.grey[400]),
            ),
          ],
        ),
      ),
    );
  }

  void _handleResume() {
    final posNotifier = ref.read(posProvider.notifier);
    posNotifier.clearCart();

    // Re-add items
    for (var item in widget.order.items) {
      final product = Product(
        id: item['product_id']?.toString() ?? '',
        name: item['product_name'] ?? item['name'] ?? 'Unknown',
        price: double.tryParse(item['unit_price']?.toString() ?? '0') ?? 0,
        imageUrl: item['product']?['image_url'],
        modifiers: const [],
      );

      final qty = int.tryParse(item['quantity']?.toString() ?? '1') ?? 1;
      for (int i = 0; i < qty; i++) {
        posNotifier.addToCart(product);
      }
    }

    // Set Customer
    if (widget.order.customerName != null) {
      final customer = Customer(
        id: '',
        name: widget.order.customerName!,
        phone: widget.order.customerPhone,
      );
      posNotifier.selectCustomer(customer);
    }

    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _handleCancel() async {
    final pin = await showDialog<String>(
      context: context,
      builder: (_) => const ManagerPinDialog(),
    );

    if (pin != null && mounted) {
      final success = await ref
          .read(historyProvider.notifier)
          .cancelOrder(widget.order.id, pin);

      if (mounted) {
        if (success) {
          Navigator.pop(context);
          AppToast.show(
            context,
            'Order cancelled successfully',
            type: ToastType.success,
          );
        } else {
          AppToast.show(
            context,
            'Cancellation failed. Check PIN or Network.',
            type: ToastType.error,
          );
        }
      }
    }
  }

  void _handleWhatsApp() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        String phone = '';
        if (widget.order.customerPhone != null) {
          phone = widget.order.customerPhone!.replaceAll(RegExp(r'\D'), '');
          if (phone.startsWith('62')) {
            phone = phone.substring(2);
          } else if (phone.startsWith('0')) {
            phone = phone.substring(1);
          }
        }

        final controller = TextEditingController(text: phone);

        return AlertDialog(
          title: const Text('Send Receipt via WhatsApp'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  prefixText: '+62 ',
                  labelText: 'Phone Number',
                  hintText: '81234567890',
                ),
                keyboardType: TextInputType.phone,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final input = controller.text.trim();
                if (input.isEmpty) return;

                // Format to 62...
                String formatted = input.replaceAll(RegExp(r'\D'), '');
                if (formatted.startsWith('0')) {
                  formatted = '62${formatted.substring(1)}';
                } else if (!formatted.startsWith('62')) {
                  formatted = '62$formatted';
                }

                Navigator.pop(dialogContext);

                final success = await ref
                    .read(historyProvider.notifier)
                    .sendReceipt(widget.order.id, formatted);
                if (mounted) {
                  AppToast.show(
                    context,
                    success ? 'Receipt sent!' : 'Failed to send receipt',
                    type: success ? ToastType.success : ToastType.error,
                  );
                }
              },
              child: const Text('Send'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    Color bg;

    switch (status.toLowerCase()) {
      case 'completed':
      case 'paid':
        color = const Color(0xFF00B14F);
        bg = const Color(0xFFE8F5E9);
        break;
      case 'cancelled':
        color = Colors.red;
        bg = Colors.red[50]!;
        break;
      default:
        color = Colors.orange;
        bg = Colors.orange[50]!;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        (status == 'completed' ? 'Paid' : status).replaceFirst(
          status[0],
          status[0].toUpperCase(),
        ),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildItemRow(dynamic item) {
    String name = item['product_name'] ?? item['name'] ?? 'Item';
    final quantity = item['quantity'] ?? 1;

    // Parse modifiers and extract prefixes
    String sizePrefix = '';
    String availablePrefix = '';

    if (item['modifiers'] != null && item['modifiers'] is List) {
      for (var mod in item['modifiers']) {
        final optionName = mod['option_name'] ?? mod['name'] ?? '';
        final modifierName =
            mod['modifier_name'] ?? mod['modifier']?['name'] ?? '';

        if (modifierName == 'Size') {
          sizePrefix = optionName;
        } else if (modifierName == 'Available') {
          availablePrefix = optionName;
        }
      }
    }

    // Prepend prefixes to name: Available then Size for "Regular Iced..."
    if (availablePrefix.isNotEmpty &&
        !name.toLowerCase().contains(availablePrefix.toLowerCase())) {
      name = "$availablePrefix $name";
    }
    if (sizePrefix.isNotEmpty &&
        !name.toLowerCase().contains(sizePrefix.toLowerCase())) {
      name = "$sizePrefix $name";
    }

    List<String> visibleModifiers = [];
    if (item['modifiers'] != null && item['modifiers'] is List) {
      for (var mod in item['modifiers']) {
        final optionName = mod['option_name'] ?? mod['name'] ?? '';
        final modifierName =
            mod['modifier_name'] ?? mod['modifier']?['name'] ?? '';

        if (modifierName != 'Size' && modifierName != 'Available') {
          // Formatting logic: "Normal" + "Ice Cube" -> "Normal Ice"
          String displayName = optionName;
          if (modifierName.toLowerCase().contains('ice')) {
            if (['Normal', 'Less', 'Extra'].contains(optionName)) {
              displayName = "$optionName Ice";
            } else {
              displayName = "$optionName ${modifierName.split(' ')[0]}";
            }
          } else {
            // Generic fallback: "Normal" + "Sugar Level" -> "Normal Sugar"
            displayName = "$optionName ${modifierName.split(' ')[0]}";
          }
          visibleModifiers.add(displayName);
        }
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: _buildProductImage(item['product']?['image_url']),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${quantity}x $name',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (visibleModifiers.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    visibleModifiers.join(', '),
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ],
                if (item['note'] != null &&
                    item['note'].toString().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    '"${item['note']}"',
                    style: TextStyle(
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey[400],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            NumberFormat.currency(
              locale: 'id',
              symbol: 'Rp ',
              decimalDigits: 0,
            ).format(
              (double.tryParse(item['total_price']?.toString() ?? '0') ?? 0),
            ),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    double value, {
    bool isDiscount = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          Text(
            NumberFormat.currency(
              locale: 'id',
              symbol: isDiscount ? '-Rp ' : 'Rp ',
              decimalDigits: 0,
            ).format(value.abs()),
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isDiscount ? Colors.red : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
