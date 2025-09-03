// ==========================================
// lib/core/services/shopping_service.dart
// ==========================================
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../data/models/shopping_list_model.dart';

// TODO: SHOPPING_FEATURES - Add advanced shopping features
// - Add voice-to-text for adding items while shopping
// - Add location-based store detection
// - Add price comparison and budget tracking
// - Add recipe-to-shopping-list conversion
// - Add shopping trip analytics

class ShoppingService {
  static const String shoppingListsBox = 'shoppingLists';

  static ShoppingService? _instance;
  static ShoppingService get instance {
    _instance ??= ShoppingService._();
    return _instance!;
  }

  ShoppingService._();

  Box<ShoppingList>? _shoppingListsBox;

  Future<void> initialize() async {
    try {
      _shoppingListsBox = await Hive.openBox<ShoppingList>(shoppingListsBox);
      debugPrint('✅ Shopping service initialized successfully');
    } catch (e) {
      debugPrint('❌ Error initializing shopping service: $e');
      rethrow;
    }
  }

  // Shopping List CRUD
  Future<List<ShoppingList>> getAllShoppingLists() async {
    return _shoppingListsBox?.values.toList() ?? [];
  }

  Future<ShoppingList?> getShoppingList(String id) async {
    return _shoppingListsBox?.get(id);
  }

  Future<void> addShoppingList(ShoppingList list) async {
    await _shoppingListsBox?.put(list.id, list);
    debugPrint('✅ Added shopping list: ${list.name}');
  }

  Future<void> updateShoppingList(ShoppingList list) async {
    await _shoppingListsBox?.put(list.id, list);
    debugPrint('✅ Updated shopping list: ${list.name}');
  }

  Future<void> removeShoppingList(String id) async {
    await _shoppingListsBox?.delete(id);
    debugPrint('✅ Removed shopping list: $id');
  }

  // Shopping List Item Management
  Future<void> addItemToList(String listId, ShoppingListItem item) async {
    final list = await getShoppingList(listId);
    if (list != null) {
      list.addItem(item);
      await updateShoppingList(list);
    }
  }

  Future<void> removeItemFromList(String listId, String itemId) async {
    final list = await getShoppingList(listId);
    if (list != null) {
      list.removeItem(itemId);
      await updateShoppingList(list);
    }
  }

  Future<void> toggleItemCompletion(String listId, String itemId, {String? completedBy}) async {
    final list = await getShoppingList(listId);
    if (list != null) {
      list.toggleItem(itemId, completedBy: completedBy);
      await updateShoppingList(list);
    }
  }

