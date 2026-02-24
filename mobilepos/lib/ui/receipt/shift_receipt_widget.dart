import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/utils/app_date_formatter.dart';

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

    final startingCash =
        double.tryParse(shift!['starting_cash']?.toString() ?? '0') ?? 0;
    final cashSales =
        double.tryParse(shift!['current_cash_sales']?.toString() ?? '0') ?? 0;
    final cashRefunds =
        double.tryParse(shift!['current_cash_refunds']?.toString() ?? '0') ?? 0;
    final expectedCash =
        double.tryParse(shift!['expected_cash']?.toString() ?? '0') ?? 0;
    final actualCash =
        double.tryParse(shift!['ending_cash_actual']?.toString() ?? '0') ?? 0;
    final difference =
        double.tryParse(shift!['difference']?.toString() ?? '0') ?? 0;

    // Manual Calculation if diff missing
    final calcDiff = actualCash - expectedCash;
    final finalDiff = difference != 0 ? difference : calcDiff;

    return Container(
      width: 300,
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Text(
            storeName,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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

          // Cash Summary
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
          if (cashRefunds > 0)
            _valueRow('Refunds (-)', formatCurrency(cashRefunds)),

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
            AppDateFormatter.formatDateFull(DateTime.now().toIso8601String()),
            style: const TextStyle(fontSize: 10, color: Colors.grey),
          ),
        ],
      ),
    );
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
              child: DecoratedBox(
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
}
