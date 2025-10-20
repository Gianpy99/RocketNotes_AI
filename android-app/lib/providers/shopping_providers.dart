import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/shopping_models.dart';
import '../core/services/shopping_service.dart';
import '../data/models/shopping_list_model.dart' as hive_model;

// ==========================================
// Shopping Lists Provider with Hive persistence
// ==========================================

final shoppingListsProvider = StateNotifierProvider<ShoppingListsNotifier, List<ShoppingList>>((ref) {
  return ShoppingListsNotifier();
});

class ShoppingListsNotifier extends StateNotifier<List<ShoppingList>> {
  ShoppingListsNotifier() : super([]) {
    _initialize();
  }

  final _service = ShoppingService.instance;
  bool _isInitialized = false;

  // Initialize and load lists from Hive
  Future<void> _initialize() async {
    if (_isInitialized) return;
    
    try {
      await _service.initialize();
      await _loadLists();
      _isInitialized = true;
    } catch (e) {
      print('❌ Error initializing shopping provider: $e');
    }
  }

  // Load lists from Hive on initialization
  Future<void> _loadLists() async {
    try {
      final hiveLists = await _service.getAllShoppingLists();
      state = hiveLists.map((hiveList) => _convertFromHive(hiveList)).toList();
      print('✅ Loaded ${state.length} shopping lists from storage');
    } catch (e) {
      print('❌ Error loading shopping lists: $e');
    }
  }

  // Reload lists from storage
  Future<void> reload() async {
    await _loadLists();
  }

  // Convert Hive model to UI model
  ShoppingList _convertFromHive(hive_model.ShoppingList hiveList) {
    return ShoppingList(
      id: hiveList.id,
      name: hiveList.name,
      description: hiveList.description,
      category: _inferCategory(hiveList.items),
      items: hiveList.items.map((item) => ShoppingItem(
        id: item.id,
        name: item.name,
        quantity: item.quantity,
        unit: item.unit,
        category: _mapCategory(item.category),
        notes: item.notes,
        createdAt: item.createdAt,
        createdBy: item.createdBy,
        status: item.isCompleted ? ShoppingItemStatus.purchased : ShoppingItemStatus.pending,
        updatedAt: item.completedAt,
        updatedBy: item.completedBy,
      )).toList(),
      createdAt: hiveList.createdAt,
      createdBy: hiveList.createdBy,
      sharedWith: List<String>.from(hiveList.sharedWith),
      updatedAt: hiveList.completedAt,
    );
  }

  // Convert UI model to Hive model
  hive_model.ShoppingList _convertToHive(ShoppingList list) {
    return hive_model.ShoppingList(
      id: list.id,
      name: list.name,
      description: list.description ?? '',
      items: list.items.map((item) => hive_model.ShoppingListItem(
        id: item.id,
        name: item.name,
        quantity: item.quantity,
        unit: item.unit,
        category: _mapCategoryToString(item.category),
        notes: item.notes,
        createdAt: item.createdAt,
        createdBy: item.createdBy,
        isCompleted: item.status == ShoppingItemStatus.purchased,
        completedAt: item.updatedAt,
        completedBy: item.updatedBy,
      )).toList(),
      createdAt: list.createdAt,
      createdBy: list.createdBy,
      sharedWith: list.sharedWith,
      isCompleted: list.isCompleted,
      completedAt: list.updatedAt,
    );
  }

  ShoppingCategory _mapCategory(String category) {
    switch (category.toLowerCase()) {
      case 'produce':
      case 'dairy':
      case 'bakery':
      case 'meat':
      case 'pantry':
        return ShoppingCategory.groceries;
      case 'cleaning':
      case 'household':
        return ShoppingCategory.household;
      case 'personal':
      case 'hygiene':
        return ShoppingCategory.personal;
      case 'electronics':
      case 'tech':
        return ShoppingCategory.electronics;
      case 'clothing':
      case 'fashion':
        return ShoppingCategory.clothing;
      case 'health':
      case 'pharmacy':
        return ShoppingCategory.health;
      default:
        return ShoppingCategory.other;
    }
  }

