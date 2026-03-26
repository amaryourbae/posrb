import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/utils/app_date_formatter.dart';
import '../../core/utils/product_helper.dart';
import '../../core/services/dio_service.dart';

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
    final receiptFooter =
        settings?['receipt_footer']?.toString().isNotEmpty == true
        ? settings!['receipt_footer'].toString()
        : 'Dapatkan 1 minuman gratis dan berbagai keuntungan dengan mengumpulkan poin.';

    return Theme(
      data: ThemeData(
        brightness: Brightness.light,
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Colors.black),
          bodySmall: TextStyle(color: Colors.black),
        ),
      ),
      child: Container(
        width: 128,
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
        color: Colors.white,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (settings?['store_logo'] != null &&
                    settings!['store_logo'].toString().isNotEmpty)
                  Center(
                    child: Container(
                      width: 80,
                      height: 80,
                      margin: const EdgeInsets.only(bottom: 1),
                      child: Image.network(
                        getFullImageUrl(settings!['store_logo']) ?? '',
                        color: Colors.black,
                        colorBlendMode: BlendMode.srcIn,
                        errorBuilder: (context, error, stackTrace) =>
                            const SizedBox.shrink(),
                      ),
                    ),
                  )
                else
                  Container(
                    width: 28,
                    height: 28,
                    margin: const EdgeInsets.only(bottom: 1),
                    decoration: BoxDecoration(
                      color: const Color(0xFF5a6c37),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Center(
                      child: Text(
                        'R',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontStyle: FontStyle.italic,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                Text(
                  storeName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 8,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (storeAddress.isNotEmpty)
                  Text(
                    storeAddress,
                    style: const TextStyle(fontSize: 7, color: Colors.black),
                    textAlign: TextAlign.center,
                  ),
                if (storePhone.isNotEmpty)
                  Text(
                    storePhone,
                    style: const TextStyle(fontSize: 7, color: Colors.black),
                    textAlign: TextAlign.center,
                  ),
              ],
            ),

            _buildDottedDivider(),
            Column(
              children: [
                Text(
                  shortOrderNumber,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  orderType,
                  style: const TextStyle(
                    fontSize: 7,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 4),

            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _infoRow('Nama Customer:', customerName),
                Text(
                  AppDateFormatter.formatLongDateFull(order!['created_at']),
                  style: const TextStyle(fontSize: 7, color: Colors.black),
                ),
                Text(
                  '#$orderNumber',
                  style: const TextStyle(fontSize: 7, color: Colors.black),
                ),
              ],
            ),

            _buildDottedDivider(),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Order',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 7,
                    color: Colors.black,
                  ),
                ),
                Text(
                  'Total Order: ${items.length}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 7,
                    color: Colors.black,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 4),

            ...items.map((item) => _buildItemRow(item, ref)),

            _buildDottedDivider(),

            _totalRow('Sub Total', 'Rp ${formatNumber(subtotal)}'),

            if (discountAmount > 0)
              _totalRow(
                'Voucher Discount',
                '-Rp ${formatNumber(discountAmount)}',
              ),

            _totalRow(
              'SUBTOTAL',
              'Rp ${formatNumber(grandTotal - taxAmount - serviceCharge)}',
              isBold: true,
            ),

            _buildDottedDivider(),

            if (taxAmount > 0 || serviceCharge > 0)
              _totalRow(
                'Net sales',
                'Rp ${formatNumber(subtotal - discountAmount)}',
                fontSize: 7,
              ),
            if (taxAmount > 0)
              _totalRow(
                'PB1 $taxRate%',
                'Rp ${formatNumber(taxAmount)}',
                fontSize: 7,
              ),
            if (serviceCharge > 0)
              _totalRow(
                'Service Charge',
                'Rp ${formatNumber(serviceCharge)}',
                fontSize: 7,
              ),

            _buildDottedDivider(),

            _totalRow(
              'Total Pembayaran',
              'Rp ${formatNumber(grandTotal)}',
              isBold: true,
              fontSize: 8,
            ),
            _totalRow('Metode Pembayaran', paymentMethod, fontSize: 7),

            Column(
              children: [
                const SizedBox(height: 4),
                const Text(
                  'Terima Kasih',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  receiptFooter,
                  style: const TextStyle(fontSize: 7, color: Colors.black),
                  textAlign: TextAlign.center,
                ),
                if (storeWebsite.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      storeWebsite,
                      style: const TextStyle(fontSize: 7, color: Colors.black),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDottedDivider() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
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
    return Text(
      '$label $value',
      style: const TextStyle(fontSize: 7, color: Colors.black),
    );
  }

  Widget _buildItemRow(dynamic item, WidgetRef ref) {
    final quantity = int.tryParse(item['quantity']?.toString() ?? '1') ?? 1;
    final totalPrice =
        double.tryParse(item['total_price']?.toString() ?? '0') ?? 0;

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
            width: 18,
            child: Text(
              '${quantity}x',
              style: const TextStyle(fontSize: 7, color: Colors.black),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  productName,
                  style: const TextStyle(fontSize: 7, color: Colors.black),
                ),
                if (_getDisplayNote(item).isNotEmpty)
                  Text(
                    '"${_getDisplayNote(item)}"',
                    style: const TextStyle(
                      fontSize: 6,
                      fontStyle: FontStyle.italic,
                      color: Colors.black87,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          Text(
            formatNumber(totalPrice),
            style: const TextStyle(fontSize: 7, color: Colors.black),
          ),
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
              color: Colors.black,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
