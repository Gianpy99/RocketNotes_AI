// Data models for shopping list functionality (T091-T095)

enum ShoppingItemStatus {
  pending,
  purchased,
  cancelled,
}

enum ShoppingListCategory {
  groceries,
  household,
  personal,
  electronics,
  clothing,
  health,
  other,
}

enum ShoppingItemPriority {
  low,
  normal,
  high,
  urgent,
}

// T095 - Enum per categorie dei prodotti shopping
enum ShoppingCategory {
  groceries,    // Alimentari
  household,    // Casa
  personal,     // Personale
  electronics,  // Elettronica
  clothing,     // Abbigliamento
  health,       // Salute
  other,        // Altro
}

class ShoppingItem {
  final String id;
  final String name;
  final String? description;
  final int quantity;
  final String? unit;
  final ShoppingItemStatus status;
  final ShoppingItemPriority priority;
  final ShoppingCategory category;
  final double? estimatedPrice;
  final double? actualPrice;
  final String? notes;
  final String? imageUrl;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String createdBy;
  final String? updatedBy;

  const ShoppingItem({
    required this.id,
    required this.name,
    this.description,
    this.quantity = 1,
    this.unit,
    this.status = ShoppingItemStatus.pending,
    this.priority = ShoppingItemPriority.normal,
    this.category = ShoppingCategory.other,
    this.estimatedPrice,
    this.actualPrice,
    this.notes,
    this.imageUrl,
    required this.createdAt,
    this.updatedAt,
    required this.createdBy,
    this.updatedBy,
  });

  ShoppingItem copyWith({
    String? id,
    String? name,
    String? description,
    int? quantity,
    String? unit,
    ShoppingItemStatus? status,
    ShoppingItemPriority? priority,
    ShoppingCategory? category,
    double? estimatedPrice,
    double? actualPrice,
    String? notes,
    String? imageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? updatedBy,
  }) {
    return ShoppingItem(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      category: category ?? this.category,
      estimatedPrice: estimatedPrice ?? this.estimatedPrice,
      actualPrice: actualPrice ?? this.actualPrice,
      notes: notes ?? this.notes,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'quantity': quantity,
      'unit': unit,
      'status': status.name,
      'priority': priority.name,
      'category': category.name,
      'estimatedPrice': estimatedPrice,
      'actualPrice': actualPrice,
      'notes': notes,
      'imageUrl': imageUrl,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'createdBy': createdBy,
      'updatedBy': updatedBy,
    };
  }

  factory ShoppingItem.fromJson(Map<String, dynamic> json) {
    return ShoppingItem(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      quantity: json['quantity'] as int? ?? 1,
      unit: json['unit'] as String?,
      status: ShoppingItemStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => ShoppingItemStatus.pending,
      ),
      priority: ShoppingItemPriority.values.firstWhere(
        (e) => e.name == json['priority'],
        orElse: () => ShoppingItemPriority.normal,
      ),
      category: ShoppingCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => ShoppingCategory.other,
      ),
      estimatedPrice: json['estimatedPrice'] as double?,
      actualPrice: json['actualPrice'] as double?,
      notes: json['notes'] as String?,
      imageUrl: json['imageUrl'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt'] as String) : null,
      createdBy: json['createdBy'] as String,
      updatedBy: json['updatedBy'] as String?,
    );
  }
}

class ShoppingList {
  final String id;
  final String name;
  final String? description;
  final ShoppingListCategory category;
  final List<ShoppingItem> items;
  final List<String> sharedWith;
  final String? templateId;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String createdBy;
  final String? updatedBy;
  final Map<String, dynamic>? metadata;

  const ShoppingList({
    required this.id,
    required this.name,
    this.description,
    this.category = ShoppingListCategory.groceries,
    this.items = const [],
    this.sharedWith = const [],
    this.templateId,
    this.isCompleted = false,
    required this.createdAt,
    this.updatedAt,
    required this.createdBy,
    this.updatedBy,
    this.metadata,
  });

