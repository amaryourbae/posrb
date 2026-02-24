import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import '../core/models/customer.dart';
import '../core/models/product.dart';
import '../core/models/cart_item.dart';
import '../core/providers/pos_provider.dart';
import 'widgets/product_modifier_dialog.dart';
import 'widgets/app_toast.dart';

class CartSidebar extends ConsumerWidget {
  final bool isOverlay;
  final bool isOpen;
  final VoidCallback onClose;
  final bool showBackdrop;
  final VoidCallback? onCharge;
  final VoidCallback? onSaveBill;

  const CartSidebar({
    super.key,
    this.isOverlay = false,
    this.isOpen = true,
    this.showBackdrop = true,
    required this.onClose,
    this.onCharge,
    this.onSaveBill,
  });

  Future<void> _editCartItem(
    BuildContext context,
    WidgetRef ref,
    CartItem item,
  ) async {
    final state = ref.read(posProvider);
    final notifier = ref.read(posProvider.notifier);

    // Find product
    Product? product;
    try {
      product = state.products.firstWhere((p) => p.id == item.productId);
    } catch (_) {
      AppToast.show(
        context,
        "Product not found, cannot edit.",
        type: ToastType.error,
      );
      return;
    }

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => ProductModifierDialog(
        product: product!,
        initialModifiers: item.modifiers,
        initialNote: item.note,
      ),
    );

