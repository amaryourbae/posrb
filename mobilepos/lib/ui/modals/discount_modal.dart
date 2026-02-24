import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../core/providers/pos_provider.dart';
import '../../core/models/discount.dart';

class DiscountModal extends ConsumerWidget {
  final bool isOpen;
  final VoidCallback onClose;

  const DiscountModal({super.key, required this.isOpen, required this.onClose});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!isOpen) return const SizedBox.shrink();

    final state = ref.watch(posProvider);
    final notifier = ref.read(posProvider.notifier);

    // Currency formatter
    final formatCurrency = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Stack(
      children: [
        // Backdrop
        GestureDetector(
          onTap: onClose,
          child: Container(color: Colors.black.withValues(alpha: 0.6)),
        ),

        // Modal Content
        Center(
          child: Container(
            width: double.infinity,
            constraints: BoxConstraints(
              maxWidth: 450,
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            margin: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Select Discount',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF111827),
                        ),
                      ),
                      IconButton(
                        onPressed: onClose,
                        icon: const Icon(LucideIcons.x),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.grey[100],
                          foregroundColor: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),

                // Discount List
                Flexible(
                  child: state.discounts.isEmpty
                      ? _buildEmptyState()
                      : ListView.separated(
                          padding: const EdgeInsets.all(24),
                          shrinkWrap: true,
                          itemCount: state.discounts.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final discount = state.discounts[index];
                            final isSelected =
                                state.activeDiscount?.id == discount.id;
                            final isApplicable = _isApplicable(
                              discount,
                              state.subTotal,
                            );

                            return _buildDiscountCard(
                              discount,
                              isSelected,
                              isApplicable,
                              formatCurrency,
                              (d) {
                                if (!isApplicable) return;
                                if (isSelected) {
                                  notifier.removeDiscount();
                                } else {
                                  notifier.applyDiscount(d);
                                }
                              },
                            );
                          },
                        ),
                ),

                // Active Discount Warning
                if (state.activeDiscount != null &&
                    !_isApplicable(state.activeDiscount!, state.subTotal))
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    color: const Color(0xFFFEFCE8), // Yellow 50
                    width: double.infinity,
                    child: Row(
                      children: [
                        const Icon(
                          LucideIcons.alertTriangle,
                          size: 16,
                          color: Color(0xFFA16207),
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Current selection requirements not met. Discount will not apply.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFFA16207),
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
                    color: Colors.grey[50], // Gray 50
                    border: Border(top: BorderSide(color: Colors.grey[200]!)),
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      if (state.activeDiscount != null)
                        Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: OutlinedButton(
                            onPressed: () => notifier.removeDiscount(),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red[600],
                              side: BorderSide(color: Colors.red[200]!),
                              padding: const EdgeInsets.symmetric(
                                vertical: 16,
                                horizontal: 20,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Remove',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: onClose,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(
                              0xFF111827,
                            ), // Gray 900
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Close',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
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

  bool _isApplicable(Discount discount, double subTotal) {
    if (discount.minPurchase > 0 && subTotal < discount.minPurchase) {
      return false;
    }
    return true;
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          children: [
            Icon(LucideIcons.ticket, size: 48, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'No active discounts available',
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiscountCard(
    Discount discount,
    bool isSelected,
    bool isApplicable,
    NumberFormat formatCurrency,
    Function(Discount) onTap,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isApplicable ? () => onTap(discount) : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF5a6c37).withValues(alpha: 0.05)
                : (isApplicable ? Colors.transparent : Colors.grey[50]),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF5a6c37)
                  : (isApplicable ? Colors.grey[200]! : Colors.grey[100]!),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          discount.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            discount.code,
                            style: TextStyle(
                              fontSize: 12,
                              fontFamily: 'Monospace',
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          discount.type == 'fixed'
                              ? formatCurrency.format(discount.value)
                              : '${discount.value}%',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF5a6c37),
                          ),
                        ),
                        const Text(
                          'OFF',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Colors.grey[100]!),
                  ), // Default border
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      discount.minPurchase > 0
                          ? 'Min. purchase: ${formatCurrency.format(discount.minPurchase)}'
                          : 'No minimum purchase',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                    if (!isApplicable)
                      const Text(
                        'Not applicable',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      )
                    else if (isSelected)
                      const Row(
                        children: [
                          Icon(
                            LucideIcons.check,
                            size: 14,
                            color: Color(0xFF5a6c37),
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Selected',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF5a6c37),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
