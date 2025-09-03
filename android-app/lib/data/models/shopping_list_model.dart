// ==========================================
// lib/data/models/shopping_list_model.dart
// ==========================================
import 'package:hive/hive.dart';

part 'shopping_list_model.g.dart';

// TODO: SHOPPING_FEATURES - Add advanced shopping features
// - Add item categories (produce, dairy, bakery, etc.)
// - Add store location mapping
// - Add price tracking and budget
// - Add recipe integration
// - Add shopping trip history
// - Test generation

@HiveType(typeId: 13)
class ShoppingListItem extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  bool isCompleted;

  @HiveField(3)
  int quantity;

  @HiveField(4)
  String? unit; // 'pieces', 'kg', 'liters', etc.

  @HiveField(5)
  String category; // 'produce', 'dairy', 'bakery', 'meat', 'pantry', etc.

  @HiveField(6)
  String? notes;

  @HiveField(7)
  DateTime? completedAt;

  @HiveField(8)
  String? completedBy; // Family member ID

  @HiveField(9)
  DateTime createdAt;

  @HiveField(10)
  String createdBy; // Family member ID

  ShoppingListItem({
    required this.id,
    required this.name,
    this.isCompleted = false,
    this.quantity = 1,
    this.unit,
    this.category = 'pantry',
    this.notes,
    this.completedAt,
    this.completedBy,
    DateTime? createdAt,
    required this.createdBy,
  }) : createdAt = createdAt ?? DateTime.now();

  ShoppingListItem copyWith({
    String? name,
    bool? isCompleted,
    int? quantity,
    String? unit,
    String? category,
    String? notes,
    DateTime? completedAt,
    String? completedBy,
  }) {
    return ShoppingListItem(
      id: id,
      name: name ?? this.name,
      isCompleted: isCompleted ?? this.isCompleted,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      category: category ?? this.category,
      notes: notes ?? this.notes,
      completedAt: completedAt ?? this.completedAt,
      completedBy: completedBy ?? this.completedBy,
      createdAt: createdAt,
      createdBy: createdBy,
    );
  }

  // Mark as completed
  ShoppingListItem markCompleted({String? completedBy}) {
    return copyWith(
      isCompleted: true,
      completedAt: DateTime.now(),
      completedBy: completedBy,
    );
  }

  // Mark as not completed
  ShoppingListItem markIncomplete() {
    return copyWith(
      isCompleted: false,
      completedAt: null,
      completedBy: null,
    );
  }

  String get displayText {
    if (quantity > 1) {
      return '$quantity ${unit ?? 'x'} $name';
    }
    return name;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'isCompleted': isCompleted,
      'quantity': quantity,
      'unit': unit,
      'category': category,
      'notes': notes,
      'completedAt': completedAt?.toIso8601String(),
      'completedBy': completedBy,
      'createdAt': createdAt.toIso8601String(),
      'createdBy': createdBy,
    };
  }

  factory ShoppingListItem.fromJson(Map<String, dynamic> json) {
    return ShoppingListItem(
      id: json['id'] as String,
      name: json['name'] as String,
      isCompleted: json['isCompleted'] as bool? ?? false,
      quantity: json['quantity'] as int? ?? 1,
      unit: json['unit'] as String?,
      category: json['category'] as String? ?? 'pantry',
      notes: json['notes'] as String?,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      completedBy: json['completedBy'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      createdBy: json['createdBy'] as String,
    );
  }

  @override
  String toString() {
    return 'ShoppingListItem(id: $id, name: $name, completed: $isCompleted, quantity: $quantity)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ShoppingListItem && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

@HiveType(typeId: 14)
class ShoppingList extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String description;

  @HiveField(3)
  List<ShoppingListItem> items;

  @HiveField(4)
  String? storeName;

  @HiveField(5)
  DateTime? shoppingDate;

  @HiveField(6)
  bool isCompleted;

  @HiveField(7)
  DateTime? completedAt;

  @HiveField(8)
  DateTime createdAt;

  @HiveField(9)
  String createdBy; // Family member ID

  @HiveField(10)
  List<String> sharedWith; // Family member IDs

  ShoppingList({
    required this.id,
    required this.name,
    this.description = '',
    this.items = const [],
    this.storeName,
    this.shoppingDate,
    this.isCompleted = false,
    this.completedAt,
    DateTime? createdAt,
    required this.createdBy,
    this.sharedWith = const [],
  }) : createdAt = createdAt ?? DateTime.now();

  // Computed properties
  int get totalItems => items.length;
  int get completedItems => items.where((item) => item.isCompleted).length;
  int get remainingItems => totalItems - completedItems;
  double get completionPercentage => totalItems > 0 ? completedItems / totalItems : 0.0;

  // Get items by category
  Map<String, List<ShoppingListItem>> get itemsByCategory {
    final Map<String, List<ShoppingListItem>> categorized = {};
    for (final item in items) {
      categorized.putIfAbsent(item.category, () => []).add(item);
    }
    return categorized;
  }

  // Add item
  void addItem(ShoppingListItem item) {
    items.add(item);
  }

  // Remove item
  void removeItem(String itemId) {
    items.removeWhere((item) => item.id == itemId);
  }

  // Toggle item completion
  void toggleItem(String itemId, {String? completedBy}) {
    final index = items.indexWhere((item) => item.id == itemId);
    if (index != -1) {
      final item = items[index];
      if (item.isCompleted) {
        items[index] = item.markIncomplete();
      } else {
        items[index] = item.markCompleted(completedBy: completedBy);
      }
    }
  }

  // Mark list as completed
  void markCompleted() {
    isCompleted = true;
    completedAt = DateTime.now();
  }

  ShoppingList copyWith({
    String? name,
    String? description,
    List<ShoppingListItem>? items,
    String? storeName,
    DateTime? shoppingDate,
    bool? isCompleted,
    DateTime? completedAt,
    List<String>? sharedWith,
  }) {
    return ShoppingList(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      items: items ?? this.items,
      storeName: storeName ?? this.storeName,
      shoppingDate: shoppingDate ?? this.shoppingDate,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt,
      createdBy: createdBy,
      sharedWith: sharedWith ?? this.sharedWith,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'items': items.map((item) => item.toJson()).toList(),
      'storeName': storeName,
      'shoppingDate': shoppingDate?.toIso8601String(),
      'isCompleted': isCompleted,
      'completedAt': completedAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'createdBy': createdBy,
      'sharedWith': sharedWith,
    };
  }

  factory ShoppingList.fromJson(Map<String, dynamic> json) {
    return ShoppingList(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      items: (json['items'] as List?)
          ?.map((item) => ShoppingListItem.fromJson(item))
          .toList() ?? [],
      storeName: json['storeName'] as String?,
      shoppingDate: json['shoppingDate'] != null
          ? DateTime.parse(json['shoppingDate'] as String)
          : null,
      isCompleted: json['isCompleted'] as bool? ?? false,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      createdBy: json['createdBy'] as String,
      sharedWith: List<String>.from(json['sharedWith'] as List? ?? []),
    );
  }

  @override
  String toString() {
    return 'ShoppingList(id: $id, name: $name, items: $totalItems, completed: $completedItems)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ShoppingList && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
