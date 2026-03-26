import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

class CashMovementModal extends StatefulWidget {
  final bool isOpen;
  final bool loading;
  final VoidCallback onClose;
  final Future<void> Function(String type, double amount, String reason)
  onSubmit;

  const CashMovementModal({
    super.key,
    required this.isOpen,
    this.loading = false,
    required this.onClose,
    required this.onSubmit,
  });

  @override
  State<CashMovementModal> createState() => _CashMovementModalState();
}

class _CashMovementModalState extends State<CashMovementModal> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();
  String _type = 'pay_in'; // pay_in, pay_out, drop
  String? _error;
  double _numericAmount = 0;

  @override
  void initState() {
    super.initState();
    if (widget.isOpen) {
      _reset();
    }
  }

  @override
  void didUpdateWidget(CashMovementModal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isOpen && !oldWidget.isOpen) {
      _reset();
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  void _reset() {
    _amountController.clear();
    _reasonController.clear();
    _numericAmount = 0;
    setState(() {
      _error = null;
      _type = 'pay_in';
    });
  }

  void _handleAmountChanged(String value) {
    setState(() => _error = null);

    String numericOnly = value.replaceAll(RegExp(r'[^0-9]'), '');

    if (numericOnly.isEmpty) {
      _numericAmount = 0;
      _amountController.value = TextEditingValue.empty;
      return;
    }

    double amount = double.tryParse(numericOnly) ?? 0;
    _numericAmount = amount;

    final formatted = NumberFormat.decimalPattern('id_ID').format(amount);

    _amountController.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  void _handleSubmit() {
    if (_numericAmount <= 0) {
      setState(() => _error = "Amount must be greater than 0");
      return;
    }

    if (_reasonController.text.trim().isEmpty) {
      setState(() => _error = "Reason is required");
      return;
    }

    widget.onSubmit(_type, _numericAmount, _reasonController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isOpen) return const SizedBox.shrink();

    return Stack(
      children: [
        // Backdrop
        GestureDetector(
          onTap: widget.loading ? null : widget.onClose,
          child: Container(
            color: Colors.black.withValues(alpha: 0.5),
            width: double.infinity,
            height: double.infinity,
          ),
        ),

        // Modal content
        Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              margin: const EdgeInsets.all(24),
              constraints: const BoxConstraints(maxWidth: 450),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                      border: Border(
                        bottom: BorderSide(color: Colors.grey[200]!),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Cash Movement',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF111827),
                          ),
                        ),
                        if (!widget.loading)
                          IconButton(
                            onPressed: widget.onClose,
                            padding: const EdgeInsets.all(4),
                            constraints: const BoxConstraints(),
                            icon: Icon(
                              LucideIcons.x,
                              size: 20,
                              color: Colors.grey[500],
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Body
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Type Selector
                        const Text(
                          'Movement Type',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF374151),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTypeOption(
                                'pay_in',
                                'Pay In',
                                LucideIcons.arrowDownLeft,
                                Colors.green,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildTypeOption(
                                'pay_out',
                                'Pay Out',
                                LucideIcons.arrowUpRight,
                                Colors.red,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildTypeOption(
                                'drop',
                                'Drop',
                                LucideIcons.banknote,
                                Colors.blue,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Amount Input
                        _buildInputGroup(
                          'Amount',
                          _amountController,
                          autofocus: true,
                        ),
                        const SizedBox(height: 16),

                        // Reason Input
                        const Text(
                          'Reason',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF374151),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _reasonController,
                          maxLines: 2,
                          decoration: InputDecoration(
                            hintText: 'e.g., Adding change, Buying supplies...',
                            hintStyle: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 14,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: const Color(0xFFe5e7eb),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: const Color(0xFFe5e7eb),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFF5a6c37),
                                width: 2,
                              ),
                            ),
                            contentPadding: const EdgeInsets.all(16),
                          ),
                        ),

                        // Error Message
                        if (_error != null)
                          Container(
                            margin: const EdgeInsets.only(top: 16),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFfef2f2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  LucideIcons.alertCircle,
                                  size: 16,
                                  color: Color(0xFFef4444),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _error!,
                                    style: const TextStyle(
                                      color: Color(0xFFef4444),
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Footer
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(16),
                      ),
                      border: Border(top: BorderSide(color: Colors.grey[200]!)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (!widget.loading)
                          TextButton(
                            onPressed: widget.onClose,
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.grey[600],
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed:
                              (widget.loading || _amountController.text.isEmpty)
                              ? null
                              : _handleSubmit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF5a6c37),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            elevation: 4,
                            shadowColor: const Color(
                              0xFF5a6c37,
                            ).withValues(alpha: 0.3),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            disabledBackgroundColor: const Color(
                              0xFF5a6c37,
                            ).withValues(alpha: 0.5),
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
                                  'Submit',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTypeOption(
    String value,
    String label,
    IconData icon,
    MaterialColor color,
  ) {
    final isSelected = _type == value;
    return Material(
      color: isSelected ? color.withValues(alpha: 0.1) : Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => setState(() {
          _type = value;
          _error = null;
        }),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color.shade500 : const Color(0xFFe5e7eb),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? color.shade600 : Colors.grey[500],
                size: 20,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? color.shade700 : Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputGroup(
    String label,
    TextEditingController controller, {
    bool autofocus = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFe5e7eb)),
          ),
          child: TextField(
            controller: controller,
            onChanged: _handleAmountChanged,
            keyboardType: TextInputType.number,
            autofocus: autofocus,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            decoration: const InputDecoration(
              prefixIcon: SizedBox(
                width: 50,
                child: Center(
                  child: Text(
                    'Rp',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 12),
              hintText: '0',
            ),
          ),
        ),
      ],
    );
  }
}
