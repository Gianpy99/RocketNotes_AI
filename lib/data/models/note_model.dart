// ==========================================
// lib/data/models/note_model.dart
// ==========================================
import 'package:hive/hive.dart';

part 'note_model.g.dart';

@HiveType(typeId: 0)
class NoteModel extends HiveObject {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  String content;
  
  @HiveField(2)
  final String mode; // 'work' or 'personal'
  
  @HiveField(3)
  final DateTime createdAt;
  
  @HiveField(4)
  DateTime updatedAt;
  
  @HiveField(5)
  List<String> tags;
  
  @HiveField(6)
  String? aiSummary;
  
  @HiveField(7)
  List<String> attachments;
  
  @HiveField(8)
  String? nfcTagId;
  
  @HiveField(9)
  String title;
  
  @HiveField(10)
  bool isFavorite;
  
  @HiveField(11)
  String? color; // For custom note colors
  
  @HiveField(12)
  int priority; // 0 = low, 1 = medium, 2 = high
  
  @HiveField(13)
  DateTime? reminderDate;
  
  @HiveField(14)
  bool isArchived;

  NoteModel({
    required this.id,
    required this.content,
    required this.mode,
    required this.createdAt,
    required this.updatedAt,
    required this.title,
    this.tags = const [],
    this.aiSummary,
    this.attachments = const [],
    this.nfcTagId,
    this.isFavorite = false,
    this.color,
    this.priority = 0,
    this.reminderDate,
    this.isArchived = false,
  });

  // Factory constructor for creating a new note
  factory NoteModel.create({
    required String title,
    required String content,
    required String mode,
    List<String>? tags,
    String? color,
    int priority = 0,
  }) {
    final now = DateTime.now();
    return NoteModel(
      id: now.millisecondsSinceEpoch.toString(),
      title: title,
      content: content,
      mode: mode,
      createdAt: now,
      updatedAt: now,
      tags: tags ?? [],
      color: color,
      priority: priority,
    );
  }

  // Copy with method for immutable updates
  NoteModel copyWith({
    String? content,
    String? title,
    DateTime? updatedAt,
    List<String>? tags,
    String? aiSummary,
    List<String>? attachments,
    bool? isFavorite,
    String? color,
    int? priority,
    DateTime? reminderDate,
    bool? isArchived,
  }) {
    return NoteModel(
      id: id,
      content: content ?? this.content,
      mode: mode,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      title: title ?? this.title,
      tags: tags ?? this.tags,
      aiSummary: aiSummary ?? this.aiSummary,
      attachments: attachments ?? this.attachments,
      nfcTagId: nfcTagId,
      isFavorite: isFavorite ?? this.isFavorite,
      color: color ?? this.color,
      priority: priority ?? this.priority,
      reminderDate: reminderDate ?? this.reminderDate,
      isArchived: isArchived ?? this.isArchived,
    );
  }

  // Utility methods
  bool get hasReminder => reminderDate != null;
  bool get isOverdue => reminderDate != null && reminderDate!.isBefore(DateTime.now());
  bool get isEmpty => title.trim().isEmpty && content.trim().isEmpty;
  
  String get displayTitle => title.isEmpty ? 'Untitled Note' : title;
  
  String get priorityText {
    switch (priority) {
      case 2:
        return 'High';
      case 1:
        return 'Medium';
      default:
        return 'Low';
    }
  }
  
  // Search helper
  bool matchesQuery(String query) {
    final lowercaseQuery = query.toLowerCase();
    return title.toLowerCase().contains(lowercaseQuery) ||
           content.toLowerCase().contains(lowercaseQuery) ||
           tags.any((tag) => tag.toLowerCase().contains(lowercaseQuery)) ||
           (aiSummary?.toLowerCase().contains(lowercaseQuery) ?? false);
  }
  
  // JSON serialization (for backup/export)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'mode': mode,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'title': title,
      'tags': tags,
      'aiSummary': aiSummary,
      'attachments': attachments,
      'nfcTagId': nfcTagId,
      'isFavorite': isFavorite,
      'color': color,
      'priority': priority,
      'reminderDate': reminderDate?.toIso8601String(),
      'isArchived': isArchived,
    };
  }
  
  factory NoteModel.fromJson(Map<String, dynamic> json) {
    return NoteModel(
      id: json['id'] as String,
      content: json['content'] as String,
      mode: json['mode'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      title: json['title'] as String,
      tags: List<String>.from(json['tags'] as List? ?? []),
      aiSummary: json['aiSummary'] as String?,
      attachments: List<String>.from(json['attachments'] as List? ?? []),
      nfcTagId: json['nfcTagId'] as String?,
      isFavorite: json['isFavorite'] as bool? ?? false,
      color: json['color'] as String?,
      priority: json['priority'] as int? ?? 0,
      reminderDate: json['reminderDate'] != null 
          ? DateTime.parse(json['reminderDate'] as String)
          : null,
      isArchived: json['isArchived'] as bool? ?? false,
    );
  }

  @override
  String toString() {
    return 'NoteModel(id: $id, title: $title, mode: $mode, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NoteModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
