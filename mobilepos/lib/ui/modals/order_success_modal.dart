import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/utils/app_date_formatter.dart';
import '../widgets/app_toast.dart';

class OrderSuccessModal extends ConsumerStatefulWidget {
  final bool isOpen;
  final Map<String, dynamic>? order;
  final Map<String, dynamic>? settings;
  final VoidCallback onNewOrder;
  final VoidCallback onPrint;
  final Function(String phone) onSendWhatsApp;

  const OrderSuccessModal({
    super.key,
    required this.isOpen,
    this.order,
    this.settings,
    required this.onNewOrder,
    required this.onPrint,
    required this.onSendWhatsApp,
  });

  @override
  ConsumerState<OrderSuccessModal> createState() => _OrderSuccessModalState();
}

class _OrderSuccessModalState extends ConsumerState<OrderSuccessModal> {
  bool _showWaInput = false;
  final TextEditingController _waController = TextEditingController();
  bool _sending = false;

  String formatCurrency(double? amount) {
    if (amount == null) return 'Rp 0';
    final format = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return format.format(amount);
  }

  @override
  void dispose() {
    _waController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isOpen || widget.order == null) return const SizedBox.shrink();

    final order = widget.order!;

    return Stack(
      children: [
        // Backdrop
        Container(color: Colors.black.withValues(alpha: 0.6)),

        // Modal
        Center(
          child: Container(
            width: 480,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.9,
            ),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Success Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
                  child: Column(
                    children: [
                      // Animated Check Icon
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: const Color(0xFF5a6c37).withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: const Color(0xFF5a6c37),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF5a6c37,
                                  ).withValues(alpha: 0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(
                              LucideIcons.check,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Payment Successful',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Transaction #${order['order_number']} completed',
                        style: TextStyle(color: Colors.grey[500], fontSize: 14),
                      ),
                    ],
                  ),
                ),

                // Receipt Card
                Flexible(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Top decoration
                        Container(
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Color(0xFF5a6c37),
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(16),
                            ),
                          ),
                        ),

                        // Receipt Content
                        Flexible(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              children: [
                                Column(
                                  children: [
                                    const SizedBox(height: 16),
                                    Text(
                                      'CHANGE',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.grey[600],
                                        letterSpacing: 2,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      formatCurrency(
                                        double.tryParse(
                                          order['change']?.toString() ?? '0',
                                        ),
                                      ),
                                      style: const TextStyle(
                                        fontSize: 48,
                                        fontWeight: FontWeight.w900,
                                        color: Color(0xFF5a6c37),
                                        height: 1.1,
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[100],
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            'Out of ',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                          Text(
                                            formatCurrency(
                                              double.tryParse(
                                                order['amount_paid']
                                                        ?.toString() ??
                                                    '0',
                                              ),
                                            ),
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black87,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 24),
                              ],
                            ),
                          ),
                        ),

                        // Receipt Footer
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            border: Border(
                              top: BorderSide(color: Colors.grey[200]!),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                AppDateFormatter.formatDateFull(DateTime.now()),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[400],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey[200]!),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      order['payment_method'] == 'cash'
                                          ? LucideIcons.banknote
                                          : LucideIcons.creditCard,
                                      size: 14,
                                      color: Colors.grey[600],
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      (order['payment_method'] ?? 'CASH')
                                          .toString()
                                          .toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Action Buttons
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(32),
                    ),
                  ),
                  child: Column(
                    children: [
                      // New Order Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: widget.onNewOrder,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF5a6c37),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 4,
                          ),
                          child: const Text(
                            'New Order',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Print & Invoice Buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: widget.onPrint,
                              icon: const Icon(LucideIcons.printer),
                              label: const Text('Print'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                side: BorderSide(color: Colors.grey[200]!),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                setState(() {
                                  _showWaInput = !_showWaInput;
                                  if (_showWaInput &&
                                      order['customer_phone'] != null) {
                                    String phone = order['customer_phone']
                                        .toString();
                                    phone = phone.replaceAll(RegExp(r'\D'), '');
                                    if (phone.startsWith('62')) {
                                      phone = phone.substring(2);
                                    } else if (phone.startsWith('0')) {
                                      phone = phone.substring(1);
                                    }
                                    _waController.text = phone;
                                  }
                                });
                              },
                              icon: Icon(
                                _showWaInput
                                    ? LucideIcons.x
                                    : LucideIcons.share2,
                              ),
                              label: Text(_showWaInput ? 'Cancel' : 'Invoice'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                side: BorderSide(
                                  color: _showWaInput
                                      ? const Color(0xFF5a6c37)
                                      : Colors.grey[200]!,
                                ),
                                foregroundColor: _showWaInput
                                    ? const Color(0xFF5a6c37)
                                    : null,
                              ),
                            ),
                          ),
                        ],
                      ),

                      // WhatsApp Input
                      if (_showWaInput) ...[
                        const SizedBox(height: 16),
                        Text(
                          'WHATSAPP NUMBER',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[400],
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.grey[200]!),
                                ),
                                child: TextField(
                                  controller: _waController,
                                  keyboardType: TextInputType.phone,
                                  decoration: InputDecoration(
                                    prefixText: '+62 ',
                                    prefixStyle: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[400],
                                    ),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.all(16),
                                    hintText: '812345678',
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: _sending
                                  ? null
                                  : () async {
                                      if (_waController.text.isEmpty) return;
                                      setState(() => _sending = true);

                                      // Call Backend API instead of opening WhatsApp directly
                                      try {
                                        await widget.onSendWhatsApp(
                                          _waController.text,
                                        );
                                        // Success handling
                                        if (!context.mounted) return;

                                        setState(() {
                                          _sending = false;
                                          _showWaInput = false;
                                        });

                                        AppToast.show(
                                          context,
                                          'Receipt sent to WhatsApp!',
                                          type: ToastType.success,
                                        );
                                      } catch (e) {
                                        if (!context.mounted) return;

                                        setState(() => _sending = false);
                                        AppToast.show(
                                          context,
                                          'Failed to send: $e',
                                          type: ToastType.error,
                                        );
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF5a6c37),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.all(16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: _sending
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(LucideIcons.send),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
