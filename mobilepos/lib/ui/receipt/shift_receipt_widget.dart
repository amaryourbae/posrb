import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/utils/app_date_formatter.dart';
import '../../core/services/dio_service.dart';

class ShiftReceiptWidget extends StatelessWidget {
  final Map<String, dynamic>? shift;
  final Map<String, dynamic>? settings;
  final String userName;

  const ShiftReceiptWidget({
    super.key,
    this.shift,
    this.settings,
    required this.userName,
  });

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
  Widget build(BuildContext context) {
    if (shift == null) return const SizedBox.shrink();

    final storeName = settings?['store_name'] ?? 'POS Ruang Bincang';
    final storeAddress = settings?['store_address'] ?? '';

    // Extract from either root (current shift) or nested (shift detail)
    final fin = shift!['financials'] as Map? ?? {};
    
    final startingCash =
        double.tryParse((shift!['starting_cash'] ?? fin['starting_cash'])?.toString() ?? '0') ?? 0;
    final cashSales =
        double.tryParse((shift!['current_cash_sales'] ?? fin['cash_sales'])?.toString() ?? '0') ?? 0;
    final cashRefunds =
        double.tryParse((shift!['current_cash_refunds'] ?? fin['cash_refunds'])?.toString() ?? '0') ?? 0;
    final payIns = double.tryParse((shift!['pay_ins'] ?? fin['total_income'])?.toString() ?? '0') ?? 0;
    final payOuts = double.tryParse((shift!['pay_outs'] ?? fin['total_expense'])?.toString() ?? '0') ?? 0;
    
    final expectedCash =
        double.tryParse(
          (shift!['expected_cash'] ?? 
           shift!['ending_cash_expected'] ?? 
           fin['expected_ending_cash'])?.toString() ??
          '0',
        ) ??
        0;
        
    final actualCash =
        double.tryParse((shift!['ending_cash_actual'] ?? fin['actual_ending_cash'])?.toString() ?? '0') ?? 0;
    final difference =
        double.tryParse((shift!['difference'] ?? fin['difference'])?.toString() ?? '0') ?? 0;

    // Manual Calculation if diff missing
    final calcDiff = actualCash - expectedCash;
    final finalDiff = difference != 0 ? difference : calcDiff;

    // Items Summary
    final itemsDict = shift!['items'] as Map? ?? {};
    final salesSummary = shift!['sales_summary'] as List? ?? itemsDict['sold'] as List? ?? [];
    final refundedItems = shift!['refunded_items'] as List? ?? itemsDict['refunded'] as List? ?? [];

    // Cash movements
    final cashMovements =
        shift!['cash_movements_detail'] as List? ??
        shift!['cash_movements'] as List? ??
        shift!['movements'] as List? ??
        [];

    return Container(
      width: 190,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          if (settings?['store_logo'] != null &&
              settings!['store_logo'].toString().isNotEmpty)
            Center(
              child: Container(
                width: 120,
                height: 120,
                margin: const EdgeInsets.only(bottom: 8),
                child: Image.network(
                  getFullImageUrl(settings!['store_logo']) ?? '',
                  color: Colors.black, // Force to black
                  colorBlendMode: BlendMode.srcIn,
                  errorBuilder: (context, error, stackTrace) =>
                      const SizedBox.shrink(),
                ),
              ),
            )
          else
            Text(
              storeName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          if (storeAddress.isNotEmpty)
            Text(
              storeAddress,
              style: const TextStyle(fontSize: 10),
              textAlign: TextAlign.center,
            ),
          const SizedBox(height: 16),

          const Text(
            'SHIFT REPORT',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          _buildDashedDivider(),
          const SizedBox(height: 8),

          _infoRow('Staff', userName),
          _infoRow('Shift ID', '#${shift!['id'] ?? '-'}'),
          _infoRow(
            'Start Time',
            AppDateFormatter.formatDateFull(shift!['start_time']),
          ),
          _infoRow(
            'End Time',
            AppDateFormatter.formatDateFull(shift!['end_time']),
          ),

          const SizedBox(height: 8),
          _buildDashedDivider(),
          const SizedBox(height: 8),

          // ─── SOLD ITEMS ───
          if (salesSummary.isNotEmpty) ...[
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Items Sold',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
            const SizedBox(height: 4),
            ...salesSummary.map((item) {
              final name = item['name'] ?? '-';
              final qty = int.tryParse(item['qty']?.toString() ?? '0') ?? 0;
              return _itemRow(name, qty);
            }),
            const SizedBox(height: 4),
            _buildDashedDivider(),
            const SizedBox(height: 4),
          ],

          // ─── REFUNDED ITEMS ───
          if (refundedItems.isNotEmpty) ...[
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Items Refunded',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: Colors.red,
                ),
              ),
            ),
            const SizedBox(height: 4),
            ...refundedItems.map((item) {
              final name = item['name'] ?? '-';
              final qty = int.tryParse(item['qty']?.toString() ?? '0') ?? 0;
              return _itemRow(name, qty, isRefund: true);
            }),
            const SizedBox(height: 4),
            _buildDashedDivider(),
            const SizedBox(height: 4),
          ],

          // ─── CASH MOVEMENTS ───
          if (cashMovements.isNotEmpty) ...[
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Cash Movements',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
            const SizedBox(height: 4),
            ...cashMovements.map((mv) {
              final type = _movementLabel(mv['type']?.toString() ?? '');
              final amount =
                  double.tryParse(mv['amount']?.toString() ?? '0') ?? 0;
              final reason = mv['reason']?.toString() ?? '';
              final time = AppDateFormatter.formatTime(mv['created_at']);
              return _movementRow(type, amount, reason, time);
            }),
            const SizedBox(height: 4),
            _buildDashedDivider(),
            const SizedBox(height: 4),
          ],

          // ─── CASH SUMMARY ───
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Cash Summary',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
          const SizedBox(height: 4),
          _valueRow('Starting Cash', formatCurrency(startingCash)),
          _valueRow('Cash Sales (+)', formatCurrency(cashSales)),
          if (payIns > 0) _valueRow('Pay In (+)', formatCurrency(payIns)),
          if (cashRefunds > 0)
            _valueRow('Refunds (-)', formatCurrency(cashRefunds)),
          if (payOuts > 0) _valueRow('Pay Out (-)', formatCurrency(payOuts)),

          const SizedBox(height: 4),
          _buildDashedDivider(),
          const SizedBox(height: 4),

          _valueRow(
            'Expected Cash',
            formatCurrency(expectedCash),
            isBold: true,
          ),
          _valueRow('Actual Cash', formatCurrency(actualCash), isBold: true),

          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black, width: 1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: _valueRow(
              'Difference',
              formatCurrency(finalDiff),
              isBold: true,
            ),
          ),

