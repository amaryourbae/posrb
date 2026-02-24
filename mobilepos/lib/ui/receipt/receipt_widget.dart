import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/utils/app_date_formatter.dart';
import '../../core/utils/product_helper.dart';

class ReceiptWidget extends ConsumerWidget {
  final Map<String, dynamic>? order;
  final Map<String, dynamic>? settings;

  const ReceiptWidget({super.key, this.order, this.settings});

  String formatNumber(dynamic num) {
    if (num == null) return '0';
    final number = double.tryParse(num.toString()) ?? 0;
    return NumberFormat('#,###', 'id_ID').format(number);
  }

  String formatCurrency(dynamic num) {
    if (num == null) return 'Rp 0';
    final number = double.tryParse(num.toString()) ?? 0;
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(number);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (order == null) return const SizedBox.shrink();

    final items = order!['items'] as List<dynamic>? ?? [];
    final orderNumber = order!['order_number'] ?? '';
    final shortOrderNumber = orderNumber.toString().split('-').last;
    final orderType = order!['order_type'] == 'dine_in'
        ? 'Dine In'
        : 'Pick up Order';
    final customerName = order!['customer_name'] ?? 'Guest';
    final subtotal =
        double.tryParse(order!['subtotal']?.toString() ?? '0') ?? 0;
    final discountAmount =
        double.tryParse(order!['discount_amount']?.toString() ?? '0') ?? 0;
    final taxAmount =
        double.tryParse(order!['tax_amount']?.toString() ?? '0') ?? 0;
    final serviceCharge =
        double.tryParse(order!['service_charge']?.toString() ?? '0') ?? 0;
    final grandTotal =
        double.tryParse(order!['grand_total']?.toString() ?? '0') ?? 0;
    final paymentMethod =
        order!['payment_method']?.toString().toUpperCase() ?? 'CASH';

    final storeName = settings?['store_name'] ?? 'POS Store';
    final storeAddress = settings?['store_address'] ?? '';
    final storePhone = settings?['store_phone'] ?? '';
    final storeWebsite = settings?['store_website'] ?? '';
    final taxRate = settings?['tax_rate']?.toString() ?? '10';
    final serviceRate = settings?['service_charge_rate']?.toString() ?? '0';

    return Container(
      width: 280,
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF5a6c37),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Text(
                    'R',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontStyle: FontStyle.italic,
                      fontSize: 20,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                storeName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              if (storeAddress.isNotEmpty)
                Text(
                  storeAddress,
                  style: const TextStyle(fontSize: 10),
                  textAlign: TextAlign.center,
                ),
              if (storePhone.isNotEmpty)
                Text(storePhone, style: const TextStyle(fontSize: 10)),
            ],
          ),

          _buildDottedDivider(),
          Column(
            children: [
              Text(
                shortOrderNumber,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(orderType, style: const TextStyle(fontSize: 10)),
            ],
          ),

          const SizedBox(height: 8),

          // Order Info
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _infoRow('Nama Customer:', customerName),
              Text(
                AppDateFormatter.formatLongDateFull(order!['created_at']),
                style: const TextStyle(fontSize: 10),
              ),
              Text('#$orderNumber', style: const TextStyle(fontSize: 10)),
            ],
          ),

          _buildDottedDivider(),

          // Items Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Order',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
              ),
              Text(
                'Total Order: ${items.length}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Items
          ...items.map((item) => _buildItemRow(item, ref)),

          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.grey[400]!)),
            ),
          ),

          // Subtotals
          _totalRow('Sub Total', 'Rp ${formatNumber(subtotal)}'),

          if (discountAmount > 0)
            _totalRow('Discount', '-Rp ${formatNumber(discountAmount)}'),

          _totalRow(
            'SUBTOTAL',
            'Rp ${formatNumber(grandTotal - taxAmount - serviceCharge)}',
            isBold: true,
          ),

          _buildDottedDivider(),

          // Tax Breakdown
          _totalRow(
            'Net sales',
            'Rp ${formatNumber(subtotal - discountAmount)}',
            fontSize: 9,
          ),
          if (double.tryParse(taxRate) != null && double.parse(taxRate) > 0)
            _totalRow(
              'PB1 $taxRate%',
              'Rp ${formatNumber(taxAmount)}',
              fontSize: 9,
            ),
          if (double.tryParse(serviceRate) != null &&
              double.parse(serviceRate) > 0)
            _totalRow(
              'Service Charge',
              'Rp ${formatNumber(serviceCharge)}',
              fontSize: 9,
            ),

          _buildDottedDivider(),

          // Grand Total
          _totalRow(
            'Total Pembayaran',
            'Rp ${formatNumber(grandTotal)}',
            isBold: true,
            fontSize: 12,
          ),
          _totalRow('Metode Pembayaran', paymentMethod, fontSize: 11),

          _buildDottedDivider(),

          // Footer
          Column(
            children: [
              const SizedBox(height: 8),
              const Text(
                'Terima Kasih',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              Text(
                '$storeName - Alam Bercerita, Kopi Menyapa',
                style: const TextStyle(fontSize: 10),
                textAlign: TextAlign.center,
              ),
              if (storeWebsite.isNotEmpty)
                Text(storeWebsite, style: const TextStyle(fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDottedDivider() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      height: 1,
      child: Row(
        children: List.generate(
          40,
          (index) => Expanded(
            child: Container(
              height: 1,
              color: index.isEven ? Colors.black : Colors.transparent,
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Text('$label $value', style: const TextStyle(fontSize: 10));
  }

  Widget _buildItemRow(dynamic item, WidgetRef ref) {
    final quantity = int.tryParse(item['quantity']?.toString() ?? '1') ?? 1;
    final totalPrice =
        double.tryParse(item['total_price']?.toString() ?? '0') ?? 0;

    final visibleModifiers = ProductHelper.getVisibleModifiers(
      item['modifiers'] as List<dynamic>? ?? [],
    );
    final productName = ProductHelper.getFormattedProductName(
      item['product_name'] ?? item['name'] ?? 'Item',
      item['modifiers'] as List<dynamic>? ?? [],
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 24,
            child: Text('${quantity}x', style: const TextStyle(fontSize: 10)),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(productName, style: const TextStyle(fontSize: 10)),
                // Modifiers
                if (visibleModifiers.isNotEmpty)
                  ...visibleModifiers.map(
                    (mod) => Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Text(
                        '+ ${ProductHelper.getModifierDisplayName(mod)}',
                        style: const TextStyle(fontSize: 8, color: Colors.grey),
                      ),
                    ),
                  ),
                // Notes
                if (_getDisplayNote(item).isNotEmpty)
                  Text(
                    '"${_getDisplayNote(item)}"',
                    style: const TextStyle(
                      fontSize: 8,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
          ),
          Text(formatNumber(totalPrice), style: const TextStyle(fontSize: 10)),
        ],
      ),
    );
  }

  String _getDisplayNote(dynamic item) {
    if (item['note'] == null) return '';
    String note = item['note'].toString();

    final modifiers = item['modifiers'] as List<dynamic>? ?? [];
    if (modifiers.isNotEmpty) {
      final modString = modifiers
          .map((m) => m['option_name'] ?? m['name'] ?? '')
          .join(', ');
      if (note.startsWith(modString)) {
        note = note.substring(modString.length).trim();
        if (note.startsWith('.') || note.startsWith(',')) {
          note = note.substring(1).trim();
        }
      }
    }
    return note;
  }

  Widget _totalRow(
    String label,
    String value, {
    bool isBold = false,
    double fontSize = 10,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
