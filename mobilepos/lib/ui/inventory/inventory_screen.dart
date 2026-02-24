import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../layout/pos_layout.dart';
import '../../core/providers/inventory_provider.dart';
import '../../core/models/product.dart';
import '../../core/services/dio_service.dart';
import '../widgets/skeleton.dart';
import '../widgets/app_toast.dart';

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  final _searchController = TextEditingController();
  final _reasonController = TextEditingController();

  // Editor State
  bool _isEditorOpen = false;
  Product? _selectedItem;
  bool _isSaving = false;

  // Edit Form Fields
  double _currentStock = 0;
  double _minimumStockAlert = 0;
  bool _isAvailable = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(inventoryProvider.notifier).fetchInventory();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  void _openEditor(Product item) {
    setState(() {
      _selectedItem = item;
      _currentStock = item.currentStock;
      _minimumStockAlert = item.minimumStockAlert;
      _isAvailable = item.isAvailable;
      _reasonController.clear();
      _isEditorOpen = true;
    });
  }

  void _closeEditor() {
    setState(() {
      _isEditorOpen = false;
      _selectedItem = null;
    });
  }

  void _adjustStock(double amount) {
    setState(() {
      _currentStock = (_currentStock + amount).clamp(0, double.infinity);
    });
  }

  Future<void> _saveChanges() async {
    if (_selectedItem == null) return;

    setState(() => _isSaving = true);

    final data = {
      'current_stock': _currentStock,
      'minimum_stock_alert': _minimumStockAlert,
      'is_available': _isAvailable,
      'reason': _reasonController.text.trim(),
    };

    final success = await ref
        .read(inventoryProvider.notifier)
        .updateInventory(_selectedItem!.id, data);

    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        _closeEditor();
        AppToast.show(
          context,
          'Inventory updated successfully',
          type: ToastType.success,
        );
      } else {
        AppToast.show(
          context,
          'Failed to update inventory',
          type: ToastType.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final inventoryState = ref.watch(inventoryProvider);
    final items = inventoryState.items;
    final isLoading = inventoryState.isLoading;

    final isLargeScreen = MediaQuery.of(context).size.width > 1024;

    return PosLayout(
      child: Stack(
        children: [
          Row(
            children: [
              // Main Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        border: Border(
                          bottom: BorderSide(color: Color(0xFFF3F4F6)),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Inventory Management',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _searchController,
                            onChanged: (val) => ref
                                .read(inventoryProvider.notifier)
                                .setSearchQuery(val),
                            decoration: InputDecoration(
                              hintText: 'Search inventory by name, SKU...',
                              prefixIcon: const Icon(
                                LucideIcons.search,
                                color: Colors.grey,
                              ),
                              filled: true,
                              fillColor: const Color(0xFFF9FAFB),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Filters
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFDFDFD),
                        border: Border(
                          bottom: BorderSide(color: Color(0xFFF9FAFB)),
                        ),
                      ),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildFilterButton(
                              label: 'All Items',
                              isActive: inventoryState.filter == 'all',
                              onTap: () => ref
                                  .read(inventoryProvider.notifier)
                                  .setFilter('all'),
                            ),
                            const SizedBox(width: 12),
                            _buildFilterButton(
                              label: 'Low Stock',
                              isActive: inventoryState.filter == 'low_stock',
                              showDot: true,
                              dotColor: Colors.red,
                              onTap: () => ref
                                  .read(inventoryProvider.notifier)
                                  .setFilter('low_stock'),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Item Grid
                    Expanded(
                      child: isLoading
                          ? const ProductGridSkeleton(itemCount: 12)
                          : items.isEmpty
                          ? _buildEmptyState()
                          : GridView.builder(
                              padding: const EdgeInsets.all(24),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 4,
                                    mainAxisSpacing: 16,
                                    crossAxisSpacing: 16,
                                    childAspectRatio: 0.8,
                                  ),
                              itemCount: items.length,
                              itemBuilder: (context, index) {
                                return _buildInventoryCard(items[index]);
                              },
                            ),
                    ),
                  ],
                ),
              ),

              // Sidebar Spacer for Large Screens
              if (_isEditorOpen && isLargeScreen) const SizedBox(width: 400),
            ],
          ),

          // Side Editor
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            right: _isEditorOpen ? 0 : -400,
            top: 0,
            bottom: 0,
            width: 400,
            child: _buildEditorSidebar(context),
          ),
        ],
      ),
    );
  }

  Widget _buildProductImage(String? imageUrl) {
    final fullUrl = getFullImageUrl(imageUrl);

    if (fullUrl == null) {
      return Container(
        color: Colors.grey[100],
        child: Center(
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
        ),
      );
    }

    return Image.network(
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
      errorBuilder: (context, error, stackTrace) => Container(
        color: Colors.grey[100],
        child: Center(
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

  Widget _buildFilterButton({
    required String label,
    required bool isActive,
    required VoidCallback onTap,
    bool showDot = false,
    Color dotColor = Colors.red,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF5a6c37) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? Colors.transparent : Colors.grey[200]!,
          ),
          boxShadow: [
            if (isActive)
              BoxShadow(
                color: const Color(0xFF5a6c37).withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showDot) ...[
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isActive ? Colors.white : dotColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isActive ? Colors.white : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInventoryCard(Product item) {
    final isSelected = _selectedItem?.id == item.id;
    final isLowStock = item.currentStock <= item.minimumStockAlert;
    final isOutOfStock = item.currentStock <= 0;

    return GestureDetector(
      onTap: () => _openEditor(item),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF5a6c37) : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image and Status Badge
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(14),
                    ),
                    child: _buildProductImage(item.imageUrl),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: _buildStatusBadge(isOutOfStock, isLowStock),
                  ),
                ],
              ),
            ),

            // Info
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'SKU: ${item.sku}',
                    style: TextStyle(color: Colors.grey[500], fontSize: 11),
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'STOCK',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                          Text(
                            item.currentStock.toStringAsFixed(0),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isLowStock
                                  ? Colors.red
                                  : const Color(0xFF5a6c37),
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            'PRICE',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                          Text(
                            NumberFormat.currency(
                              locale: 'id_ID',
                              symbol: 'Rp',
                              decimalDigits: 0,
                            ).format(item.price),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(bool isOutOfStock, bool isLowStock) {
    String text;
    Color color;
    Color textColor;

    if (isOutOfStock) {
      text = 'Out';
      color = Colors.red[50]!;
      textColor = Colors.red[700]!;
    } else if (isLowStock) {
      text = 'Low';
      color = Colors.orange[50]!;
      textColor = Colors.orange[700]!;
    } else {
      text = 'In Stock';
      color = Colors.green[50]!;
      textColor = Colors.green[700]!;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: textColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isLowStock && !isOutOfStock)
            Container(
              width: 6,
              height: 6,
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(
                color: Colors.orange[500],
                shape: BoxShape.circle,
              ),
            ),
          Text(
            text,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditorSidebar(BuildContext context) {
    if (_selectedItem == null) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(left: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Edit Stock',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: _closeEditor,
                  icon: const Icon(LucideIcons.x, color: Colors.grey),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Scrollable Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Item Header
                  Row(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          image: DecorationImage(
                            image: NetworkImage(
                              getFullImageUrl(_selectedItem!.imageUrl) ?? '',
                            ),
                            fit: BoxFit.cover,
                          ),
                          border: Border.all(color: Colors.grey[100]!),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF5a6c37,
                                ).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                _isAvailable ? 'Active' : 'Inactive',
                                style: const TextStyle(
                                  color: Color(0xFF5a6c37),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _selectedItem!.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'SKU: ${_selectedItem!.sku}',
                              style: TextStyle(color: Colors.grey[500]),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Stock Level
                  const Text(
                    'CURRENT STOCK LEVEL',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFF1F5F9)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildStockButton(
                          icon: LucideIcons.minus,
                          onTap: () => _adjustStock(-1),
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                _currentStock.toStringAsFixed(0),
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Text(
                                'units',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _buildStockButton(
                          icon: LucideIcons.plus,
                          isPrimary: true,
                          onTap: () => _adjustStock(1),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Low Stock Alert
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Minimum Stock Alert',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      Text(
                        '${_minimumStockAlert.toInt()} units',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: const Color(0xFF5a6c37),
                      thumbColor: const Color(0xFF5a6c37),
                      overlayColor: const Color(
                        0xFF5a6c37,
                      ).withValues(alpha: 0.2),
                    ),
                    child: Slider(
                      value: _minimumStockAlert,
                      min: 0,
                      max: 100,
                      onChanged: (val) =>
                          setState(() => _minimumStockAlert = val),
                    ),
                  ),
                  const Text(
                    'Alert triggers when stock falls below this value.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 24),

                  // Availability
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Available on Menu',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                          Text(
                            'Show or hide from POS',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                      Switch(
                        value: _isAvailable,
                        onChanged: (val) => setState(() => _isAvailable = val),
                        activeTrackColor: const Color(0xFF5a6c37),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Reason
                  const Text(
                    'Update Reason (Optional)',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _reasonController,
                    decoration: InputDecoration(
                      hintText: 'e.g. Restock, Spoilage, Correction',
                      filled: true,
                      fillColor: const Color(0xFFF9FAFB),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[200]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[200]!),
                      ),
                    ),
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ),

          // Footer
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFFF3F4F6))),
            ),
            child: ElevatedButton(
              onPressed: _isSaving ? null : _saveChanges,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5a6c37),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_isSaving)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  else
                    const Icon(LucideIcons.save, size: 20),
                  const SizedBox(width: 8),
                  Text(_isSaving ? 'Saving...' : 'Save Changes'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStockButton({
    required IconData icon,
    required VoidCallback onTap,
    bool isPrimary = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: isPrimary ? const Color(0xFF5a6c37) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isPrimary ? Colors.transparent : Colors.grey[200]!,
          ),
          boxShadow: [
            if (isPrimary)
              BoxShadow(
                color: const Color(0xFF5a6c37).withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            else
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Icon(icon, color: isPrimary ? Colors.white : Colors.grey[700]),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.package, size: 48, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text(
            'No inventory items found',
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
