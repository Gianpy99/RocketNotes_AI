// lib/data/models/note_model.dart
import 'package:hive/hive.dart';

part 'note_model.g.dart';

@HiveType(typeId: 0)
class NoteModel extends HiveObject {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  String content;
  
  @HiveField(2)
  final String mode;
  
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
  });

  NoteModel copyWith({
    String? content,
    String? title,
    DateTime? updatedAt,
    List<String>? tags,
    String? aiSummary,
    List<String>? attachments,
  }) {
    return NoteModel(
      id: id,
      content: content ?? this.content,
      mode: mode,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      title: title ?? this.title,
      tags: tags ?? this.tags,
      aiSummary: aiSummary ?? this.aiSummary,
      attachments: attachments ?? this.attachments,
      nfcTagId: nfcTagId,
    );
  }
}