    if (result != null) {
      // Remove old item
      notifier.removeFromCart(item.cartId);

      // Add new item (with updated modifiers)
      notifier.addToCart(
        product,
        quantity: item.quantity,
        modifiers: result['modifiers'] as List<CartModifier>,
        note: result['note'] as String?,
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(posProvider);
    final notifier = ref.read(posProvider.notifier);
    // Indonesian Rupiah format
    final formatCurrency = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    final sidebarContent = Container(
      width: 400,
      color: Colors.white,
      child: Column(
        children: [
          // 1. Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey[100]!)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Order Details",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(LucideIcons.x, color: Colors.grey),
                  onPressed: onClose,
                ),
              ],
            ),
          ),

          // 2. Scrollable Content (Customer, Order Type, Cart Items)
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Customer & Order Type Inputs
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "CUSTOMER NAME",
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 6),
                        _buildCustomerInput(state, notifier),
                        const SizedBox(height: 16),
                        const Text(
                          "ORDER TYPE",
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 6),
                        _buildOrderTypeDropdown(state, notifier),
                      ],
                    ),
                  ),

                  // Order Items Header
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 8,
                    ),
                    child: Text(
                      "Order Items",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[900],
                      ),
                    ),
                  ),
                  const Divider(height: 1, indent: 24, endIndent: 24),

                  // Cart Items
                  state.cart.isEmpty
                      ? _buildEmptyCart()
                      : _buildCartListInColumn(
                          context,
                          ref,
                          state,
                          notifier,
                          formatCurrency,
                        ),
                ],
              ),
            ),
          ),

          // 3. Footer (Fixed at bottom)
          _buildFooter(context, state, notifier, formatCurrency),
        ],
      ),
    );

    // If overlay mode, wrap with positioning
    if (isOverlay) {
      return Stack(
        children: [
          // Backdrop
          if (isOpen && showBackdrop)
            GestureDetector(
              onTap: onClose,
              child: Container(color: Colors.black.withValues(alpha: 0.2)),
            ),

          // Sidebar
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            right: isOpen ? 0 : -400,
            top: 0,
            bottom: 0,
            child: Material(elevation: 16, child: sidebarContent),
          ),
        ],
      );
    }

    // Static mode (desktop)
    return sidebarContent;
  }

  Widget _buildCustomerInput(PosState state, PosNotifier notifier) {
    if (state.selectedCustomer != null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.green[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.green[100]!),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.green[200],
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      state.selectedCustomer!.name.isNotEmpty
                          ? state.selectedCustomer!.name
                                .substring(0, 1)
                                .toUpperCase()
                          : 'G',
                      style: TextStyle(
                        color: Colors.green[800],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      state.selectedCustomer!.name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[900],
                      ),
                    ),
                    if (state.selectedCustomer!.phone != null)
                      Text(
                        state.selectedCustomer!.phone!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green[700],
                        ),
                      ),
                  ],
                ),
              ],
            ),
            IconButton(
              icon: const Icon(LucideIcons.x, size: 16, color: Colors.red),
              onPressed: () => notifier.selectCustomer(null),
            ),
          ],
        ),
      );
    }

    return Autocomplete<Customer>(
      optionsBuilder: (TextEditingValue textEditingValue) {
        // Synchronous options builder - just filter existing state.customers
        if (textEditingValue.text.isEmpty) {
          return const Iterable<Customer>.empty();
        }

        // Use customers from state (populated by onChanged trigger)
        final guestOption = Customer.guest(textEditingValue.text);
        if (state.customers.isEmpty) {
          return [guestOption];
        }
        return [...state.customers, guestOption];
      },
      displayStringForOption: (Customer option) => option.name,
      onSelected: (Customer selection) => notifier.selectCustomer(selection),
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        return TextField(
          controller: controller,
          focusNode: focusNode,
          onChanged: (value) {
            // Trigger async search - this populates state.customers for next rebuild
            if (value.isNotEmpty) {
              notifier.searchCustomersAndUpdateState(value);
            }
          },
          decoration: InputDecoration(
            hintText: "Insert Customer Name...",
            hintStyle: TextStyle(fontSize: 14, color: Colors.grey[400]),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[200]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[200]!),
            ),
          ),
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 300,
              constraints: const BoxConstraints(maxHeight: 300),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final option = options.elementAt(index);
                  if (option.isGuest) {
                    return Container(
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(color: Colors.grey[100]!),
                        ),
                      ),
                      child: ListTile(
                        title: Text("Use \"${option.name}\" as Guest"),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            "Guest",
                            style: TextStyle(fontSize: 10, color: Colors.grey),
                          ),
                        ),
                        onTap: () => onSelected(option),
                      ),
                    );
                  }
                  return ListTile(
                    title: Text(option.name),
                    subtitle: option.phone != null ? Text(option.phone!) : null,
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        "Member",
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.green[700],
                        ),
                      ),
                    ),
                    onTap: () => onSelected(option),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildOrderTypeDropdown(PosState state, PosNotifier notifier) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: state.orderType,
          isExpanded: true,
          icon: Icon(
            LucideIcons.chevronDown,
            size: 16,
            color: Colors.grey[400],
          ),
          items: ['Dine In', 'Pickup Order']
              .map(
                (String value) => DropdownMenuItem<String>(
                  value: value,
                  child: Text(value, style: const TextStyle(fontSize: 14)),
                ),
              )
              .toList(),
          onChanged: (String? newValue) {
            if (newValue != null) notifier.setOrderType(newValue);
          },
        ),
      ),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.shoppingBag, size: 48, color: Colors.grey[200]),
          const SizedBox(height: 12),
          const Text(
            "Cart is empty",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          const Text(
            "Add items to start an order",
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildCartListInColumn(
    BuildContext context,
    WidgetRef ref,
    PosState state,
    PosNotifier notifier,
    NumberFormat formatCurrency,
  ) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: state.cart.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return Padding(
            padding: EdgeInsets.only(
              bottom: index < state.cart.length - 1 ? 16 : 0,
            ),
            child: InkWell(
              onTap: () => _editCartItem(context, ref, item),
              borderRadius: BorderRadius.circular(8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 24,
                    child: Text(
                      "${index + 1}",
                      style: const TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        if (item.modifiers.isEmpty)
                          const Text(
                            "Standard",
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          )
                        else
                          ...item.modifiers
                              .where((m) => m.showInUi)
                              .map(
                                (m) => Text(
                                  "+ ${m.displayName}",
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                        if (item.quantity > 1)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              "${item.quantity}x @ ${formatCurrency.format(item.unitPrice)}",
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF5a6c37),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        formatCurrency.format(item.totalPrice),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildActionButton(
                            LucideIcons.minus,
                            () => notifier.updateQuantity(
                              item.cartId,
                              item.quantity - 1,
                            ),
                          ),
                          const SizedBox(width: 4),
                          _buildActionButton(
                            LucideIcons.plus,
                            () => notifier.updateQuantity(
                              item.cartId,
                              item.quantity + 1,
                            ),
                          ),
                          const SizedBox(width: 4),
                          _buildActionButton(
                            LucideIcons.trash2,
                            () => notifier.removeFromCart(item.cartId),
                            isDestructive: true,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFooter(
    BuildContext context,
    PosState state,
    PosNotifier notifier,
    NumberFormat formatCurrency,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[100]!)),
      ),
      child: Column(
        children: [
          // Discount Button
          if (state.activeDiscount == null)
            OutlinedButton(
              onPressed: () => notifier.toggleDiscountModal(true),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 16,
                ),
                side: BorderSide(color: Colors.grey[300]!),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Add Discount",
                    style: TextStyle(color: Colors.grey),
                  ),
                  Icon(
                    LucideIcons.chevronRight,
                    size: 16,
                    color: Colors.grey[400],
                  ),
                ],
              ),
            )
          else
            InkWell(
              onTap: () => notifier.toggleDiscountModal(true),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF5a6c37).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF5a6c37)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      LucideIcons.ticket,
                      size: 20,
                      color: Color(0xFF5a6c37),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            state.activeDiscount!.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF5a6c37),
                            ),
                          ),
                          Text(
                            state.activeDiscount!.type == 'fixed'
                                ? "Discount: ${formatCurrency.format(state.activeDiscount!.value)}"
                                : "Discount: ${state.activeDiscount!.value}% Off",
                            style: TextStyle(
                              fontSize: 12,
                              color: const Color(
                                0xFF5a6c37,
                              ).withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        LucideIcons.x,
                        size: 16,
                        color: Colors.red,
                      ),
                      onPressed: () => notifier.removeDiscount(),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),

          // Totals
          _buildTotalRow("Sub Total", formatCurrency.format(state.subTotal)),
          if (state.activeDiscount != null) ...[
            const SizedBox(height: 8),
            _buildTotalRow(
              "Discount",
              "-${formatCurrency.format(state.discountAmount)}",
              color: Colors.red,
            ),
          ],
          if (state.tax > 0) ...[
            const SizedBox(height: 8),
            _buildTotalRow(
              "Tax (${state.taxRate.toStringAsFixed(0)}%)",
              formatCurrency.format(state.tax),
            ),
          ],
          if (state.serviceCharge > 0) ...[
            const SizedBox(height: 8),
            _buildTotalRow(
              "Service Charge (${state.serviceChargeRate.toStringAsFixed(0)}%)",
              formatCurrency.format(state.serviceCharge),
            ),
          ],
          const SizedBox(height: 12),
          _buildTotalRow(
            "Total",
            formatCurrency.format(state.total),
            isBold: true,
            fontSize: 18,
          ),

          const SizedBox(height: 24),

          // Action Buttons
          Row(
            children: [
              // View Pending Bills Button
              Container(
                margin: const EdgeInsets.only(right: 8),
                child: Tooltip(
                  message: 'View Pending Bills',
                  child: ElevatedButton(
                    onPressed: () => notifier.togglePendingBills(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.orange,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: Colors.orange),
                      ),
                      elevation: 0,
                    ),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        const Icon(LucideIcons.history, size: 20),
                        if (state.pendingCount > 0)
                          Positioned(
                            top: -6,
                            right: -6,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 14,
                                minHeight: 14,
                              ),
                              child: Text(
                                '${state.pendingCount}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 7,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              Container(
                margin: const EdgeInsets.only(right: 8),
                child: Tooltip(
                  message: 'Save Bill (Pending)',
                  child: ElevatedButton(
                    onPressed: state.cart.isEmpty ? null : onSaveBill,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                      shadowColor: Colors.orange.withValues(alpha: 0.4),
                    ),
                    child: const Icon(LucideIcons.save, size: 20),
                  ),
                ),
              ),
              Expanded(
                child: ElevatedButton(
                  onPressed: state.cart.isEmpty
                      ? null
                      : () {
                          if (onCharge != null) {
                            onCharge!();
                          } else {
                            context.push('/checkout');
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5a6c37),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    shadowColor: const Color(0xFF5a6c37).withValues(alpha: 0.4),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(LucideIcons.creditCard, size: 20),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Text(
                          "Charge ${formatCurrency.format(state.total)}",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTotalRow(
    String label,
    String value, {
    bool isBold = false,
    double fontSize = 14,
    Color? color,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: color ?? (isBold ? Colors.black : Colors.grey),
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            fontSize: fontSize,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: fontSize,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(
    IconData icon,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isDestructive ? Colors.red[50] : Colors.grey[100],
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(
          icon,
          size: 14,
          color: isDestructive ? Colors.red : Colors.grey[600],
        ),
      ),
    );
  }
}
