import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

class SplitBillModal extends StatefulWidget {
  final bool isOpen;
  final double totalAmount;
  final bool loading;
  final VoidCallback onClose;
  final Function(List<Map<String, dynamic>>) onProcess;

  const SplitBillModal({
    super.key,
    required this.isOpen,
    required this.totalAmount,
    required this.loading,
    required this.onClose,
    required this.onProcess,
  });

  @override
  State<SplitBillModal> createState() => _SplitBillModalState();
}

class _SplitBillModalState extends State<SplitBillModal> {
  final List<Map<String, dynamic>> _payments = [];
  String _selectedMethod = 'cash';
  final TextEditingController _amountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.isOpen) {
      _reset();
    }
  }

  @override
  void didUpdateWidget(SplitBillModal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isOpen && !oldWidget.isOpen) {
      _reset();
    }
  }

  void _reset() {
    _payments.clear();
    _amountController.text = _remaining.toStringAsFixed(0);
    _selectedMethod = 'cash';
    setState(() {});
  }

  double get _totalPaid =>
      _payments.fold(0.0, (sum, item) => sum + (item['amount'] as double));
  double get _remaining =>
      (widget.totalAmount - _totalPaid).clamp(0.0, double.infinity);
  bool get _isFullyPaid => _totalPaid >= widget.totalAmount;

  String formatCurrency(double amount) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(amount);
  }

  void _addPayment() {
    double amount = double.tryParse(_amountController.text) ?? 0;
    if (amount <= 0) return;

    if (_selectedMethod != 'cash' && amount > _remaining) {
      amount = _remaining; // Only cash can have change right now
    }

    setState(() {
      _payments.add({
        'method': _selectedMethod,
        'amount': amount,
        'status': 'paid',
      });
      _amountController.text = _remaining.toStringAsFixed(0);
    });
  }

  void _removePayment(int index) {
    setState(() {
      _payments.removeAt(index);
      _amountController.text = _remaining.toStringAsFixed(0);
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isOpen) return const SizedBox.shrink();

    return Stack(
      children: [
        GestureDetector(
          onTap: widget.loading ? null : widget.onClose,
          child: Container(color: Colors.black.withValues(alpha: 0.4)),
        ),
        Center(
          child: Container(
            width: 600,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.9,
            ),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
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
                // Header
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                    border: Border(
                      bottom: BorderSide(color: Colors.grey[100]!),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Split Bill / Partial Payment',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        onPressed: widget.loading ? null : widget.onClose,
                        icon: Icon(LucideIcons.x, color: Colors.grey[400]),
                      ),
                    ],
                  ),
                ),

                // Content
                Flexible(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Left: Input Section
                      Expanded(
                        flex: 5,
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '1. SELECT METHOD',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[400],
                                  letterSpacing: 1,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  _buildMethodBtn(
                                    'cash',
                                    'Cash',
                                    LucideIcons.banknote,
                                  ),
                                  const SizedBox(width: 8),
                                  _buildMethodBtn(
                                    'qris',
                                    'QRIS',
                                    LucideIcons.qrCode,
                                  ),
                                  const SizedBox(width: 8),
                                  _buildMethodBtn(
                                    'debit',
                                    'Card',
                                    LucideIcons.creditCard,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),

                              Text(
                                '2. INPUT AMOUNT',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[400],
                                  letterSpacing: 1,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.grey[200]!),
                                ),
                                child: TextField(
                                  controller: _amountController,
                                  keyboardType: TextInputType.number,
                                  enabled: !_isFullyPaid,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  decoration: InputDecoration(
                                    prefixText: 'Rp ',
                                    prefixStyle: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[400],
                                    ),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.all(16),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: _isFullyPaid ? null : _addPayment,
                                  icon: const Icon(LucideIcons.plus, size: 18),
                                  label: const Text('Add Payment'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFF3F4F6),
                                    foregroundColor: const Color(0xFF111827),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Divider
                      Container(width: 1, color: Colors.grey[200]),

                      // Right: Summary Section
                      Expanded(
                        flex: 4,
                        child: Container(
                          color: Colors.grey[50],
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'PAYMENT SUMMARY',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[500],
                                  letterSpacing: 1,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _buildSummaryRow(
                                'Total Bill',
                                widget.totalAmount,
                                isBold: true,
                              ),
                              const SizedBox(height: 8),
                              _buildSummaryRow(
                                'Total Paid',
                                _totalPaid,
                                color: const Color(0xFF5a6c37),
                              ),
                              const Divider(height: 24),
                              if (_isFullyPaid)
                                _buildSummaryRow(
                                  'Change',
                                  _totalPaid - widget.totalAmount,
                                  isBold: true,
                                  color: Colors.green,
                                )
                              else
                                _buildSummaryRow(
                                  'Remaining',
                                  _remaining,
                                  isBold: true,
                                  color: Colors.red,
                                ),

                              const SizedBox(height: 24),
                              Text(
                                'TRANSACTIONS',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[500],
                                  letterSpacing: 1,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Expanded(
                                child: _payments.isEmpty
                                    ? Center(
                                        child: Text(
                                          'No payments added',
                                          style: TextStyle(
                                            color: Colors.grey[400],
                                          ),
                                        ),
                                      )
                                    : ListView.builder(
                                        itemCount: _payments.length,
                                        itemBuilder: (context, index) {
                                          final p = _payments[index];
                                          return Container(
                                            margin: const EdgeInsets.only(
                                              bottom: 8,
                                            ),
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              border: Border.all(
                                                color: Colors.grey[200]!,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      p['method']
                                                          .toString()
                                                          .toUpperCase(),
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 13,
                                                      ),
                                                    ),
                                                    Text(
                                                      formatCurrency(
                                                        p['amount'],
                                                      ),
                                                      style: TextStyle(
                                                        color: Colors.grey[600],
                                                        fontSize: 13,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                IconButton(
                                                  icon: const Icon(
                                                    LucideIcons.trash2,
                                                    size: 16,
                                                    color: Colors.red,
                                                  ),
                                                  onPressed: () =>
                                                      _removePayment(index),
                                                  constraints:
                                                      const BoxConstraints(),
                                                  padding: EdgeInsets.zero,
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Footer
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: Colors.grey[100]!)),
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isFullyPaid && !widget.loading
                          ? () => widget.onProcess(_payments)
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5a6c37),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: widget.loading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Confirm Split Payment',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(
    String label,
    double amount, {
    bool isBold = false,
    Color? color,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: Colors.grey[600],
            fontSize: isBold ? 16 : 14,
          ),
        ),
        Text(
          formatCurrency(amount),
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            color: color ?? Colors.grey[800],
            fontSize: isBold ? 16 : 14,
          ),
        ),
      ],
    );
  }

  Widget _buildMethodBtn(String id, String label, IconData icon) {
    bool isSelected = _selectedMethod == id;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedMethod = id),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF5a6c37).withValues(alpha: 0.1)
                : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? const Color(0xFF5a6c37) : Colors.grey[200]!,
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 24,
                color: isSelected ? const Color(0xFF5a6c37) : Colors.grey[500],
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isSelected
                      ? const Color(0xFF5a6c37)
                      : Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
