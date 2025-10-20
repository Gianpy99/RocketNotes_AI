import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/shopping_models.dart';
import '../providers/shopping_providers.dart';

class ShoppingListDetailScreen extends ConsumerStatefulWidget {
  final String listId;

  const ShoppingListDetailScreen({
    super.key,
    required this.listId,
  });

  @override
  ConsumerState<ShoppingListDetailScreen> createState() => _ShoppingListDetailScreenState();
}

class _ShoppingListDetailScreenState extends ConsumerState<ShoppingListDetailScreen> {
  final TextEditingController _itemController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController(text: '1');
  final TextEditingController _unitController = TextEditingController();

  @override
  void dispose() {
    _itemController.dispose();
    _quantityController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final list = ref.watch(shoppingListsProvider.notifier).getListById(widget.listId);

    if (list == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Lista non trovata')),
        body: const Center(child: Text('Lista della spesa non trovata')),
      );
    }

    final itemsByCategory = _groupByCategory(list.items);
    final pendingItems = list.items.where((i) => i.status == ShoppingItemStatus.pending).toList();
    final purchasedItems = list.items.where((i) => i.status == ShoppingItemStatus.purchased).toList();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(list.name),
            Text(
              '${pendingItems.length} da comprare, ${purchasedItems.length} acquistati',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        actions: [
          if (list.items.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              tooltip: 'Rimuovi acquistati',
              onPressed: () => _removeCompletedItems(list),
            ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'share':
                  _shareList(list);
                  break;
                case 'duplicate':
                  _duplicateList(list);
                  break;
                case 'delete':
                  _deleteList(list);
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'share',
                child: Row(
                  children: [
                    Icon(Icons.share),
                    SizedBox(width: 8),
                    Text('Condividi'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'duplicate',
                child: Row(
                  children: [
                    Icon(Icons.copy),
                    SizedBox(width: 8),
                    Text('Duplica'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Elimina', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Quick add bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green[50],
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _itemController,
                    decoration: InputDecoration(
                      hintText: 'Aggiungi prodotto...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      prefixIcon: const Icon(Icons.add_shopping_cart),
                      suffixIcon: _itemController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                setState(() {
                                  _itemController.clear();
                                });
                              },
                            )
                          : null,
                    ),
                    onChanged: (value) => setState(() {}),
                    onSubmitted: (value) => _quickAddItem(list),
                  ),
                ),
                const SizedBox(width: 8),
                FloatingActionButton.small(
                  onPressed: () => _showDetailedAddDialog(list),
                  backgroundColor: Colors.green[700],
                  child: const Icon(Icons.add),
                ),
              ],
            ),
          ),

          // Progress indicator
          if (list.items.isNotEmpty)
            LinearProgressIndicator(
              value: list.completionPercentage,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(Colors.green[700]!),
            ),

          // Items list
          Expanded(
            child: list.items.isEmpty
                ? _buildEmptyState()
                : ListView(
                    children: [
                      // Pending items by category
                      if (pendingItems.isNotEmpty) ...[
                        const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text(
                            'Da Acquistare',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        ...itemsByCategory.entries.where((entry) {
                          return entry.value.any((item) => item.status == ShoppingItemStatus.pending);
                        }).map((entry) {
                          final categoryItems = entry.value
                              .where((item) => item.status == ShoppingItemStatus.pending)
                              .toList();
                          return _buildCategorySection(entry.key, categoryItems, list);
                        }),
                      ],

                      // Purchased items
                      if (purchasedItems.isNotEmpty) ...[
                        const Divider(height: 32),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle, color: Colors.green),
                              const SizedBox(width: 8),
                              Text(
                                'Acquistati (${purchasedItems.length})',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ...purchasedItems.map((item) => _buildItemTile(item, list, completed: true)),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Lista vuota',
            style: TextStyle(fontSize: 20, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Aggiungi il primo prodotto',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySection(ShoppingCategory category, List<ShoppingItem> items, ShoppingList list) {
    final categoryName = _getCategoryName(category);
    final categoryIcon = _getCategoryIcon(category);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(categoryIcon, size: 20, color: Colors.green[700]),
              const SizedBox(width: 8),
              Text(
                categoryName,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.green[700],
                ),
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${items.length}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green[700],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        ...items.map((item) => _buildItemTile(item, list)),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildItemTile(ShoppingItem item, ShoppingList list, {bool completed = false}) {
    return Dismissible(
      key: Key(item.id),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      direction: DismissDirection.endToStart,
      onDismissed: (_) {
        ref.read(shoppingListsProvider.notifier).deleteItemFromList(list.id, item.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${item.name} rimosso'),
            action: SnackBarAction(
              label: 'Annulla',
              onPressed: () {
                // Re-add item
                ref.read(shoppingListsProvider.notifier).addItemToList(list.id, item);
              },
            ),
          ),
        );
      },
      child: CheckboxListTile(
        value: completed,
        onChanged: (value) {
          ref.read(shoppingListsProvider.notifier).toggleItemStatus(list.id, item.id);
        },
        title: Text(
          item.name,
          style: TextStyle(
            decoration: completed ? TextDecoration.lineThrough : null,
            color: completed ? Colors.grey : null,
          ),
        ),
        subtitle: Row(
          children: [
            if (item.quantity > 1)
              Text('${item.quantity}${item.unit != null ? " ${item.unit}" : "x"}'),
            if (item.notes != null && item.notes!.isNotEmpty) ...[
              if (item.quantity > 1) const Text(' • '),
              Expanded(
                child: Text(
                  item.notes!,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    decoration: completed ? TextDecoration.lineThrough : null,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
        secondary: completed
            ? const Icon(Icons.check_circle, color: Colors.green)
            : null,
        controlAffinity: ListTileControlAffinity.leading,
      ),
    );
  }

  void _quickAddItem(ShoppingList list) {
    final itemName = _itemController.text.trim();
    if (itemName.isEmpty) return;

    ref.read(shoppingListsProvider.notifier).quickAddItem(
          list.id,
          itemName,
        );

    setState(() {
      _itemController.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ $itemName aggiunto'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _showDetailedAddDialog(ShoppingList list) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Aggiungi Prodotto'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _itemController,
                decoration: const InputDecoration(
                  labelText: 'Nome prodotto *',
                  border: OutlineInputBorder(),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _quantityController,
                      decoration: const InputDecoration(
                        labelText: 'Quantità',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: _unitController,
                      decoration: const InputDecoration(
                        labelText: 'Unità (es: kg)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annulla'),
          ),
          ElevatedButton(
            onPressed: () {
              final itemName = _itemController.text.trim();
              if (itemName.isEmpty) return;

              final quantity = int.tryParse(_quantityController.text) ?? 1;
              final unit = _unitController.text.trim().isEmpty ? null : _unitController.text.trim();

              ref.read(shoppingListsProvider.notifier).quickAddItem(
                    list.id,
                    itemName,
                    quantity: quantity,
                    unit: unit,
                  );

              _itemController.clear();
              _quantityController.text = '1';
              _unitController.clear();

              Navigator.pop(context);
            },
            child: const Text('Aggiungi'),
          ),
        ],
      ),
    );
  }

  void _removeCompletedItems(ShoppingList list) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rimuovi Acquistati'),
        content: Text(
          'Vuoi rimuovere ${list.items.where((i) => i.status == ShoppingItemStatus.purchased).length} prodotti acquistati?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annulla'),
          ),
          ElevatedButton(
            onPressed: () {
              final completedIds = list.items
                  .where((i) => i.status == ShoppingItemStatus.purchased)
                  .map((i) => i.id)
                  .toList();

              for (final id in completedIds) {
                ref.read(shoppingListsProvider.notifier).deleteItemFromList(list.id, id);
              }

              Navigator.pop(context);
            },
            child: const Text('Rimuovi'),
          ),
        ],
      ),
    );
  }

  void _shareList(ShoppingList list) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Funzione condivisione in arrivo')),
    );
  }

  void _duplicateList(ShoppingList list) {
    final duplicated = list.copyWith(
      id: 'list_${DateTime.now().millisecondsSinceEpoch}',
      name: '${list.name} (Copia)',
      createdAt: DateTime.now(),
    );

    ref.read(shoppingListsProvider.notifier).addList(duplicated);

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Lista "${duplicated.name}" creata')),
    );
  }

  void _deleteList(ShoppingList list) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Elimina Lista'),
        content: Text('Eliminare "${list.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annulla'),
          ),
          TextButton(
            onPressed: () {
              ref.read(shoppingListsProvider.notifier).deleteList(list.id);
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close detail screen
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Lista "${list.name}" eliminata')),
              );
            },
            child: const Text('Elimina', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Map<ShoppingCategory, List<ShoppingItem>> _groupByCategory(List<ShoppingItem> items) {
    final Map<ShoppingCategory, List<ShoppingItem>> grouped = {};
    for (final item in items) {
      grouped.putIfAbsent(item.category, () => []).add(item);
    }
    return grouped;
  }

  String _getCategoryName(ShoppingCategory category) {
    switch (category) {
      case ShoppingCategory.groceries:
        return 'Alimentari';
      case ShoppingCategory.household:
        return 'Casa';
      case ShoppingCategory.personal:
        return 'Personale';
      case ShoppingCategory.electronics:
        return 'Elettronica';
      case ShoppingCategory.clothing:
        return 'Abbigliamento';
      case ShoppingCategory.health:
        return 'Salute';
      case ShoppingCategory.other:
        return 'Altro';
    }
  }

  IconData _getCategoryIcon(ShoppingCategory category) {
    switch (category) {
      case ShoppingCategory.groceries:
        return Icons.shopping_basket;
      case ShoppingCategory.household:
        return Icons.home;
      case ShoppingCategory.personal:
        return Icons.person;
      case ShoppingCategory.electronics:
        return Icons.devices;
      case ShoppingCategory.clothing:
        return Icons.checkroom;
      case ShoppingCategory.health:
        return Icons.local_hospital;
      case ShoppingCategory.other:
        return Icons.category;
    }
  }
}
