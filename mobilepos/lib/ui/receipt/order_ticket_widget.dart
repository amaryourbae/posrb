import 'package:flutter/material.dart';
import '../../core/utils/app_date_formatter.dart';
import '../../core/utils/product_helper.dart';

class OrderTicketWidget extends StatelessWidget {
  final Map<String, dynamic>? order;
  final bool isAdditional;

  const OrderTicketWidget({
    super.key,
    this.order,
    this.isAdditional = false,
  });

  @override
  Widget build(BuildContext context) {
    if (order == null) return const SizedBox.shrink();

    final orderNumber = order!['order_number'] ?? 'Order';
    final shortOrderNumber = orderNumber.toString().split('-').last;
    final orderType = (order!['order_type'] ?? 'Takeaway')
        .toString()
        .replaceAll('_', ' ')
        .toUpperCase();
    final customerName = order!['customer_name'] ?? 'Guest';
    final items = order!['items'] as List<dynamic>? ?? [];

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
          children: [
            Text(
              isAdditional ? 'ADDITIONAL ORDER' : 'NEW ORDER',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 4),
            
            _buildDashedDivider(),
            const SizedBox(height: 4),

            Text(
              shortOrderNumber,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 6),

            Text(
              'Date: ${AppDateFormatter.formatLongDateFull(order!['created_at'])}',
              style: const TextStyle(fontSize: 7, color: Colors.black),
            ),
            Text(
              'Customer: $customerName',
              style: const TextStyle(
                fontSize: 7, 
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),

            const SizedBox(height: 6),
            
            _buildDashedDivider(),
            const SizedBox(height: 2),
            Text(
              orderType,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.0,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 2),
            _buildDashedDivider(),
            const SizedBox(height: 6),

            ...items.map((item) => _buildItemRow(item)),

            const SizedBox(height: 4),
            _buildDashedDivider(),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildItemRow(dynamic item) {
    final quantity = int.tryParse(item['quantity']?.toString() ?? '1') ?? 1;
    final mods = item['modifiers'] as List<dynamic>? ?? [];
    final name = ProductHelper.getFormattedProductName(
      item['product_name'] ?? item['name'] ?? 'Item',
      mods,
    );
    final visibleMods = ProductHelper.getVisibleModifiers(mods);

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${quantity}x ',
                style: const TextStyle(
                  fontSize: 8, 
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    fontSize: 8, 
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
          ...visibleMods.map(
            (mod) => Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Text(
                '- ${ProductHelper.getModifierDisplayName(mod)}',
                style: const TextStyle(fontSize: 7, color: Colors.black87),
              ),
            ),
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
              child: const DecoratedBox(
                decoration: BoxDecoration(color: Colors.black),
              ),
            );
          }),
        );
      },
    );
  }
}
