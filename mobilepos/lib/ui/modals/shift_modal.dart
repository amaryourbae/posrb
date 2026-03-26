import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

class ShiftModal extends StatefulWidget {
  final bool isOpen;
  final bool isForce;
  final String mode;
  final bool loading;
  final double? expectedCash;
  final VoidCallback? onClose;
  final Future<void> Function(double amount, String note) onSubmit;

  const ShiftModal({
    super.key,
    required this.isOpen,
    this.isForce = false,
    this.mode = 'start',
    this.loading = false,
    this.expectedCash,
    this.onClose,
    required this.onSubmit,
  });

  @override
  State<ShiftModal> createState() => _ShiftModalState();
}

class _ShiftModalState extends State<ShiftModal> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
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
  void didUpdateWidget(ShiftModal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isOpen && !oldWidget.isOpen) {
      _reset();
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _reset() {
    _amountController.clear();
    _noteController.clear();
    _numericAmount = 0;
    setState(() => _error = null);
  }

  void _handleAmountChanged(String value) {
    setState(() => _error = null);

    // Remove non-digits
    String numericOnly = value.replaceAll(RegExp(r'[^0-9]'), '');

    if (numericOnly.isEmpty) {
      _numericAmount = 0;
      _amountController.value = TextEditingValue.empty;
      return;
    }

    // Parse to number
    double amount = double.tryParse(numericOnly) ?? 0;
    _numericAmount = amount;

    // Format with ID locale
    final formatted = NumberFormat.decimalPattern('id_ID').format(amount);

    _amountController.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  void _handleSubmit() {
    if (_numericAmount <= 0) {}

    if (_amountController.text.isEmpty) {
      setState(() => _error = "Amount is required");
      return;
    }

    widget.onSubmit(_numericAmount, _noteController.text);
  }

  String _formatCurrency(double amount) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(amount);
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isOpen) return const SizedBox.shrink();

    return Stack(
      children: [
        // Backdrop
        GestureDetector(
          onTap: widget.isForce ? null : widget.onClose,
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
              constraints: const BoxConstraints(maxWidth: 400),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16), // rounded-2xl
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
                        Text(
                          widget.mode == 'start' ? 'Start Shift' : 'End Shift',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF111827), // Gray 900
                          ),
                        ),
                        if (!widget.isForce && widget.onClose != null)
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: widget.onClose,
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.transparent,
                                ),
                                child: Icon(
                                  LucideIcons.x,
                                  size: 20,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Body
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        if (widget.mode == 'start') ...[
                          Text(
                            'Please input the initial cash amount in the drawer to start your shift.',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildInputGroup(
                            'Starting Cash',
                            _amountController,
                            autofocus: true,
                          ),
                        ] else ...[
                          Text(
                            'You are about to close your shift. Please verify the cash amount.',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 16),

                          if (widget.expectedCash != null)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFeff6ff), // Blue 50
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  const Text(
                                    'Expected Cash: ',
                                    style: TextStyle(
                                      color: Color(0xFF2563eb), // Blue 600
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    _formatCurrency(widget.expectedCash!),
                                    style: const TextStyle(
                                      color: Color(0xFF1e40af), // Blue 800
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          _buildInputGroup(
                            'Actual Cash Amount',
                            _amountController,
                          ),
                          const SizedBox(height: 12),
                          _buildNoteInput(),
                        ],

                        // Error Message
                        if (_error != null)
                          Container(
                            margin: const EdgeInsets.only(top: 16),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFfef2f2), // Red 50
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
                        if (!widget.isForce && widget.onClose != null)
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
                              (widget.loading ||
                                  (_amountController.text.isEmpty))
                              ? null
                              : _handleSubmit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(
                              0xFF5a6c37,
                            ), // Primary Green
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
                              : Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      widget.mode == 'start'
                                          ? 'Open Shift'
                                          : 'End Shift',
                                      style: const TextStyle(
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
        ),
      ],
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
            color: Color(0xFF374151), // Gray 700
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFe5e7eb)), // Gray 200
          ),
          child: TextField(
            controller: controller,
            onChanged: _handleAmountChanged,
            keyboardType: TextInputType.number,
            autofocus: autofocus,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              prefixIcon: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                alignment: Alignment.center,
                width: 50,
                child: const Text(
                  'Rp',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              hintText: '0',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNoteInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Note (Optional)',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _noteController,
          maxLines: 2,
          decoration: InputDecoration(
            hintText: 'Any discrepancies or notes...',
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: const Color(0xFFe5e7eb)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: const Color(0xFFe5e7eb)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF5a6c37), width: 2),
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
      ],
    );
  }
}
