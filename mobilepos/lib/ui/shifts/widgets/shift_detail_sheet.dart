import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:screenshot/screenshot.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/pos_provider.dart';
import '../../../core/providers/shift_detail_provider.dart';
import '../../../core/utils/app_date_formatter.dart';
import '../../receipt/shift_receipt_widget.dart';
import '../../widgets/app_toast.dart';

class ShiftDetailSheet extends ConsumerStatefulWidget {
  final String shiftId;
  final VoidCallback? onClose;

  const ShiftDetailSheet({super.key, required this.shiftId, this.onClose});

  @override
  ConsumerState<ShiftDetailSheet> createState() => _ShiftDetailSheetState();
}

class _ShiftDetailSheetState extends ConsumerState<ShiftDetailSheet> {
  final ScreenshotController _screenshotController = ScreenshotController();
  bool _isPrinting = false;

  String _formatCurrency(double amount) {
    if (amount < 0) {
      final formatted = NumberFormat.currency(
        locale: 'id_ID',
        symbol: 'Rp. ',
        decimalDigits: 0,
      ).format(amount.abs());
      return '($formatted)';
    }
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp. ',
      decimalDigits: 0,
    ).format(amount);
  }

  Future<void> _handleEndShift() async {
    ref.read(posProvider.notifier).toggleShiftModal(true, 'end');
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  Future<void> _handlePrint(Map<String, dynamic> shift) async {
    if (kIsWeb) return;
    setState(() => _isPrinting = true);

    try {
      final authState = ref.read(authProvider);
      final settings = authState.settings;
      final userName = authState.user?['name'] ?? 'Staff';

      final image = await _screenshotController.captureFromWidget(
        Material(
          child: ShiftReceiptWidget(
            shift: shift,
            settings: settings,
            userName: userName,
          ),
        ),
        delay: const Duration(milliseconds: 100),
        context: context,
      );

      if (!mounted) return;

      final printer = BlueThermalPrinter.instance;
      final isConnected = await printer.isConnected;

      if (isConnected == true) {
        await printer.printImageBytes(image);
      } else if (mounted) {
        AppToast.show(
          context,
          'Printer not connected',
          type: ToastType.warning,
        );
      }
    } catch (e) {
      debugPrint('Print Error: $e');
      if (mounted) {
        AppToast.show(
          context,
          'Gagal mencetak: $e',
          type: ToastType.error,
        );
      }
    } finally {
      if (mounted) setState(() => _isPrinting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(shiftDetailProvider(widget.shiftId));

    if (state.isLoading) {
      return Container(
        height: 400,
        color: Colors.white,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (state.error != null || state.detail == null) {
      return Container(
        height: 400,
        color: Colors.white,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(LucideIcons.alertCircle, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Error loading shift details: ${state.error ?? 'Unknown error'}',
              ),
            ],
          ),
        ),
      );
    }

    final detail = state.detail!;
    final fin = detail['financials'];
    final itemsInfo = detail['items'];
    final bool isOngoing = detail['end_time'] == null;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Shift Details',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Cashier: ${detail['user']}',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(LucideIcons.x),
                  onPressed: widget.onClose ?? () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Dates
                  Row(
                    children: [
                      Expanded(
                        child: _buildDateInfo('Started', detail['start_time']),
                      ),
                      Expanded(
                        child: _buildDateInfo(
                          'Ended',
                          detail['end_time'] ?? 'Ongoing',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Items Summary
                  _buildSectionTitle('ITEMS'),
                  const SizedBox(height: 12),
                  _buildItemSummaryRow(
                    context,
                    'Sold Items',
                    itemsInfo['total_sold_qty'].toString(),
                    (itemsInfo['sold'] as List?) ?? [],
                  ),
                  _buildItemSummaryRow(
                    context,
                    'Refunded Items',
                    itemsInfo['total_refunded_qty'].toString(),
                    (itemsInfo['refunded'] as List?) ?? [],
                  ),
                  const SizedBox(height: 32),

                  // Financials 1 (CASH breakdown)
                  _buildSectionTitle('CASH'),
                  const SizedBox(height: 12),
                  _buildValueRow(
                    'STARTING CASH',
                    _formatCurrency(fin['starting_cash'].toDouble()),
                  ),
                  _buildValueRow(
                    'CASH SALES',
                    _formatCurrency(fin['cash_sales'].toDouble()),
                  ),
                  _buildValueRow(
                    'CASH FROM INVOICE',
                    _formatCurrency(fin['cash_from_invoice'].toDouble()),
                  ),
                  _buildValueRow(
                    'CASH REFUNDS',
                    _formatCurrency(fin['cash_refunds'].toDouble()),
                  ),
                  _buildValueRow(
                    'TOTAL EXPENSE',
                    _formatCurrency(fin['total_expense'].toDouble()),
                    isIndented: true,
                  ),
                  _buildValueRow(
                    'TOTAL INCOME',
                    _formatCurrency(fin['total_income'].toDouble()),
                    isIndented: true,
                  ),
                  _buildValueRow(
                    'EXPECTED ENDING CASH',
                    _formatCurrency(fin['expected_ending_cash'].toDouble()),
                    isBold: true,
                  ),
                  _buildValueRow(
                    'ACTUAL ENDING CASH',
                    _formatCurrency(fin['actual_ending_cash'].toDouble()),
                    isBold: true,
                  ),

                  const SizedBox(height: 32),

                  // Financials 2 (Payment details)
                  _buildSectionTitle('CASH'),
                  const SizedBox(height: 12),
                  _buildValueRow(
                    'CASH',
                    _formatCurrency(fin['cash_sales'].toDouble()),
                  ),
                  _buildValueRow(
                    'CASH REFUNDS',
                    _formatCurrency(fin['cash_refunds'].toDouble()),
                  ),
                  _buildValueRow(
                    'EXPECTED CASH PAYMENT',
                    _formatCurrency(fin['expected_cash_payment'].toDouble()),
                    isBold: true,
                  ),

                  const SizedBox(height: 32),

                  // Financials 3 (Differences)
                  _buildSectionTitle('TOTAL'),
                  const SizedBox(height: 12),
                  _buildValueRow(
                    'TOTAL EXPECTED',
                    _formatCurrency(fin['expected_ending_cash'].toDouble()),
                    isBold: true,
                  ),
                  _buildValueRow(
                    'TOTAL ACTUAL',
                    _formatCurrency(fin['actual_ending_cash'].toDouble()),
                    isBold: true,
                  ),
                  _buildValueRow(
                    'DIFFERENCE',
                    _formatCurrency(fin['difference'].toDouble()),
                    isBold: true,
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // Footer Actions
          Container(
            padding: const EdgeInsets.all(20),
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
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isPrinting ? null : () => _handlePrint(detail),
                    icon: _isPrinting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(LucideIcons.printer, size: 18),
                    label: Text(_isPrinting ? 'Printing...' : 'Print Report'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                if (isOngoing) ...[
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _handleEndShift,
                      icon: const Icon(LucideIcons.logOut, size: 18),
                      label: const Text('End Shift'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateInfo(String label, String dateString) {
    String formattedDate = dateString;
    if (dateString != 'Ongoing') {
      try {
        formattedDate = AppDateFormatter.formatDateFull(
          DateTime.parse(dateString),
        );
      } catch (_) {}
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.grey[500],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          formattedDate,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(bottom: 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey, width: 2)),
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildValueRow(
    String label,
    String value, {
    bool isBold = false,
    bool isIndented = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (isIndented)
                Icon(
                  LucideIcons.chevronRight,
                  size: 16,
                  color: Colors.grey[400],
                ),
              if (isIndented) const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
                  color: isBold ? Colors.black : Colors.grey[800],
                ),
              ),
            ],
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              color: value.startsWith('(') ? Colors.red[700] : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemSummaryRow(
    BuildContext context,
    String label,
    String qty,
    List<dynamic> items,
  ) {
    return InkWell(
      onTap: () {
        _showItemsModal(context, label, items);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            Row(
              children: [
                Text(
                  qty,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  LucideIcons.chevronRight,
                  size: 16,
                  color: Colors.grey,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showItemsModal(
    BuildContext context,
    String title,
    List<dynamic> items,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title),
              IconButton(
                icon: const Icon(LucideIcons.x),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          content: Container(
            width: 400,
            constraints: const BoxConstraints(maxHeight: 400),
            child: items.isEmpty
                ? const Center(child: Text('No items found'))
                : ListView.separated(
                    shrinkWrap: true,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 8,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                item['name']?.toString() ?? 'Item',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Text(
                              'Qty: ${item['qty'] ?? 0}',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        );
      },
    );
  }
}
