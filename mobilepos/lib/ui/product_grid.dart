import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../core/providers/pos_provider.dart';
import '../core/models/product.dart';
import '../core/models/cart_item.dart';
import '../core/services/dio_service.dart';
import 'widgets/product_modifier_dialog.dart';
import 'widgets/skeleton.dart';

class ProductGrid extends ConsumerWidget {
  const ProductGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(posProvider);

    if (state.loading) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: ProductGridSkeleton(itemCount: 12, crossAxisCount: 4),
      );
    }

    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Error: ${state.error}",
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.read(posProvider.notifier).fetchProducts(),
              child: const Text("Retry"),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: const Color(0xFF5a6c37),
      onRefresh: () => ref.read(posProvider.notifier).fetchProducts(),
      child: GridView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: _getCrossAxisCount(context),
          childAspectRatio: 0.8,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: state.filteredProducts.length,
        itemBuilder: (context, index) {
          final product = state.filteredProducts[index];
          return ProductCard(product: product);
        },
      ),
    );
  }

  static int _getCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 600) return 2; // Smartphone
    if (width < 1024) return 3; // Tablet
    return 4; // Desktop
  }
}

class ProductCard extends ConsumerWidget {
  final Product product;

  const ProductCard({required this.product, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formatCurrency = NumberFormat.simpleCurrency(locale: 'id_ID');
    final isLowStock =
        product.lowStock == true ||
        (!product.hasRecipe && product.currentStock <= 0);

    return GestureDetector(
      onTap: isLowStock
          ? null
          : () async {
              if (product.modifiers.isNotEmpty) {
                final result = await showDialog<Map<String, dynamic>>(
                  context: context,
                  builder: (context) => ProductModifierDialog(product: product),
                );

                if (result != null) {
                  final modifiers = result['modifiers'] as List<CartModifier>;
                  final note = result['note'] as String?;
                  ref
                      .read(posProvider.notifier)
                      .addToCart(product, modifiers: modifiers, note: note);
                  ref.read(posProvider.notifier).setCartOpen(true);
                }
              } else {
                // No modifiers, add directly
                ref
                    .read(posProvider.notifier)
                    .addToCart(product, modifiers: []);
                ref.read(posProvider.notifier).setCartOpen(true);
              }
            },
      child: Opacity(
        opacity: isLowStock ? 0.5 : 1.0,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16), // rounded-xl
            border: Border.all(
              color: Colors.transparent,
            ), // Border invisible by default
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Area
              Expanded(
                child: Stack(
                  children: [
                    Container(
                      margin: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.grey[100],
                      ),
                      child: _buildProductImage(product.imageUrl),
                    ),
                    // Badges (Low Stock)
                    if (isLowStock)
                      Positioned(
                        top: 16,
                        right: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red[600],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            product.hasRecipe ? "Low Ingredients" : "Low Stock",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // Info Area
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          formatCurrency.format(
                            product.getPriceForSalesType(
                              ref.watch(posProvider).selectedSalesType?.slug,
                            ),
                          ),
                          style: TextStyle(
                            color: const Color(0xFF5a6c37),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        if (product.currentStock > 0 ||
                            product.trackStock == false)
                          Text(
                            product.trackStock
                                ? "Stk: ${product.currentStock.toInt()}"
                                : "",
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[400],
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

  Widget _buildProductImage(String? imageUrl) {
    final fullUrl = getFullImageUrl(imageUrl);

    if (fullUrl == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.image, size: 32, color: Colors.grey[300]),
            const SizedBox(height: 4),
            Text(
              'No Image',
              style: TextStyle(fontSize: 10, color: Colors.grey[400]),
            ),
          ],
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        fullUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                  : null,
              strokeWidth: 2,
              color: Colors.grey[300],
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(LucideIcons.imageOff, size: 32, color: Colors.grey[300]),
              const SizedBox(height: 4),
              Text(
                'Error',
                style: TextStyle(fontSize: 10, color: Colors.grey[400]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
