// ==========================================
// lib/data/models/shared_notebook_model.dart
// ==========================================
import 'package:hive/hive.dart';

part 'shared_notebook_model.g.dart';

// Quaderni condivisi implementati

@HiveType(typeId: 2)
class SharedNotebook extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String description;

  @HiveField(3)
  String category; // 'shopping', 'recipes', 'reminders', 'general', etc.

  @HiveField(4)
  String? iconName; // Icon identifier for UI

  @HiveField(5)
  String? color; // Theme color

  @HiveField(6)
  List<String> memberIds; // Family members with access

  @HiveField(7)
  Map<String, List<String>> permissions; // memberId -> ['read', 'write', 'admin']

  @HiveField(8)
  DateTime createdAt;

  @HiveField(9)
  DateTime updatedAt;

  @HiveField(10)
  String createdBy; // Family member ID who created it

  SharedNotebook({
    required this.id,
    required this.name,
    this.description = '',
    this.category = 'general',
    this.iconName,
    this.color,
    this.memberIds = const [],
    Map<String, List<String>>? permissions,
    DateTime? createdAt,
    DateTime? updatedAt,
    required this.createdBy,
  })  : permissions = permissions ?? {},
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  // Predefined notebook templates
  static SharedNotebook shoppingList({required String createdBy}) {
    return SharedNotebook(
      id: 'shopping_${DateTime.now().millisecondsSinceEpoch}',
      name: 'Shopping List',
      description: 'Family shopping list and groceries',
      category: 'shopping',
      iconName: 'shopping_cart',
      color: '#4CAF50',
      createdBy: createdBy,
    );
  }

  static SharedNotebook reminders({required String createdBy}) {
    return SharedNotebook(
      id: 'reminders_${DateTime.now().millisecondsSinceEpoch}',
      name: 'Family Reminders',
      description: 'Important dates and reminders',
      category: 'reminders',
      iconName: 'event_note',
      color: '#2196F3',
      createdBy: createdBy,
    );
  }

  static SharedNotebook recipes({required String createdBy}) {
    return SharedNotebook(
      id: 'recipes_${DateTime.now().millisecondsSinceEpoch}',
      name: 'Family Recipes',
      description: 'Favorite family recipes and cooking notes',
      category: 'recipes',
      iconName: 'restaurant',
      color: '#FF9800',
      createdBy: createdBy,
    );
  }

  bool hasPermission(String memberId, String permission) {
    final memberPermissions = permissions[memberId];
    return memberPermissions?.contains(permission) ?? false;
  }

  void addMember(String memberId, {List<String> memberPermissions = const ['read', 'write']}) {
    if (!memberIds.contains(memberId)) {
      memberIds.add(memberId);
      permissions[memberId] = memberPermissions;
      updatedAt = DateTime.now();
    }
  }

  void removeMember(String memberId) {
    memberIds.remove(memberId);
    permissions.remove(memberId);
    updatedAt = DateTime.now();
  }

  SharedNotebook copyWith({
    String? name,
    String? description,
    String? category,
    String? iconName,
    String? color,
    List<String>? memberIds,
    Map<String, List<String>>? permissions,
    DateTime? updatedAt,
  }) {
    return SharedNotebook(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      iconName: iconName ?? this.iconName,
      color: color ?? this.color,
      memberIds: memberIds ?? this.memberIds,
      permissions: permissions ?? this.permissions,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      createdBy: createdBy,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category,
      'iconName': iconName,
      'color': color,
      'memberIds': memberIds,
      'permissions': permissions,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'createdBy': createdBy,
    };
  }

  factory SharedNotebook.fromJson(Map<String, dynamic> json) {
    return SharedNotebook(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      category: json['category'] as String? ?? 'general',
      iconName: json['iconName'] as String?,
      color: json['color'] as String?,
      memberIds: List<String>.from(json['memberIds'] as List? ?? []),
      permissions: Map<String, List<String>>.from(
        (json['permissions'] as Map? ?? {}).map(
          (key, value) => MapEntry(key, List<String>.from(value)),
        ),
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      createdBy: json['createdBy'] as String,
    );
  }

  @override
  String toString() {
    return 'SharedNotebook(id: $id, name: $name, category: $category, members: ${memberIds.length})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SharedNotebook && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
