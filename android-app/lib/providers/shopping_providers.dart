import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/shopping_models.dart';

// Shopping Lists Provider
final shoppingListsProvider = StateNotifierProvider<ShoppingListsNotifier, List<ShoppingList>>((ref) {
  return ShoppingListsNotifier();
});

class ShoppingListsNotifier extends StateNotifier<List<ShoppingList>> {
  ShoppingListsNotifier() : super([]);

  void addList(ShoppingList list) {
    state = [...state, list];
  }

  void updateList(ShoppingList updatedList) {
    state = state.map((list) {
      return list.id == updatedList.id ? updatedList : list;
    }).toList();
  }

  void deleteList(String listId) {
    state = state.where((list) => list.id != listId).toList();
  }

  void addItemToList(String listId, ShoppingItem item) {
    state = state.map((list) {
      if (list.id == listId) {
        final updatedItems = [...list.items, item];
        return list.copyWith(
          items: updatedItems,
          updatedAt: DateTime.now(),
        );
      }
      return list;
    }).toList();
  }

  void updateItemInList(String listId, ShoppingItem updatedItem) {
    state = state.map((list) {
      if (list.id == listId) {
        final updatedItems = list.items.map((item) {
          return item.id == updatedItem.id ? updatedItem : item;
        }).toList();
        return list.copyWith(
          items: updatedItems,
          updatedAt: DateTime.now(),
        );
      }
      return list;
    }).toList();
  }

  void deleteItemFromList(String listId, String itemId) {
    state = state.map((list) {
      if (list.id == listId) {
        final updatedItems = list.items.where((item) => item.id != itemId).toList();
        return list.copyWith(
          items: updatedItems,
          updatedAt: DateTime.now(),
        );
      }
      return list;
    }).toList();
  }

  void toggleItemStatus(String listId, String itemId) {
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
        return list.copyWith(
          items: updatedItems,
          updatedAt: DateTime.now(),
        );
      }
      return list;
    }).toList();
  }

  void shareListWithFamily(String listId, List<String> familyMemberIds) {
    state = state.map((list) {
      if (list.id == listId) {
        return list.copyWith(
          sharedWith: familyMemberIds,
          updatedAt: DateTime.now(),
        );
      }
      return list;
    }).toList();
  }

  List<ShoppingList> getListsByCategory(ShoppingListCategory category) {
    return state.where((list) => list.category == category).toList();
  }

  List<ShoppingList> getSharedLists() {
    return state.where((list) => list.sharedWith.isNotEmpty).toList();
  }

  List<ShoppingList> getCompletedLists() {
    return state.where((list) => list.isCompleted).toList();
  }
}

// Shopping List Templates Provider
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
          'Carta igienica',
          'Fazzoletti',
          'Spugne',
          'Detersivo lavatrice',
          'Ammorbidente',
          'Candeggina',
          'Sacchetti spazzatura',
        ],
        isPublic: true,
        createdAt: DateTime.now(),
        createdBy: 'system',
      ),
      ShoppingListTemplate(
        id: 'template_personal',
        name: 'Cura Personale',
        description: 'Prodotti per la cura personale',
        category: ShoppingListCategory.personal,
        defaultItems: [
          'Shampoo',
          'Bagnoschiuma',
          'Dentifricio',
          'Spazzolino',
          'Crema viso',
          'Deodorante',
          'Rasoio',
          'Crema mani',
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

  void incrementUsage(String templateId) {
    state = state.map((template) {
      return template.id == templateId 
          ? template.copyWith(usageCount: template.usageCount + 1)
          : template;
    }).toList();
  }

  void markAsUsed(String templateId) {
    state = state.map((template) {
      return template.id == templateId 
          ? template.copyWith(
              usageCount: template.usageCount + 1,
              lastUsed: DateTime.now(),
            )
          : template;
    }).toList();
  }

  void toggleFavorite(String templateId) {
    state = state.map((template) {
      return template.id == templateId 
          ? template.copyWith(isFavorite: !template.isFavorite)
          : template;
    }).toList();
  }

  List<ShoppingListTemplate> getPublicTemplates() {
    return state.where((template) => template.isPublic).toList();
  }

  List<ShoppingListTemplate> getTemplatesByCategory(ShoppingListCategory category) {
    return state.where((template) => template.category == category).toList();
  }
}

// Current Shopping List Provider (for editing)
final currentShoppingListProvider = StateNotifierProvider<CurrentShoppingListNotifier, ShoppingList?>((ref) {
  return CurrentShoppingListNotifier();
});

class CurrentShoppingListNotifier extends StateNotifier<ShoppingList?> {
  CurrentShoppingListNotifier() : super(null);

  void setCurrentList(ShoppingList list) {
    state = list;
  }

  void clearCurrentList() {
    state = null;
  }

  void updateCurrentList(ShoppingList updatedList) {
    state = updatedList;
  }

  void addItem(ShoppingItem item) {
    if (state != null) {
      final updatedItems = [...state!.items, item];
      state = state!.copyWith(
        items: updatedItems,
        updatedAt: DateTime.now(),
      );
    }
  }

  void updateItem(ShoppingItem updatedItem) {
    if (state != null) {
      final updatedItems = state!.items.map((item) {
        return item.id == updatedItem.id ? updatedItem : item;
      }).toList();
      state = state!.copyWith(
        items: updatedItems,
        updatedAt: DateTime.now(),
      );
    }
  }

  void deleteItem(String itemId) {
    if (state != null) {
      final updatedItems = state!.items.where((item) => item.id != itemId).toList();
      state = state!.copyWith(
        items: updatedItems,
        updatedAt: DateTime.now(),
      );
    }
  }

  void toggleItemStatus(String itemId) {
    if (state != null) {
      final updatedItems = state!.items.map((item) {
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
      state = state!.copyWith(
        items: updatedItems,
        updatedAt: DateTime.now(),
      );
    }
  }
}

// Shopping Filter Provider
final shoppingFilterProvider = StateNotifierProvider<ShoppingFilterNotifier, ShoppingFilter>((ref) {
  return ShoppingFilterNotifier();
});

class ShoppingFilter {
  final ShoppingListCategory? category;
  final bool showCompleted;
  final bool showSharedOnly;
  final String searchQuery;

  const ShoppingFilter({
    this.category,
    this.showCompleted = true,
    this.showSharedOnly = false,
    this.searchQuery = '',
  });

  ShoppingFilter copyWith({
    ShoppingListCategory? category,
    bool? showCompleted,
    bool? showSharedOnly,
    String? searchQuery,
  }) {
    return ShoppingFilter(
      category: category ?? this.category,
      showCompleted: showCompleted ?? this.showCompleted,
      showSharedOnly: showSharedOnly ?? this.showSharedOnly,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class ShoppingFilterNotifier extends StateNotifier<ShoppingFilter> {
  ShoppingFilterNotifier() : super(const ShoppingFilter());

  void setCategory(ShoppingListCategory? category) {
    state = state.copyWith(category: category);
  }

  void toggleShowCompleted() {
    state = state.copyWith(showCompleted: !state.showCompleted);
  }

  void toggleShowSharedOnly() {
    state = state.copyWith(showSharedOnly: !state.showSharedOnly);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void resetFilters() {
    state = const ShoppingFilter();
  }
}

// T095 - Category Filter Provider
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