  ShoppingList copyWith({
    String? id,
    String? name,
    String? description,
    ShoppingListCategory? category,
    List<ShoppingItem>? items,
    List<String>? sharedWith,
    String? templateId,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? updatedBy,
    Map<String, dynamic>? metadata,
  }) {
    return ShoppingList(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      items: items ?? this.items,
      sharedWith: sharedWith ?? this.sharedWith,
      templateId: templateId ?? this.templateId,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category.name,
      'items': items.map((item) => item.toJson()).toList(),
      'sharedWith': sharedWith,
      'templateId': templateId,
      'isCompleted': isCompleted,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'createdBy': createdBy,
      'updatedBy': updatedBy,
      'metadata': metadata,
    };
  }

  factory ShoppingList.fromJson(Map<String, dynamic> json) {
    return ShoppingList(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      category: ShoppingListCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => ShoppingListCategory.groceries,
      ),
      items: (json['items'] as List<dynamic>?)
          ?.map((item) => ShoppingItem.fromJson(item as Map<String, dynamic>))
          .toList() ?? [],
      sharedWith: (json['sharedWith'] as List<dynamic>?)?.cast<String>() ?? [],
      templateId: json['templateId'] as String?,
      isCompleted: json['isCompleted'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt'] as String) : null,
      createdBy: json['createdBy'] as String,
      updatedBy: json['updatedBy'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  // Helper methods
  int get totalItems => items.length;
  int get pendingItems => items.where((item) => item.status == ShoppingItemStatus.pending).length;
  int get purchasedItems => items.where((item) => item.status == ShoppingItemStatus.purchased).length;
  double get totalEstimatedPrice => items.fold(0.0, (sum, item) => sum + (item.estimatedPrice ?? 0.0));
  double get totalActualPrice => items.fold(0.0, (sum, item) => sum + (item.actualPrice ?? 0.0));
  double get completionPercentage => totalItems > 0 ? (purchasedItems / totalItems) * 100 : 0.0;
}

class ShoppingListTemplate {
  final String id;
  final String name;
  final String? description;
  final ShoppingListCategory category;
  final List<String> defaultItems;
  final bool isPublic;
  final DateTime createdAt;
  final String createdBy;
  final int usageCount;
  final bool isFavorite;
  final bool isPopular;
  final DateTime? lastUsed;

  const ShoppingListTemplate({
    required this.id,
    required this.name,
    this.description,
    this.category = ShoppingListCategory.groceries,
    this.defaultItems = const [],
    this.isPublic = false,
    required this.createdAt,
    required this.createdBy,
    this.usageCount = 0,
    this.isFavorite = false,
    this.isPopular = false,
    this.lastUsed,
  });

  ShoppingListTemplate copyWith({
    String? id,
    String? name,
    String? description,
    ShoppingListCategory? category,
    List<String>? defaultItems,
    bool? isPublic,
    DateTime? createdAt,
    String? createdBy,
    int? usageCount,
    bool? isFavorite,
    bool? isPopular,
    DateTime? lastUsed,
  }) {
    return ShoppingListTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      defaultItems: defaultItems ?? this.defaultItems,
      isPublic: isPublic ?? this.isPublic,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      usageCount: usageCount ?? this.usageCount,
      isFavorite: isFavorite ?? this.isFavorite,
      isPopular: isPopular ?? this.isPopular,
      lastUsed: lastUsed ?? this.lastUsed,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category.name,
      'defaultItems': defaultItems,
      'isPublic': isPublic,
      'createdAt': createdAt.toIso8601String(),
      'createdBy': createdBy,
      'usageCount': usageCount,
      'isFavorite': isFavorite,
      'isPopular': isPopular,
      'lastUsed': lastUsed?.toIso8601String(),
    };
  }

  factory ShoppingListTemplate.fromJson(Map<String, dynamic> json) {
    return ShoppingListTemplate(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      category: ShoppingListCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => ShoppingListCategory.groceries,
      ),
      defaultItems: (json['defaultItems'] as List<dynamic>?)?.cast<String>() ?? [],
      isPublic: json['isPublic'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      createdBy: json['createdBy'] as String,
      usageCount: json['usageCount'] as int? ?? 0,
      isFavorite: json['isFavorite'] as bool? ?? false,
      isPopular: json['isPopular'] as bool? ?? false,
      lastUsed: json['lastUsed'] != null ? DateTime.parse(json['lastUsed'] as String) : null,
    );
  }
}