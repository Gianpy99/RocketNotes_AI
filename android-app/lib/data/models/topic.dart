// ==========================================
// lib/data/models/topic.dart
// ==========================================

import 'package:hive/hive.dart';
import 'package:flutter/material.dart';

part 'topic.g.dart';

@HiveType(typeId: 5) // Assicurati che typeId sia unico
class Topic extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String? description;

  @HiveField(3)
  int colorValue; // Salva il valore int del colore

  @HiveField(4)
  String? iconCodePoint; // Per icone personalizzate

  @HiveField(5)
  DateTime createdAt;

  @HiveField(6)
  DateTime updatedAt;

  @HiveField(7)
  String? userId; // Per multi-user support

  @HiveField(8)
  bool isFavorite;

  @HiveField(9)
  int noteCount; // Cache del numero di note

  Topic({
    required this.id,
    required this.name,
    this.description,
    required this.colorValue,
    this.iconCodePoint,
    required this.createdAt,
    required this.updatedAt,
    this.userId,
    this.isFavorite = false,
    this.noteCount = 0,
  });

  // Helper per ottenere il colore come oggetto Color
  Color get color => Color(colorValue);

  // Helper per ottenere l'icona
  IconData? get icon {
    if (iconCodePoint != null) {
      return IconData(int.parse(iconCodePoint!), fontFamily: 'MaterialIcons');
    }
    return null;
  }

  // Factory per creare un nuovo topic
  factory Topic.create({
    required String name,
    String? description,
    Color? color,
    IconData? icon,
    String? userId,
  }) {
    final now = DateTime.now();
    return Topic(
      id: now.millisecondsSinceEpoch.toString(),
      name: name,
      description: description,
      colorValue: (color ?? Colors.blue).value,
      iconCodePoint: icon?.codePoint.toString(),
      createdAt: now,
      updatedAt: now,
      userId: userId,
      isFavorite: false,
      noteCount: 0,
    );
  }

  // copyWith per aggiornamenti immutabili
  Topic copyWith({
    String? name,
    String? description,
    int? colorValue,
    String? iconCodePoint,
    DateTime? updatedAt,
    String? userId,
    bool? isFavorite,
    int? noteCount,
  }) {
    return Topic(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      colorValue: colorValue ?? this.colorValue,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      userId: userId ?? this.userId,
      isFavorite: isFavorite ?? this.isFavorite,
      noteCount: noteCount ?? this.noteCount,
    );
  }

  // Conversione JSON per Firestore
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'colorValue': colorValue,
      'iconCodePoint': iconCodePoint,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'userId': userId,
      'isFavorite': isFavorite,
      'noteCount': noteCount,
    };
  }

  factory Topic.fromJson(Map<String, dynamic> json) {
    return Topic(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      colorValue: json['colorValue'] as int,
      iconCodePoint: json['iconCodePoint'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      userId: json['userId'] as String?,
      isFavorite: json['isFavorite'] as bool? ?? false,
      noteCount: json['noteCount'] as int? ?? 0,
    );
  }

  @override
  String toString() {
    return 'Topic(id: $id, name: $name, noteCount: $noteCount)';
  }
}

// Colori predefiniti per i topic
class TopicColors {
  static const List<Color> predefined = [
    Color(0xFF2196F3), // Blue
    Color(0xFF4CAF50), // Green
    Color(0xFFFFC107), // Amber
    Color(0xFFE91E63), // Pink
    Color(0xFF9C27B0), // Purple
    Color(0xFFFF5722), // Deep Orange
    Color(0xFF00BCD4), // Cyan
    Color(0xFF795548), // Brown
    Color(0xFF607D8B), // Blue Grey
    Color(0xFF3F51B5), // Indigo
  ];

  static const Map<String, Color> themed = {
    'work': Color(0xFF1976D2),       // Blue
    'personal': Color(0xFF388E3C),   // Green
    'travel': Color(0xFFF57C00),     // Orange
    'meeting': Color(0xFF7B1FA2),    // Purple
    'project': Color(0xFFD32F2F),    // Red
    'learning': Color(0xFF0097A7),   // Cyan
    'health': Color(0xFFC2185B),     // Pink
    'finance': Color(0xFF689F38),    // Light Green
  };
}

// Icone predefinite per i topic
class TopicIcons {
  static const Map<String, IconData> predefined = {
    'work': Icons.work,
    'personal': Icons.person,
    'travel': Icons.flight,
    'meeting': Icons.meeting_room,
    'project': Icons.folder,
    'learning': Icons.school,
    'health': Icons.favorite,
    'finance': Icons.attach_money,
    'shopping': Icons.shopping_cart,
    'food': Icons.restaurant,
    'home': Icons.home,
    'car': Icons.directions_car,
  };
}