  String _mapCategoryToString(ShoppingCategory category) {
    switch (category) {
      case ShoppingCategory.groceries:
        return 'pantry';
      case ShoppingCategory.household:
        return 'household';
      case ShoppingCategory.personal:
        return 'personal';
      case ShoppingCategory.electronics:
        return 'electronics';
      case ShoppingCategory.clothing:
        return 'clothing';
      case ShoppingCategory.health:
        return 'health';
      case ShoppingCategory.other:
        return 'other';
    }
  }

  ShoppingListCategory _inferCategory(List<hive_model.ShoppingListItem> items) {
    if (items.isEmpty) return ShoppingListCategory.groceries;
    
    // Count categories
    final categoryCounts = <String, int>{};
    for (final item in items) {
      categoryCounts[item.category] = (categoryCounts[item.category] ?? 0) + 1;
    }
    
    // Return most common category
    final mostCommon = categoryCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
    
    if (['produce', 'dairy', 'bakery', 'meat', 'pantry'].contains(mostCommon)) {
      return ShoppingListCategory.groceries;
    } else if (mostCommon == 'household') {
      return ShoppingListCategory.household;
    } else if (mostCommon == 'personal') {
      return ShoppingListCategory.personal;
    } else if (mostCommon == 'electronics') {
      return ShoppingListCategory.electronics;
    } else if (mostCommon == 'clothing') {
      return ShoppingListCategory.clothing;
    } else if (mostCommon == 'health') {
      return ShoppingListCategory.health;
    }
    
    return ShoppingListCategory.other;
  }

  // CRUD Operations with persistence

  Future<void> addList(ShoppingList list) async {
    state = [...state, list];
    await _service.addShoppingList(_convertToHive(list));
  }

  Future<void> updateList(ShoppingList updatedList) async {
    state = state.map((list) {
      return list.id == updatedList.id ? updatedList : list;
    }).toList();
    await _service.updateShoppingList(_convertToHive(updatedList));
  }

  Future<void> deleteList(String listId) async {
    state = state.where((list) => list.id != listId).toList();
    await _service.removeShoppingList(listId);
  }

  Future<void> addItemToList(String listId, ShoppingItem item) async {
    state = state.map((list) {
      if (list.id == listId) {
        final updatedItems = [...list.items, item];
        final updated = list.copyWith(
          items: updatedItems,
          updatedAt: DateTime.now(),
        );
        _service.updateShoppingList(_convertToHive(updated));
        return updated;
      }
      return list;
    }).toList();
  }

  Future<void> updateItemInList(String listId, ShoppingItem updatedItem) async {
    state = state.map((list) {
      if (list.id == listId) {
        final updatedItems = list.items.map((item) {
          return item.id == updatedItem.id ? updatedItem : item;
        }).toList();
        final updated = list.copyWith(
          items: updatedItems,
          updatedAt: DateTime.now(),
        );
        _service.updateShoppingList(_convertToHive(updated));
        return updated;
      }
      return list;
    }).toList();
  }

  Future<void> deleteItemFromList(String listId, String itemId) async {
    state = state.map((list) {
      if (list.id == listId) {
        final updatedItems = list.items.where((item) => item.id != itemId).toList();
        final updated = list.copyWith(
          items: updatedItems,
          updatedAt: DateTime.now(),
        );
        _service.updateShoppingList(_convertToHive(updated));
        return updated;
      }
      return list;
    }).toList();
  }

  Future<void> toggleItemStatus(String listId, String itemId) async {
    state = state.map((list) {
      if (list.id == listId) {
        final updatedItems = list.items.map((item) {
          if (item.id == itemId) {
            final newStatus = item.status == ShoppingItemStatus.pending 
                ? ShoppingItemStatus.purchased 
                : ShoppingItemStatus.pending;
            return item.copyWith(
              status: newStatus,
              updatedAt: DateTime.now(),
            );
          }
          return item;
        }).toList();
        final updated = list.copyWith(
          items: updatedItems,
          updatedAt: DateTime.now(),
        );
        _service.updateShoppingList(_convertToHive(updated));
        return updated;
      }
      return list;
    }).toList();
  }

