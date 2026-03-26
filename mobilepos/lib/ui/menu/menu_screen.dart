import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // Keep kIsWeb support
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'dart:io'
    show File; // Specifically only use File to prevent Platform bleeding
import '../layout/pos_layout.dart';
import '../../core/providers/menu_provider.dart';
import '../../core/models/product.dart';
import '../../core/services/dio_service.dart';
import '../widgets/skeleton.dart';
import '../widgets/app_toast.dart';

class MenuScreen extends ConsumerStatefulWidget {
  const MenuScreen({super.key});

  @override
  ConsumerState<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends ConsumerState<MenuScreen> {
  final _searchController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // Editor State
  bool _isEditorOpen = false;
  bool _isCreating = false;
  Product? _selectedProduct;
  XFile? _selectedImage;
  String? _imagePreviewUrl;

  // Form Fields
  String _name = '';
  String _sku = '';
  double _price = 0;
  String? _categoryId;
  bool _isAvailable = true;
  double _currentStock = 0; // Only for creation/display

  @override
  void initState() {
    super.initState();
    // Fetch data on load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(menuProvider.notifier).fetchCategories();
      ref.read(menuProvider.notifier).fetchProducts();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openEditor({Product? product}) {
    setState(() {
      _isEditorOpen = true;
      _isCreating = product == null;
      _selectedProduct = product;

      // Reset or Populate Form
      if (product != null) {
        _name = product.name;
        _sku = product.sku ?? '';
        _price = product.price;
        _categoryId = product.categoryId;
        _isAvailable = product.isAvailable;
        _currentStock = product.currentStock;
        _imagePreviewUrl = product.imageUrl;
      } else {
        _name = '';
        _sku =
            'PRD-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}'; // Simple random SKU
        _price = 0;
        _categoryId = null;
        _isAvailable = true;
        _currentStock = 0;
        _imagePreviewUrl = null;
      }
      _selectedImage = null;
    });
  }

  void _closeEditor() {
    setState(() {
      _isEditorOpen = false;
      _selectedProduct = null;
    });
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = pickedFile;
      });
    }
  }

  Future<void> _deleteProduct() async {
    if (_selectedProduct == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: const Text('Are you sure you want to delete this product?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await ref
          .read(menuProvider.notifier)
          .deleteProduct(_selectedProduct!.id);
      if (success) _closeEditor();
    }
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    final data = {
      'name': _name,
      'sku': _sku,
      'price': _price,
      'category_id': _categoryId,
      'is_available': _isAvailable,
      'current_stock': _currentStock,
    };

    bool success;
    if (_isCreating) {
      success = await ref
          .read(menuProvider.notifier)
          .createProduct(data, _selectedImage);
    } else {
      success = await ref
          .read(menuProvider.notifier)
          .updateProduct(_selectedProduct!.id, data, _selectedImage);
    }

    if (success) {
      _closeEditor();
      if (mounted) {
        AppToast.show(
          context,
          _isCreating
              ? 'Product created successfully'
              : 'Product updated successfully',
          type: ToastType.success,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final menuState = ref.watch(menuProvider);
    final products = menuState.products;
    final categories = menuState.categories;
    final isLoading = menuState.isLoading;

    return PosLayout(
      child: Stack(
        children: [
          Row(
            children: [
              // Main Content
              Expanded(
                child: Column(
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
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'All Menu',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              ElevatedButton.icon(
                                onPressed: () => _openEditor(),
                                icon: const Icon(LucideIcons.plus, size: 16),
                                label: const Text('Add Menu'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF5a6c37),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _searchController,
                            onChanged: (val) => ref
                                .read(menuProvider.notifier)
                                .setSearchQuery(val),
                            decoration: InputDecoration(
                              hintText: 'Search product name, SKU...',
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

                    // Categories
                    Container(
                      height: 60,
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 24,
                      ),
                      child: isLoading && categories.isEmpty
                          ? const CategoryListSkeleton()
                          : ListView(
                              scrollDirection: Axis.horizontal,
                              children: [
                                _buildCategoryButton(
                                  id: 'all',
                                  label: 'All Items',
                                  isActive: menuState.activeCategoryId == 'all',
                                  onTap: () => ref
                                      .read(menuProvider.notifier)
                                      .setActiveCategory('all'),
                                ),
                                ...categories.map(
                                  (cat) => _buildCategoryButton(
                                    id: cat.id,
                                    label: cat.name,
                                    isActive:
                                        menuState.activeCategoryId == cat.id,
                                    onTap: () => ref
                                        .read(menuProvider.notifier)
                                        .setActiveCategory(cat.id),
                                  ),
                                ),
                              ],
                            ),
                    ),

                    // Grid
                    Expanded(
                      child: isLoading && products.isEmpty
                          ? const ProductGridSkeleton(crossAxisCount: 4)
                          : products.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    LucideIcons.layoutGrid,
                                    size: 48,
                                    color: Colors.grey[300],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No products found',
                                    style: TextStyle(color: Colors.grey[400]),
                                  ),
                                ],
                              ),
                            )
                          : GridView.builder(
                              padding: const EdgeInsets.all(24),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount:
                                        4, // Responsive logic could be added here
                                    mainAxisSpacing: 16,
                                    crossAxisSpacing: 16,
                                    childAspectRatio:
                                        0.75, // Adjust for card layout
                                  ),
                              itemCount: products.length,
                              itemBuilder: (context, index) {
                                final product = products[index];
                                final isSelected =
                                    _selectedProduct?.id == product.id;

                                return GestureDetector(
                                  onTap: () => _openEditor(product: product),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: isSelected
                                            ? const Color(0xFF5a6c37)
                                            : const Color(0xFFE5E7EB),
                                        width: isSelected ? 2 : 1,
                                      ),
                                      boxShadow: [
                                        if (isSelected)
                                          BoxShadow(
                                            color: const Color(
                                              0xFF5a6c37,
                                            ).withValues(alpha: 0.1),
                                            blurRadius: 8,
                                          ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        // Image
                                        Expanded(
                                          child: Container(
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  const BorderRadius.vertical(
                                                    top: Radius.circular(15),
                                                  ),
                                              color: Colors.grey[100],
                                            ),
                                            child: ClipRRect(
                                              borderRadius:
                                                  const BorderRadius.vertical(
                                                    top: Radius.circular(15),
                                                  ),
                                              child: Stack(
                                                fit: StackFit.expand,
                                                children: [
                                                  _buildProductImage(
                                                    product.imageUrl,
                                                  ),
                                                  if (!product.isAvailable)
                                                    Container(
                                                      color: Colors.white
                                                          .withValues(
                                                            alpha: 0.7,
                                                          ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                        // Info
                                        Padding(
                                          padding: const EdgeInsets.all(12),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                product.name,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                NumberFormat.currency(
                                                  locale: 'id_ID',
                                                  symbol: 'Rp ',
                                                  decimalDigits: 0,
                                                ).format(product.price),
                                                style: TextStyle(
                                                  color: Colors.grey[600],
                                                  fontSize: 12,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Text(
                                                    product.isAvailable
                                                        ? 'AVAILABLE'
                                                        : 'HIDDEN',
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: product.isAvailable
                                                          ? const Color(
                                                              0xFF9CA3AF,
                                                            )
                                                          : Colors.red,
                                                    ),
                                                  ),
                                                  Container(
                                                    width: 32,
                                                    height: 20,
                                                    decoration: BoxDecoration(
                                                      color: product.isAvailable
                                                          ? const Color(
                                                              0xFF5a6c37,
                                                            )
                                                          : const Color(
                                                              0xFFD1D5DB,
                                                            ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            20,
                                                          ),
                                                    ),
                                                    child: Align(
                                                      alignment:
                                                          product.isAvailable
                                                          ? Alignment
                                                                .centerRight
                                                          : Alignment
                                                                .centerLeft,
                                                      child: Container(
                                                        margin:
                                                            const EdgeInsets.all(
                                                              2,
                                                            ),
                                                        width: 16,
                                                        height: 16,
                                                        decoration:
                                                            const BoxDecoration(
                                                              color:
                                                                  Colors.white,
                                                              shape: BoxShape
                                                                  .circle,
                                                            ),
                                                      ),
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
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),

              // Sidebar Placeholder to preventing main content overlap when sidebar opens?
              // No, we use Stack's Positioned, so it floats over.
              // However, Vue's implementation pushes content:
              // :class="{ 'lg:mr-[400px]': selectedProduct || isCreating }"
              // We can simulate this by animating a SizedBox width or checking screen size.
              // For simplicity, let's overlay on mobile, push on desktop if we had time.
              // Let's just overlay for now or use EndDrawer pattern custom.
              if (_isEditorOpen && MediaQuery.of(context).size.width > 800)
                const SizedBox(width: 400),
            ],
          ),

          // Editor Sidebar
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            right: _isEditorOpen ? 0 : -400,
            top: 0,
            bottom: 0,
            width: 400,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(left: BorderSide(color: Colors.grey[200]!)),
              ),
              child: Column(
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
                        Text(
                          _isCreating ? 'New Product' : 'Edit Product',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          onPressed: _closeEditor,
                          icon: const Icon(LucideIcons.x, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),

                  // Form
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          key: ValueKey(
                            _selectedProduct?.id ?? 'new-$_isCreating',
                          ),
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Image Picker
                            GestureDetector(
                              onTap: _pickImage,
                              child: Container(
                                height: 200,
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.grey[300]!,
                                    style: BorderStyle.none,
                                  ), // Dashed border hard in flutter native without package, keeping simple
                                  image: _selectedImage != null
                                      ? DecorationImage(
                                          image: kIsWeb
                                              ? NetworkImage(
                                                      _selectedImage!.path,
                                                    )
                                                    as ImageProvider
                                              : FileImage(
                                                      File(
                                                        _selectedImage!.path,
                                                      ),
                                                    )
                                                    as ImageProvider,
                                          fit: BoxFit.cover,
                                        )
                                      : (_imagePreviewUrl != null
                                            ? DecorationImage(
                                                image: NetworkImage(
                                                  getFullImageUrl(
                                                        _imagePreviewUrl,
                                                      ) ??
                                                      '',
                                                ),
                                                fit: BoxFit.cover,
                                              )
                                            : null),
                                ),
                                child:
                                    (_selectedImage == null &&
                                        _imagePreviewUrl == null)
                                    ? const Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            LucideIcons.camera,
                                            size: 48,
                                            color: Colors.grey,
                                          ),
                                          SizedBox(height: 8),
                                          Text(
                                            'Tap to upload',
                                            style: TextStyle(
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ],
                                      )
                                    : null,
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Product Info
                            const Text(
                              'PRODUCT INFORMATION',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 16),

                            TextFormField(
                              initialValue: _name,
                              decoration: _inputDecoration(
                                'Product Name',
                                'e.g. Kopi Ruang',
                              ),
                              onSaved: (val) => _name = val ?? '',
                              validator: (val) => val == null || val.isEmpty
                                  ? 'Required'
                                  : null,
                            ),
                            const SizedBox(height: 16),

                            TextFormField(
                              initialValue: _sku,
                              decoration: _inputDecoration(
                                'SKU',
                                'e.g. PRD-001',
                              ),
                              onSaved: (val) => _sku = val ?? '',
                              validator: (val) => val == null || val.isEmpty
                                  ? 'Required'
                                  : null,
                            ),
                            const SizedBox(height: 16),

                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    initialValue: _price == 0
                                        ? ''
                                        : _price.toString(),
                                    decoration: _inputDecoration(
                                      'Price (Rp)',
                                      '0',
                                    ),
                                    keyboardType: TextInputType.number,
                                    onSaved: (val) => _price =
                                        double.tryParse(val ?? '0') ?? 0,
                                    validator: (val) =>
                                        val == null || val.isEmpty
                                        ? 'Required'
                                        : null,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    initialValue: _categoryId,
                                    decoration: _inputDecoration(
                                      'Category',
                                      '',
                                    ),
                                    items: categories
                                        .map<DropdownMenuItem<String>>(
                                          (c) => DropdownMenuItem<String>(
                                            value: c.id,
                                            child: Text(
                                              c.name,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        )
                                        .toList(),
                                    isExpanded: true,
                                    onChanged: (val) =>
                                        setState(() => _categoryId = val),
                                    validator: (val) =>
                                        val == null ? 'Required' : null,
                                  ),
                                ),
                              ],
                            ),

                            const Divider(),
                            const Text(
                              'INVENTORY & STATUS',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),

                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey[200]!),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Available Online',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Switch(
                                    value: _isAvailable,
                                    onChanged: (val) =>
                                        setState(() => _isAvailable = val),
                                    activeThumbColor: const Color(0xFF5a6c37),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),

                            TextFormField(
                              initialValue: _currentStock == 0
                                  ? ''
                                  : _currentStock.toString(),
                              decoration: _inputDecoration('Current Stock', '0')
                                  .copyWith(
                                    helperText: !_isCreating
                                        ? 'Use Inventory Page to Update Stock'
                                        : null,
                                  ),
                              keyboardType: TextInputType.number,
                              enabled: _isCreating,
                              onSaved: (val) => _currentStock =
                                  double.tryParse(val ?? '0') ?? 0,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Footer
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: const BoxDecoration(
                      border: Border(top: BorderSide(color: Color(0xFFF3F4F6))),
                    ),
                    child: Row(
                      children: [
                        if (!_isCreating)
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _deleteProduct,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: const BorderSide(color: Colors.red),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text('Delete'),
                            ),
                          ),
                        if (!_isCreating) const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: isLoading ? null : _saveProduct,
                            icon: isLoading
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const SizedBox.shrink(),
                            label: Text(
                              isLoading ? 'Saving...' : 'Save Changes',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF5a6c37),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
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
      ),
    );
  }

  Widget _buildCategoryButton({
    required String id,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          backgroundColor: isActive ? const Color(0xFF5a6c37) : Colors.white,
          foregroundColor: isActive ? Colors.white : Colors.grey[600],
          side: BorderSide(
            color: isActive ? const Color(0xFF5a6c37) : const Color(0xFFE5E7EB),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: Text(label),
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
    );
  }

  InputDecoration _inputDecoration(String label, String hint) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      floatingLabelBehavior: FloatingLabelBehavior.always,
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
    );
  }
}