          const SizedBox(height: 16),
          const Text(
            'Printed by POS System',
            style: TextStyle(fontSize: 10, color: Colors.grey),
          ),
          Text(
            AppDateFormatter.formatDateFull(DateTime.now()),
            style: const TextStyle(fontSize: 10, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  String _movementLabel(String type) {
    switch (type) {
      case 'pay_in':
        return 'Pay In';
      case 'pay_out':
        return 'Pay Out';
      case 'drop':
        return 'Cash Drop';
      default:
        return type;
    }
  }

  Widget _buildDashedDivider() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boxWidth = constraints.constrainWidth();
        const dashWidth = 5.0;
        final dashHeight = 1.0;
        final dashCount = (boxWidth / (2 * dashWidth)).floor();
        return Flex(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          direction: Axis.horizontal,
          children: List.generate(dashCount, (_) {
            return SizedBox(
              width: dashWidth,
              height: dashHeight,
              child: const DecoratedBox(
                decoration: BoxDecoration(color: Colors.black),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 10)),
          Text(
            value,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _valueRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _itemRow(String name, int qty, {bool isRefund = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        children: [
          Expanded(
            child: Text(
              name,
              style: TextStyle(
                fontSize: 11,
                color: isRefund ? Colors.red : Colors.black87,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'x$qty',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isRefund ? Colors.red : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _movementRow(String type, double amount, String reason, String time) {
    final isOut = type == 'Pay Out' || type == 'Cash Drop';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    isOut ? Icons.arrow_downward : Icons.arrow_upward,
                    size: 10,
                    color: isOut ? Colors.red : Colors.green,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    type,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isOut ? Colors.red : Colors.green,
                    ),
                  ),
                ],
              ),
              Text(
                '${isOut ? "-" : "+"}${formatCurrency(amount)}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isOut ? Colors.red : Colors.green,
                ),
              ),
            ],
          ),
          if (reason.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 14),
              child: Text(
                reason,
                style: const TextStyle(fontSize: 9, color: Colors.grey),
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(left: 14),
            child: Text(
              time,
              style: const TextStyle(fontSize: 9, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}