  Future<void> shareListWithFamily(String listId, List<String> familyMemberIds) async {
    state = state.map((list) {
      if (list.id == listId) {
        final updated = list.copyWith(
          sharedWith: familyMemberIds,
          updatedAt: DateTime.now(),
        );
        _service.updateShoppingList(_convertToHive(updated));
        return updated;
      }
      return list;
    }).toList();
  }

  // Quick add item with AI-powered categorization
  Future<void> quickAddItem(String listId, String itemName, {
    int quantity = 1,
    String? unit,
    String? notes,
  }) async {
    final item = ShoppingItem(
      id: 'item_${DateTime.now().millisecondsSinceEpoch}',
      name: itemName,
      quantity: quantity,
      unit: unit,
      notes: notes,
      category: _guessCategory(itemName),
      createdAt: DateTime.now(),
      createdBy: 'current_user',
      status: ShoppingItemStatus.pending,
    );
    
    await addItemToList(listId, item);
  }

  // AI-powered category guessing based on item name
  ShoppingCategory _guessCategory(String itemName) {
    final lower = itemName.toLowerCase();
    
    // Groceries
    if (lower.contains(RegExp(r'latte|pane|uova|pasta|riso|farina|olio|zucchero|sale|caffè|tè|acqua|succo|vino|birra|carne|pollo|pesce|verdure|frutta|formaggio|yogurt|burro'))) {
      return ShoppingCategory.groceries;
    }
    
    // Household
    if (lower.contains(RegExp(r'detersivo|sapone|candeggina|spugna|sacchi|carta|scottex|fazzoletti|lampadine|pile'))) {
      return ShoppingCategory.household;
    }
    
    // Personal
    if (lower.contains(RegExp(r'shampoo|balsamo|doccia|bagno|denti|spazzolino|rasoi|crema|profumo|trucco'))) {
      return ShoppingCategory.personal;
    }
    
    // Health
    if (lower.contains(RegExp(r'vitamina|farmaco|medicina|cerotti|aspirina|antibiotico|sciroppo|termometro|pressione'))) {
      return ShoppingCategory.health;
    }
    
    // Electronics
    if (lower.contains(RegExp(r'cavo|caricatore|auricolari|mouse|tastiera|smartphone|tablet|computer|usb|sd|hdmi'))) {
      return ShoppingCategory.electronics;
    }
    
    // Clothing
    if (lower.contains(RegExp(r'maglietta|pantaloni|gonna|vestito|scarpe|calze|giacca|cappotto|sciarpa|guanti|cappello'))) {
      return ShoppingCategory.clothing;
    }
    
    return ShoppingCategory.other;
  }

  // Filter methods
  List<ShoppingList> getListsByCategory(ShoppingListCategory category) {
    return state.where((list) => list.category == category).toList();
  }

  List<ShoppingList> getSharedLists() {
    return state.where((list) => list.sharedWith.isNotEmpty).toList();
  }

  List<ShoppingList> getCompletedLists() {
    return state.where((list) => list.isCompleted).toList();
  }

  List<ShoppingList> getActiveLists() {
    return state.where((list) => !list.isCompleted).toList();
  }

  // Get list by ID
  ShoppingList? getListById(String id) {
    try {
      return state.firstWhere((list) => list.id == id);
    } catch (e) {
      return null;
    }
  }

  // Statistics
  int get totalLists => state.length;
  int get activeLists => getActiveLists().length;
  int get completedLists => getCompletedLists().length;
  int get sharedLists => getSharedLists().length;
}

// ==========================================
// Shopping Templates Provider
// ==========================================

final shoppingTemplatesProvider = StateNotifierProvider<ShoppingTemplatesNotifier, List<ShoppingListTemplate>>((ref) {
  return ShoppingTemplatesNotifier();
});

class ShoppingTemplatesNotifier extends StateNotifier<List<ShoppingListTemplate>> {
  ShoppingTemplatesNotifier() : super(_getDefaultTemplates());

