import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

class PaymentModal extends StatefulWidget {
  final bool isOpen;
  final double totalAmount;
  final bool loading;
  final VoidCallback onClose;
  final Function(Map<String, dynamic>) onProcess;
  final String? orderNumber;

  const PaymentModal({
    super.key,
    required this.isOpen,
    required this.totalAmount,
    required this.loading,
    required this.onClose,
    required this.onProcess,
    this.orderNumber,
  });

  @override
  State<PaymentModal> createState() => _PaymentModalState();
}

class _PaymentModalState extends State<PaymentModal> {
  String _selectedMethod = 'cash';
  double _amountPaid = 0;
  final TextEditingController _amountController = TextEditingController();

  String formatCurrency(double amount) {
    final format = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return format.format(amount);
  }

  double get change =>
      (_amountPaid - widget.totalAmount).clamp(0, double.infinity);

  bool get isValid {
    if (_selectedMethod == 'cash') {
      return _amountPaid >= widget.totalAmount;
    }
    return true;
  }

  List<double> get quickAmounts {
    final total = widget.totalAmount;
    final suggestions = <double>{total};

    if (total % 10000 != 0) {
      suggestions.add((total / 10000).ceil() * 10000);
    }
    suggestions.add((total / 20000).ceil() * 20000);
    suggestions.add((total / 50000).ceil() * 50000);
    suggestions.add((total / 100000).ceil() * 100000);

    return suggestions.where((amount) => amount >= total).toList()
      ..sort()
      ..take(4);
  }

  void _selectMethod(String method) {
    setState(() {
      _selectedMethod = method;
      if (method == 'cash') {
        _amountPaid = 0;
        _amountController.text = '';
      } else {
        _amountPaid = widget.totalAmount;
        _amountController.text = widget.totalAmount.toStringAsFixed(0);
      }
    });
  }

  void _setAmount(double amount) {
    setState(() {
      _amountPaid = amount;
      _amountController.text = amount.toStringAsFixed(0);
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
        // Backdrop
        GestureDetector(
          onTap: widget.onClose,
          child: Container(color: Colors.black.withValues(alpha: 0.4)),
        ),

        // Modal
        Center(
          child: Container(
            width: 480,
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
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text(
                                'Payment',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (widget.orderNumber != null) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    widget.orderNumber!,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          RichText(
                            text: TextSpan(
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                              children: [
                                const TextSpan(text: 'Total Bill: '),
                                TextSpan(
                                  text: formatCurrency(widget.totalAmount),
                                  style: const TextStyle(
                                    color: Color(0xFF5a6c37),
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: widget.onClose,
                        icon: Icon(LucideIcons.x, color: Colors.grey[400]),
                      ),
                    ],
                  ),
                ),

                // Content
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Payment Methods
                        Text(
                          'SELECT PAYMENT METHOD',
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
                            _buildMethodButton(
                              id: 'cash',
                              label: 'Cash',
                              icon: LucideIcons.banknote,
                            ),
                            const SizedBox(width: 12),
                            _buildMethodButton(
                              id: 'qris',
                              label: 'QRIS',
                              icon: LucideIcons.qrCode,
                            ),
                            const SizedBox(width: 12),
                            _buildMethodButton(
                              id: 'debit',
                              label: 'Debit/Credit',
                              icon: LucideIcons.creditCard,
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Cash Payment Section
                        if (_selectedMethod == 'cash') ...[
                          Text(
                            'AMOUNT PAID',
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
                                hintText: '0',
                              ),
                              onChanged: (value) {
                                setState(() {
                                  _amountPaid = double.tryParse(value) ?? 0;
                                });
                              },
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Quick Amounts
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: quickAmounts.take(4).map((amount) {
                              final isExact = amount == widget.totalAmount;
                              final isSelected = _amountPaid == amount;
                              return GestureDetector(
                                onTap: () => _setAmount(amount),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? const Color(0xFF5a6c37)
                                        : Colors.grey[100],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    isExact ? 'Exact' : formatCurrency(amount),
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.grey[700],
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),

                          const SizedBox(height: 16),

                          // Change Display
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.green[50],
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.green[100]!),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Change Return',
                                  style: TextStyle(
                                    color: Colors.green[700],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  formatCurrency(change),
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        // QRIS Section
                        if (_selectedMethod == 'qris')
                          Center(
                            child: Column(
                              children: [
                                Container(
                                  width: 192,
                                  height: 192,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[900],
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      LucideIcons.qrCode,
                                      size: 96,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Scan QR Code to Pay',
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Debit Section
                        if (_selectedMethod == 'debit')
                          Center(
                            child: Column(
                              children: [
                                Icon(
                                  LucideIcons.creditCard,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Insert or Tap Card',
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
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
                      onPressed: isValid && !widget.loading
                          ? () {
                              widget.onProcess({
                                'method': _selectedMethod,
                                'amount_paid': _amountPaid,
                                'change': change,
                              });
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5a6c37),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
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
                              'Confirm Payment',
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

  Widget _buildMethodButton({
    required String id,
    required String label,
    required IconData icon,
  }) {
    final isSelected = _selectedMethod == id;
    return Expanded(
      child: GestureDetector(
        onTap: () => _selectMethod(id),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF5a6c37).withValues(alpha: 0.05)
                : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              width: 2,
              color: isSelected ? const Color(0xFF5a6c37) : Colors.grey[100]!,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 32,
                color: isSelected ? const Color(0xFF5a6c37) : Colors.grey[500],
              ),
              const SizedBox(height: 8),
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
