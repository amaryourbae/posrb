import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/services/dio_service.dart';
import '../../core/providers/pos_provider.dart';
import 'package:go_router/go_router.dart';
import '../widgets/app_toast.dart';
import '../modals/status_modal.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  String _selectedPaymentMethod = 'cash'; // Default to cash
  final TextEditingController _amountPaidController = TextEditingController();

  // Hardcoded payment methods for now, can be dynamic later
  final List<Map<String, dynamic>> _paymentMethods = [
    {'id': 'cash', 'name': 'Cash', 'icon': Icons.payments},
    {'id': 'qris', 'name': 'QRIS', 'icon': Icons.qr_code},
    {'id': 'debit', 'name': 'Debit Card', 'icon': Icons.credit_card},
  ];

  @override
  void dispose() {
    _amountPaidController.dispose();
    super.dispose();
  }

  void _processCheckout() async {
    final state = ref.read(posProvider);
    double amountPaid = 0.0;

    if (_selectedPaymentMethod == 'cash') {
      amountPaid =
          double.tryParse(
            _amountPaidController.text.replaceAll(RegExp(r'[^0-9]'), ''),
          ) ??
          0.0;
      if (amountPaid < state.total) {
        AppToast.show(
          context,
          'Insufficient amount paid',
          type: ToastType.warning,
        );
        return;
      }
    } else {
      // For non-cash, assume full payment
      amountPaid = state.total;
    }

    try {
      await ref
          .read(posProvider.notifier)
          .checkout(
            paymentMethod: _selectedPaymentMethod,
            amountPaid: amountPaid,
          );

      if (mounted) {
        if (mounted) {
          StatusModal.show(
            context: context,
            title: 'Payment Successful',
            message: 'The order has been completed and recorded successfully.',
            onButtonPressed: () {
              context.go('/'); // Return to POS
            },
          );
        }
      }
    } catch (e) {
      if (mounted) {
        AppToast.show(context, 'Checkout failed: $e', type: ToastType.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(posProvider);
    final formatCurrency = NumberFormat.simpleCurrency(locale: 'id_ID');

    if (state.cart.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Checkout')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Cart is empty'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go('/'),
                child: const Text('Back to POS'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Checkout'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
      ),
      body: Row(
        children: [
          // Left Side: Order Summary
          Expanded(
            flex: 3,
            child: Container(
              margin: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: const Text(
                      'Order Summary',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.all(24),
                      itemCount: state.cart.length,
                      separatorBuilder: (context, index) => const Divider(),
                      itemBuilder: (context, index) {
                        final item = state.cart[index];
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: Colors.grey[100],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: _buildProductImage(item.imageUrl),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (item.modifiers.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        item.modifiers
                                            .map(
                                              (m) =>
                                                  "${m.optionName} (+${formatCurrency.format(m.price)})",
                                            )
                                            .join(', '),
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  if (item.note != null &&
                                      item.note!.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        "Note: ${item.note}",
                                        style: TextStyle(
                                          color: Colors.orange[800],
                                          fontSize: 12,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text("x${item.quantity}"),
                                const SizedBox(height: 4),
                                Text(
                                  formatCurrency.format(item.totalPrice),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        _buildSummaryRow(
                          'Subtotal',
                          state.subTotal,
                          formatCurrency,
                        ),
                        const SizedBox(height: 8),
                        _buildSummaryRow(
                          'Tax (11%)',
                          state.tax,
                          formatCurrency,
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Divider(),
                        ),
                        _buildSummaryRow(
                          'Total',
                          state.total,
                          formatCurrency,
                          isTotal: true,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Right Side: Payment
          Expanded(
            flex: 2,
            child: Container(
              margin: const EdgeInsets.fromLTRB(0, 24, 24, 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Payment Method',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ..._paymentMethods.map((method) {
                      final isSelected = _selectedPaymentMethod == method['id'];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          onTap: () => setState(
                            () => _selectedPaymentMethod = method['id'],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFF5a6c37)
                                    : Colors.grey[200]!,
                                width: isSelected ? 2 : 1,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              color: isSelected
                                  ? const Color(
                                      0xFF5a6c37,
                                    ).withValues(alpha: 0.05)
                                  : Colors.white,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  method['icon'],
                                  color: isSelected
                                      ? const Color(0xFF5a6c37)
                                      : Colors.grey[600],
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  method['name'],
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isSelected
                                        ? const Color(0xFF5a6c37)
                                        : Colors.black87,
                                  ),
                                ),
                                const Spacer(),
                                if (isSelected)
                                  const Icon(
                                    Icons.check_circle,
                                    color: Color(0xFF5a6c37),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),

                    if (_selectedPaymentMethod == 'cash') ...[
                      const SizedBox(height: 24),
                      const Text(
                        'Cash Amount Received',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _amountPaidController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          prefixText: 'Rp ',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          hintText: 'Enter amount...',
                        ),
                        // Basic visual feedback for change calculation could go here
                      ),
                    ],

                    const Spacer(),

                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: state.loading ? null : _processCheckout,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5a6c37),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: state.loading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text(
                                'Complete Order',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
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
            const Icon(Icons.image, size: 24, color: Color(0xFFE0E0E0)),
            const SizedBox(height: 2),
            Text(
              'No Image',
              style: TextStyle(fontSize: 8, color: Colors.grey[400]),
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
            color: Colors.grey[200],
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.image_not_supported,
              size: 24,
              color: Color(0xFFE0E0E0),
            ),
            const SizedBox(height: 2),
            Text(
              'Error',
              style: TextStyle(fontSize: 8, color: Colors.grey[400]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    double amount,
    NumberFormat formatCurrency, {
    bool isTotal = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 18 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: isTotal ? Colors.black : Colors.grey[600],
          ),
        ),
        Text(
          formatCurrency.format(amount),
          style: TextStyle(
            fontSize: isTotal ? 20 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: isTotal ? const Color(0xFF5a6c37) : Colors.black,
          ),
        ),
      ],
    );
  }
}