  // Quick item addition (for voice input)
  Future<ShoppingListItem> createQuickItem(String name, {
    int quantity = 1,
    String? unit,
    String category = 'pantry',
    String? notes,
    required String createdBy,
  }) async {
    final item = ShoppingListItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      quantity: quantity,
      unit: unit,
      category: category,
      notes: notes,
      createdBy: createdBy,
    );
    return item;
  }

  // Get active shopping lists (not completed)
  Future<List<ShoppingList>> getActiveShoppingLists() async {
    final allLists = await getAllShoppingLists();
    return allLists.where((list) => !list.isCompleted).toList();
  }

  // Get shopping lists for specific family member
  Future<List<ShoppingList>> getShoppingListsForMember(String memberId) async {
    final allLists = await getAllShoppingLists();
    return allLists.where((list) =>
      list.createdBy == memberId ||
      list.sharedWith.contains(memberId)
    ).toList();
  }

  // Create predefined shopping lists
  Future<ShoppingList> createWeeklyGroceryList({required String createdBy}) async {
    final list = ShoppingList(
      id: 'weekly_grocery_${DateTime.now().millisecondsSinceEpoch}',
      name: 'Weekly Grocery Shopping',
      description: 'Regular weekly grocery items',
      createdBy: createdBy,
    );

    // Add common grocery items
    final commonItems = [
      ShoppingListItem(
        id: 'milk_${DateTime.now().millisecondsSinceEpoch}',
        name: 'Milk',
        quantity: 1,
        unit: 'liter',
        category: 'dairy',
        createdBy: createdBy,
      ),
      ShoppingListItem(
        id: 'bread_${DateTime.now().millisecondsSinceEpoch}',
        name: 'Bread',
        quantity: 1,
        unit: 'loaf',
        category: 'bakery',
        createdBy: createdBy,
      ),
      ShoppingListItem(
        id: 'eggs_${DateTime.now().millisecondsSinceEpoch}',
        name: 'Eggs',
        quantity: 12,
        category: 'dairy',
        createdBy: createdBy,
      ),
      ShoppingListItem(
        id: 'bananas_${DateTime.now().millisecondsSinceEpoch}',
        name: 'Bananas',
        quantity: 6,
        category: 'produce',
        createdBy: createdBy,
      ),
    ];

    for (final item in commonItems) {
      list.addItem(item);
    }

    await addShoppingList(list);
    return list;
  }

  // Voice command processing
  Future<String?> processVoiceCommand(String command, String listId, String memberId) async {
    final lowerCommand = command.toLowerCase();

    // Parse voice commands like:
    // "Add milk to shopping list"
    // "I found the bread"
    // "Remove eggs from list"
    // "Check off bananas"

    if (lowerCommand.contains('add') || lowerCommand.contains('aggiungi')) {
      final itemName = _extractItemName(lowerCommand);
      if (itemName != null) {
        final item = await createQuickItem(itemName, createdBy: memberId);
        await addItemToList(listId, item);
        return 'Added $itemName to shopping list';
      }
    }

    if (lowerCommand.contains('found') || lowerCommand.contains('check') ||
        lowerCommand.contains('trovato') || lowerCommand.contains('spunta')) {
      final itemName = _extractItemName(lowerCommand);
      if (itemName != null) {
        final list = await getShoppingList(listId);
        if (list != null) {
          final item = list.items.firstWhere(
            (item) => item.name.toLowerCase().contains(itemName.toLowerCase()),
            orElse: () => ShoppingListItem(id: '', name: '', createdBy: ''),
          );
          if (item.id.isNotEmpty) {
            await toggleItemCompletion(listId, item.id, completedBy: memberId);
            return 'Checked off $itemName';
          }
        }
      }
    }

    if (lowerCommand.contains('remove') || lowerCommand.contains('delete') ||
        lowerCommand.contains('rimuovi') || lowerCommand.contains('elimina')) {
      final itemName = _extractItemName(lowerCommand);
      if (itemName != null) {
        final list = await getShoppingList(listId);
        if (list != null) {
          final item = list.items.firstWhere(
            (item) => item.name.toLowerCase().contains(itemName.toLowerCase()),
            orElse: () => ShoppingListItem(id: '', name: '', createdBy: ''),
          );
          if (item.id.isNotEmpty) {
            await removeItemFromList(listId, item.id);
            return 'Removed $itemName from shopping list';
          }
        }
      }
    }

    return 'Sorry, I didn\'t understand that command';
  }

  String? _extractItemName(String command) {
    // Simple extraction - could be enhanced with NLP
    final words = command.split(' ');
    final keywords = ['add', 'aggiungi', 'found', 'trovato', 'check', 'spunta',
                     'remove', 'rimuovi', 'delete', 'elimina', 'from', 'to', 'the'];

    for (final word in words) {
      if (!keywords.contains(word.toLowerCase()) && word.length > 2) {
        return word;
      }
    }
    return null;
  }

  // Data export/import
  Future<String> exportShoppingData() async {
    final lists = await getAllShoppingLists();
    final data = {
      'shoppingLists': lists.map((list) => list.toJson()).toList(),
      'exportDate': DateTime.now().toIso8601String(),
    };
    return jsonEncode(data);
  }

  Future<void> importShoppingData(String jsonData) async {
    try {
      final data = jsonDecode(jsonData) as Map<String, dynamic>;
      final listsData = data['shoppingLists'] as List?;

      if (listsData != null) {
        for (final listData in listsData) {
          final list = ShoppingList.fromJson(listData);
          await addShoppingList(list);
        }
      }

      debugPrint('✅ Imported shopping data successfully');
    } catch (e) {
      debugPrint('❌ Error importing shopping data: $e');
      rethrow;
    }
  }

  // Cleanup
  Future<void> dispose() async {
    await _shoppingListsBox?.close();
    _shoppingListsBox = null;
  }
}