  static List<ShoppingListTemplate> _getDefaultTemplates() {
    return [
      ShoppingListTemplate(
        id: 'template_groceries',
        name: 'Spesa Settimanale',
        description: 'Template per la spesa settimanale di base',
        category: ShoppingListCategory.groceries,
        defaultItems: [
          'Latte',
          'Pane',
          'Uova',
          'Pasta',
          'Pomodori',
          'Banane',
          'Mele',
          'Carne',
          'Formaggio',
          'Yogurt',
        ],
        isPublic: true,
        createdAt: DateTime.now(),
        createdBy: 'system',
      ),
      ShoppingListTemplate(
        id: 'template_household',
        name: 'Casa e Pulizie',
        description: 'Prodotti per la casa e le pulizie',
        category: ShoppingListCategory.household,
        defaultItems: [
          'Detersivo piatti',
          'Detersivo lavatrice',
          'Candeggina',
          'Spugne',
          'Sacchi spazzatura',
          'Carta igienica',
          'Scottex',
        ],
        isPublic: true,
        createdAt: DateTime.now(),
        createdBy: 'system',
      ),
      ShoppingListTemplate(
        id: 'template_party',
        name: 'Festa/Party',
        description: 'Acquisti per organizzare una festa',
        category: ShoppingListCategory.other,
        defaultItems: [
          'Piatti usa e getta',
          'Bicchieri',
          'Posate',
          'Tovaglioli',
          'Snack',
          'Bevande',
          'Decorazioni',
        ],
        isPublic: true,
        createdAt: DateTime.now(),
        createdBy: 'system',
      ),
    ];
  }

  void addTemplate(ShoppingListTemplate template) {
    state = [...state, template];
  }

  void updateTemplate(ShoppingListTemplate updatedTemplate) {
    state = state.map((template) {
      return template.id == updatedTemplate.id ? updatedTemplate : template;
    }).toList();
  }

  void deleteTemplate(String templateId) {
    state = state.where((template) => template.id != templateId).toList();
  }

  // Mark template as used (increment usage count)
  void markAsUsed(String templateId) {
    state = state.map((template) {
      if (template.id == templateId) {
        return ShoppingListTemplate(
          id: template.id,
          name: template.name,
          description: template.description,
          category: template.category,
          defaultItems: template.defaultItems,
          isPublic: template.isPublic,
          createdAt: template.createdAt,
          createdBy: template.createdBy,
          isFavorite: template.isFavorite,
          usageCount: template.usageCount + 1,
          lastUsed: DateTime.now(),
        );
      }
      return template;
    }).toList();
  }

  // Toggle favorite status
  void toggleFavorite(String templateId) {
    state = state.map((template) {
      if (template.id == templateId) {
        return ShoppingListTemplate(
          id: template.id,
          name: template.name,
          description: template.description,
          category: template.category,
          defaultItems: template.defaultItems,
          isPublic: template.isPublic,
          createdAt: template.createdAt,
          createdBy: template.createdBy,
          isFavorite: !template.isFavorite,
          usageCount: template.usageCount,
          lastUsed: template.lastUsed,
        );
      }
      return template;
    }).toList();
  }

  // Create shopping list from template
  ShoppingList createListFromTemplate(String templateId, String createdBy) {
    final template = state.firstWhere((t) => t.id == templateId);
    
    final items = template.defaultItems.map((itemName) {
      return ShoppingItem(
        id: 'item_${DateTime.now().millisecondsSinceEpoch}_${itemName.hashCode}',
        name: itemName,
        quantity: 1,
        category: template.category == ShoppingListCategory.groceries 
            ? ShoppingCategory.groceries 
            : ShoppingCategory.household,
        createdAt: DateTime.now(),
        createdBy: createdBy,
        status: ShoppingItemStatus.pending,
      );
    }).toList();

    return ShoppingList(
      id: 'list_${DateTime.now().millisecondsSinceEpoch}',
      name: template.name,
      description: 'Creata da template: ${template.description}',
      category: template.category,
      items: items,
      createdAt: DateTime.now(),
      createdBy: createdBy,
      sharedWith: [],
    );
  }
}

// ==========================================
// Category Filter Provider
// ==========================================

final categoryFilterProvider = StateNotifierProvider<CategoryFilterNotifier, ShoppingCategory?>((ref) {
  return CategoryFilterNotifier();
});

class CategoryFilterNotifier extends StateNotifier<ShoppingCategory?> {
  CategoryFilterNotifier() : super(null);

  void setFilter(ShoppingCategory category) {
    state = category;
  }

  void clearFilter() {
    state = null;
  }
}
