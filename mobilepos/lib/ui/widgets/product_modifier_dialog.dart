import 'package:flutter/material.dart';
import '../../core/models/product.dart';
import '../../core/models/cart_item.dart';
import 'package:intl/intl.dart';

class ProductModifierDialog extends StatefulWidget {
  final Product product;
  final List<CartModifier>? initialModifiers;
  final String? initialNote;

  const ProductModifierDialog({
    super.key,
    required this.product,
    this.initialModifiers,
    this.initialNote,
  });

  @override
  State<ProductModifierDialog> createState() => _ProductModifierDialogState();
}

class _ProductModifierDialogState extends State<ProductModifierDialog> {
  // Map<ModifierId, List<ModifierOption>>
  final Map<String, List<ModifierOption>> _selections = {};
  late TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController(text: widget.initialNote);
    _initializeDefaults();
  }

  void _initializeDefaults() {
    if (widget.initialModifiers != null &&
        widget.initialModifiers!.isNotEmpty) {
      // Map initial modifiers to selections
      for (var mod in widget.initialModifiers!) {
        try {
          final modifier = widget.product.modifiers.firstWhere(
            (m) => m.id == mod.modifierId,
          );
          final option = modifier.options.firstWhere(
            (o) => o.id == mod.optionId,
          );

          if (_selections[mod.modifierId] == null) {
            _selections[mod.modifierId] = [];
          }
          _selections[mod.modifierId]!.add(option);
        } catch (_) {
          // Ignore if modifier/option no longer exists
        }
      }
      // Ensure empty lists for unselected modifiers
      for (var modifier in widget.product.modifiers) {
        if (!_selections.containsKey(modifier.id)) {
          _selections[modifier.id] = [];
        }
      }
    } else {
      // Default Logic
      for (var modifier in widget.product.modifiers) {
        if (modifier.type == 'single' &&
            modifier.isRequired &&
            modifier.options.isNotEmpty) {
          // Pre-select first option if required and single
          _selections[modifier.id] = [modifier.options.first];
        } else {
          _selections[modifier.id] = [];
        }
      }
    }
  }

  double get _totalPrice {
    double total = widget.product.price;
    _selections.forEach((key, options) {
      for (var option in options) {
        total += option.price;
      }
    });
    return total;
  }

  bool get _isValid {
    for (var modifier in widget.product.modifiers) {
      if (modifier.isRequired) {
        final selected = _selections[modifier.id];
        if (selected == null || selected.isEmpty) {
          return false;
        }
      }
    }
    return true;
  }

  void _toggleOption(Modifier modifier, ModifierOption option) {
    setState(() {
      final currentList = _selections[modifier.id] ?? [];

      if (modifier.type == 'single' ||
          modifier.type == 'radio' ||
          modifier.type == 'select') {
        // Single selection: replace list with just this option
        _selections[modifier.id] = [option];
      } else {
        // Multiple selection: toggle
        if (currentList.any((o) => o.id == option.id)) {
          currentList.removeWhere((o) => o.id == option.id);
        } else {
          currentList.add(option);
        }
        _selections[modifier.id] = currentList; // Re-assign for safety
      }
    });
  }

  bool _isSelected(String modifierId, String optionId) {
    final list = _selections[modifierId];
    return list?.any((o) => o.id == optionId) ?? false;
  }

  void _confirm() {
    if (!_isValid) return;

    // Convert selections to CartModifiers
    List<CartModifier> cartModifiers = [];
    _selections.forEach((modId, options) {
      final modifier = widget.product.modifiers.firstWhere(
        (m) => m.id == modId,
      );
      for (var option in options) {
        cartModifiers.add(
          CartModifier(
            modifierId: modId,
            optionId: option.id,
            name: modifier.name,
            optionName: option.name,
            price: option.price,
          ),
        );
      }
    });

    Navigator.of(
      context,
    ).pop({'modifiers': cartModifiers, 'note': _noteController.text.trim()});
  }

  List<ModifierOption> _getFilteredOptions(Modifier modifier) {
    if (modifier.allowedOptions == null || modifier.allowedOptions!.isEmpty) {
      return modifier.options;
    }

    return modifier.options.where((opt) {
      return modifier.allowedOptions!.contains(opt.id);
    }).toList();
  }

  List<Modifier> get _visibleModifiers {
    final visible = widget.product.modifiers.where((modifier) {
      if (modifier.conditionModifierId == null) {
        return true;
      }

      final conditionModId = modifier.conditionModifierId!;
      final conditionOptId = modifier.conditionOptionId;
      final selection = _selections[conditionModId];

      if (selection == null || selection.isEmpty) {
        return false;
      }

      if (conditionOptId != null) {
        return selection.any((opt) => opt.id == conditionOptId);
      }

      return true;
    }).toList();

    // Custom Sort: Available > Size > Others (preserve backend sort_order)
    visible.sort((a, b) {
      int getPriority(String name) {
        if (name == 'Available') return 0;
        if (name == 'Size') return 1;
        return 2;
      }

      final pA = getPriority(a.name);
      final pB = getPriority(b.name);

      if (pA != pB) return pA.compareTo(pB);

      return widget.product.modifiers
          .indexOf(a)
          .compareTo(widget.product.modifiers.indexOf(b));
    });

    return visible;
  }

  @override
  Widget build(BuildContext context) {
    final formatCurrency = NumberFormat.simpleCurrency(locale: 'id_ID');

    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 600,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.product.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        formatCurrency.format(widget.product.price),
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Content
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  ..._visibleModifiers.map((modifier) {
                    final filteredOptions = _getFilteredOptions(modifier);
                    if (filteredOptions.isEmpty) return const SizedBox.shrink();

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                modifier.name.toUpperCase(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              if (modifier.isRequired)
                                const Text(
                                  " (Required)",
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontSize: 12,
                                  ),
                                ),
                              if (modifier.type != 'single' &&
                                  modifier.type != 'radio')
                                Text(
                                  " (Optional, multiple)",
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 12,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  childAspectRatio: 4.5,
                                  crossAxisSpacing: 8,
                                  mainAxisSpacing: 8,
                                ),
                            itemCount: filteredOptions.length,
                            itemBuilder: (context, index) {
                              final option = filteredOptions[index];
                              final isSelected = _isSelected(
                                modifier.id,
                                option.id,
                              );

                              return InkWell(
                                onTap: () => _toggleOption(modifier, option),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: isSelected
                                          ? const Color(0xFF5a6c37)
                                          : Colors.grey[300]!,
                                      width: isSelected ? 2 : 1,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    color: isSelected
                                        ? const Color(
                                            0xFF5a6c37,
                                          ).withValues(alpha: 0.05)
                                        : Colors.white,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  child: Row(
                                    children: [
                                      // Checkbox/Radio Indicator
                                      if (modifier.type == 'single' ||
                                          modifier.type == 'radio')
                                        Icon(
                                          isSelected
                                              ? Icons.radio_button_checked
                                              : Icons.radio_button_off,
                                          color: isSelected
                                              ? const Color(0xFF5a6c37)
                                              : Colors.grey[400],
                                          size: 20,
                                        )
                                      else
                                        Icon(
                                          isSelected
                                              ? Icons.check_box
                                              : Icons.check_box_outline_blank,
                                          color: isSelected
                                              ? const Color(0xFF5a6c37)
                                              : Colors.grey[400],
                                          size: 20,
                                        ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          option.name,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w500,
                                            color: isSelected
                                                ? const Color(0xFF5a6c37)
                                                : Colors.black87,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (option.price > 0)
                                        Text(
                                          "+${formatCurrency.format(option.price)}",
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    );
                  }),

                  // Note
                  const Text(
                    "NOTE",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _noteController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: "Add special instructions...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
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
                color: Colors.grey[50],
                border: const Border(
                  top: BorderSide(color: Colors.grey, width: 0.2),
                ),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(16),
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isValid ? _confirm : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5a6c37),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey[300],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.initialModifiers != null
                            ? "Update Order"
                            : "Add to Order",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        formatCurrency.format(_totalPrice),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
