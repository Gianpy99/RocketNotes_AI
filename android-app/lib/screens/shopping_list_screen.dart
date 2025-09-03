// ==========================================
// lib/screens/shopping_list_screen.dart
// ==========================================
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_colors.dart';
import '../data/models/shopping_list_model.dart';
import '../core/services/shopping_service.dart';
import '../core/services/family_service.dart';
import '../ui/widgets/shopping/quick_add_dialog.dart';
import '../ui/widgets/shopping/voice_input_dialog.dart';

// TODO: SHOPPING_FEATURES - Add advanced shopping UI
// - Add voice input for adding items
// - Add swipe gestures for quick actions
// - Add item categories with colors
// - Add shopping trip timer
// - Add store map integration

class ShoppingListScreen extends ConsumerStatefulWidget {
  final String? listId; // If null, create new list

  const ShoppingListScreen({super.key, this.listId});

  @override
  ConsumerState<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends ConsumerState<ShoppingListScreen> {
  ShoppingList? _shoppingList;
  final TextEditingController _newItemController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController(text: '1');
  final String _selectedCategory = 'pantry';
  bool _isLoading = true;

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
  void initState() {
    super.initState();
    _loadShoppingList();
  }

  @override
  void dispose() {
    _newItemController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _loadShoppingList() async {
    setState(() => _isLoading = true);

    try {
      if (widget.listId != null) {
        _shoppingList = await ShoppingService.instance.getShoppingList(widget.listId!);
      } else {
        // Create new shopping list
        final currentUser = await FamilyService.instance.getCurrentUser();
        if (currentUser != null) {
          _shoppingList = ShoppingList(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            name: 'New Shopping List',
            createdBy: currentUser.id,
          );
        }
      }
    } catch (e) {
      debugPrint('Error loading shopping list: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_shoppingList == null) {
      return const Scaffold(
        body: Center(child: Text('Shopping list not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_shoppingList!.name),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.mic),
            onPressed: _showVoiceInputDialog,
            tooltip: 'Voice Input',
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: _showListOptions,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: _buildProgressBar(),
        ),
      ),
      body: Column(
        children: [
          // Add new item section
          _buildAddItemSection(),

          // Items list
          Expanded(
            child: _buildItemsList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddItemDialog,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildProgressBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_shoppingList!.completedItems}/${_shoppingList!.totalItems} items',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
              Text(
                '${(_shoppingList!.completionPercentage * 100).round()}% complete',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: _shoppingList!.completionPercentage,
            backgroundColor: Colors.white.withValues(alpha: 0.3),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildAddItemSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _newItemController,
              decoration: const InputDecoration(
                hintText: 'Add item...',
                border: InputBorder.none,
              ),
              onSubmitted: (_) => _addQuickItem(),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle, color: AppColors.primary),
            onPressed: _addQuickItem,
          ),
        ],
      ),
    );
  }

  Widget _buildItemsList() {
    if (_shoppingList!.items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: 80,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'No items yet',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add your first item above',
              style: TextStyle(
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }

    final itemsByCategory = _shoppingList!.itemsByCategory;

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: itemsByCategory.length,
      itemBuilder: (context, index) {
        final category = itemsByCategory.keys.elementAt(index);
        final items = itemsByCategory[category]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCategoryHeader(category, items),
            ...items.map((item) => _buildItemTile(item)),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  Widget _buildCategoryHeader(String category, List<ShoppingListItem> items) {
    final completedCount = items.where((item) => item.isCompleted).length;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _categoryColors[category]?.withValues(alpha: 0.1) ?? Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            _categoryIcons[category] ?? Icons.category,
            size: 16,
            color: _categoryColors[category] ?? Colors.grey,
          ),
          const SizedBox(width: 8),
          Text(
            '${category.toUpperCase()} ($completedCount/${items.length})',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: _categoryColors[category] ?? Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemTile(ShoppingListItem item) {
    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => _removeItem(item.id),
      child: Card(
        margin: const EdgeInsets.only(bottom: 4),
        child: ListTile(
          leading: Checkbox(
            value: item.isCompleted,
            onChanged: (_) => _toggleItemCompletion(item.id),
            activeColor: _categoryColors[item.category] ?? AppColors.primary,
          ),
          title: Text(
            item.displayText,
            style: TextStyle(
              decoration: item.isCompleted ? TextDecoration.lineThrough : null,
              color: item.isCompleted ? Colors.grey : null,
            ),
          ),
          subtitle: item.notes != null && item.notes!.isNotEmpty
              ? Text(item.notes!)
              : null,
          trailing: Icon(
            _categoryIcons[item.category] ?? Icons.category,
            color: _categoryColors[item.category] ?? Colors.grey,
            size: 20,
          ),
          onTap: () => _toggleItemCompletion(item.id),
        ),
      ),
    );
  }

  Future<void> _addQuickItem() async {
    final itemName = _newItemController.text.trim();
    if (itemName.isEmpty) return;

    final currentUser = await FamilyService.instance.getCurrentUser();
    if (currentUser == null) return;

    final item = await ShoppingService.instance.createQuickItem(
      itemName,
      createdBy: currentUser.id,
      category: _selectedCategory,
    );

    await ShoppingService.instance.addItemToList(_shoppingList!.id, item);

    _newItemController.clear();
    await _loadShoppingList(); // Refresh the list
  }

  Future<void> _toggleItemCompletion(String itemId) async {
    final currentUser = await FamilyService.instance.getCurrentUser();
    await ShoppingService.instance.toggleItemCompletion(
      _shoppingList!.id,
      itemId,
      completedBy: currentUser?.id,
    );
    await _loadShoppingList(); // Refresh the list
  }

  Future<void> _removeItem(String itemId) async {
    await ShoppingService.instance.removeItemFromList(_shoppingList!.id, itemId);
    await _loadShoppingList(); // Refresh the list
  }

  void _showAddItemDialog() {
    showDialog(
      context: context,
      builder: (context) => QuickAddDialog(listId: _shoppingList!.id),
    ).then((_) => _loadShoppingList()); // Refresh list after dialog closes
  }

  void _showVoiceInputDialog() {
    showDialog(
      context: context,
      builder: (context) => VoiceInputDialog(listId: _shoppingList!.id),
    ).then((_) => _loadShoppingList()); // Refresh list after dialog closes
  }

  void _showListOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Rename List'),
            onTap: () {
              Navigator.of(context).pop();
              _showRenameDialog();
            },
          ),
          ListTile(
            leading: const Icon(Icons.share),
            title: const Text('Share with Family'),
            onTap: () {
              Navigator.of(context).pop();
              _showShareDialog();
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text('Delete List', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.of(context).pop();
              _showDeleteConfirmation();
            },
          ),
        ],
      ),
    );
  }

  void _showRenameDialog() {
    final controller = TextEditingController(text: _shoppingList!.name);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Shopping List'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'List name',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                final updatedList = _shoppingList!.copyWith(name: newName);
                await ShoppingService.instance.updateShoppingList(updatedList);
                await _loadShoppingList();
              }
              if (context.mounted) {
                Navigator.of(context).pop();
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showShareDialog() {
    // TODO: Implement family sharing
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Family sharing - Coming Soon!'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Shopping List'),
        content: const Text('Are you sure you want to delete this shopping list? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await ShoppingService.instance.removeShoppingList(_shoppingList!.id);
              if (context.mounted) {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Close screen
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
