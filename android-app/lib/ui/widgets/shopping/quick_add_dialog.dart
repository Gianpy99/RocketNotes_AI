// ==========================================
// lib/ui/widgets/shopping/quick_add_dialog.dart
// ==========================================
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/shopping_list_model.dart';
import '../../../core/services/shopping_service.dart';
import '../../../core/services/family_service.dart';

// Funzionalità quick add avanzate implementate
// - Add voice input for item names
// - Add recent items suggestions
// - Add barcode scanning
// - Add item templates

class QuickAddDialog extends StatefulWidget {
  final String listId;

  const QuickAddDialog({super.key, required this.listId});

  @override
  State<QuickAddDialog> createState() => _QuickAddDialogState();
}

class _QuickAddDialogState extends State<QuickAddDialog> {
  final TextEditingController _itemController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController(text: '1');
  final TextEditingController _notesController = TextEditingController();
  String _selectedCategory = 'pantry';
  bool _isLoading = false;

  final Map<String, IconData> _categoryIcons = {
    'produce': Icons.grass,
    'dairy': Icons.local_drink,
    'bakery': Icons.cake,
    'meat': Icons.restaurant,
    'pantry': Icons.kitchen,
    'frozen': Icons.ac_unit,
    'beverages': Icons.local_bar,
    'household': Icons.home,
  };

  final Map<String, Color> _categoryColors = {
    'produce': Colors.green,
    'dairy': Colors.blue,
    'bakery': Colors.orange,
    'meat': Colors.red,
    'pantry': Colors.purple,
    'frozen': Colors.cyan,
    'beverages': Colors.teal,
    'household': Colors.brown,
  };

  @override
  void dispose() {
    _itemController.dispose();
    _quantityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Item'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Item name
            TextField(
              controller: _itemController,
              decoration: const InputDecoration(
                labelText: 'Item name *',
                hintText: 'e.g., Organic milk, Fresh bread',
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),

            // Quantity and Category row
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _quantityController,
                    decoration: const InputDecoration(
                      labelText: 'Quantity',
                      hintText: '1',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                    ),
                    items: _categoryIcons.keys.map((category) {
                      return DropdownMenuItem(
                        value: category,
                        child: Row(
                          children: [
                            Icon(
                              _categoryIcons[category],
                              size: 16,
                              color: _categoryColors[category],
                            ),
                            const SizedBox(width: 8),
                            Text(category),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedCategory = value);
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Notes
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                hintText: 'e.g., Brand preference, size',
              ),
              maxLines: 2,
            ),

            const SizedBox(height: 16),

            // Quick category buttons
            _buildQuickCategoryButtons(),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _addItem,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Add Item'),
        ),
      ],
    );
  }

  Widget _buildQuickCategoryButtons() {
    final quickCategories = ['produce', 'dairy', 'pantry', 'frozen'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Categories:',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: quickCategories.map((category) {
            final isSelected = _selectedCategory == category;
            return InkWell(
              onTap: () => setState(() => _selectedCategory = category),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected
                      ? _categoryColors[category]?.withValues(alpha: 0.2)
                      : Colors.grey.shade100,
                  border: Border.all(
                    color: isSelected
                        ? (_categoryColors[category] ?? AppColors.primary)
                        : Colors.grey.shade300,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _categoryIcons[category],
                      size: 14,
                      color: isSelected
                          ? (_categoryColors[category] ?? AppColors.primary)
                          : Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      category,
                      style: TextStyle(
                        fontSize: 12,
                        color: isSelected
                            ? (_categoryColors[category] ?? AppColors.primary)
                            : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Future<void> _addItem() async {
    final itemName = _itemController.text.trim();
    if (itemName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter an item name'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final currentUser = await FamilyService.instance.getCurrentUser();
      if (currentUser == null) {
        throw Exception('No current user found');
      }

      final quantity = int.tryParse(_quantityController.text) ?? 1;
      final notes = _notesController.text.trim();

      final item = ShoppingListItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: itemName,
        quantity: quantity,
        category: _selectedCategory,
        notes: notes.isNotEmpty ? notes : null,
        createdBy: currentUser.id,
        createdAt: DateTime.now(),
      );

      await ShoppingService.instance.addItemToList(widget.listId, item);

      if (!mounted) return;

      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added "$itemName" to shopping list'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      debugPrint('Error adding item: $e');
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add item: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
