import 'package:hive/hive.dart';

part 'scanned_content.g.dart';

@HiveType(typeId: 2)
class ScannedContent extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String imagePath;

  @HiveField(2)
  String rawText;

  @HiveField(3)
  List<TableData> tables;

  @HiveField(4)
  List<DiagramData> diagrams;

  @HiveField(5)
  OCRMetadata ocrMetadata;

  @HiveField(6)
  AIAnalysis? aiAnalysis;

  @HiveField(7)
  DateTime scannedAt;

  @HiveField(8)
  ProcessingStatus status;

  ScannedContent({
    required this.id,
    required this.imagePath,
    required this.rawText,
    required this.tables,
    required this.diagrams,
    required this.ocrMetadata,
    this.aiAnalysis,
    required this.scannedAt,
    this.status = ProcessingStatus.pending,
  });

  factory ScannedContent.fromImage(String imagePath) {
    return ScannedContent(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      imagePath: imagePath,
      rawText: '',
      tables: [],
      diagrams: [],
      ocrMetadata: OCRMetadata.empty(),
      scannedAt: DateTime.now(),
    );
  }
}

@HiveType(typeId: 3)
class TableData extends HiveObject {
  @HiveField(0)
  List<List<String>> rows;

  @HiveField(1)
  String? title;

  @HiveField(2)
  BoundingBox boundingBox;

  @HiveField(3)
  double confidence;

  TableData({
    required this.rows,
    this.title,
    required this.boundingBox,
    required this.confidence,
  });
}

@HiveType(typeId: 4)
class DiagramData extends HiveObject {
  @HiveField(0)
  String type; // 'flowchart', 'mindmap', 'graph', 'sketch'

  @HiveField(1)
  String description;

  @HiveField(2)
  BoundingBox boundingBox;

  @HiveField(3)
  Map<String, dynamic> elements;

  @HiveField(4)
  double confidence;

  DiagramData({
    required this.type,
    required this.description,
    required this.boundingBox,
    required this.elements,
    required this.confidence,
  });
}

@HiveType(typeId: 5)
class OCRMetadata extends HiveObject {
  @HiveField(0)
  String engine; // 'ml_kit', 'tesseract', 'cloud_vision'

  @HiveField(1)
  double overallConfidence;

  @HiveField(2)
  List<String> detectedLanguages;

  @HiveField(3)
  Duration processingTime;

  @HiveField(4)
  Map<String, dynamic> additionalData;

  OCRMetadata({
    required this.engine,
    required this.overallConfidence,
    required this.detectedLanguages,
    required this.processingTime,
    required this.additionalData,
  });

  factory OCRMetadata.empty() {
    return OCRMetadata(
      engine: 'none',
      overallConfidence: 0.0,
      detectedLanguages: [],
      processingTime: Duration.zero,
      additionalData: {},
    );
  }
}

@HiveType(typeId: 6)
class AIAnalysis extends HiveObject {
  @HiveField(0)
  String summary;

  @HiveField(1)
  List<String> keyTopics;

  @HiveField(2)
  List<String> suggestedTags;

  @HiveField(3)
  String suggestedTitle;

  @HiveField(4)
  ContentType contentType;

  @HiveField(5)
  double sentiment; // -1 to 1

  @HiveField(6)
  List<ActionItem> actionItems;

  @HiveField(7)
  Map<String, dynamic> insights;

  AIAnalysis({
    required this.summary,
    required this.keyTopics,
    required this.suggestedTags,
    required this.suggestedTitle,
    required this.contentType,
    required this.sentiment,
    required this.actionItems,
    required this.insights,
  });
}

@HiveType(typeId: 7)
class ActionItem extends HiveObject {
  @HiveField(0)
  String text;

  @HiveField(1)
  DateTime? dueDate;

  @HiveField(2)
  Priority priority;

  @HiveField(3)
  bool isCompleted;

  ActionItem({
    required this.text,
    this.dueDate,
    required this.priority,
    this.isCompleted = false,
  });
}

@HiveType(typeId: 8)
class BoundingBox extends HiveObject {
  @HiveField(0)
  double left;

  @HiveField(1)
  double top;

  @HiveField(2)
  double width;

  @HiveField(3)
  double height;

  BoundingBox({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });
}

@HiveType(typeId: 9)
enum ProcessingStatus {
  @HiveField(0)
  pending,
  @HiveField(1)
  processing,
  @HiveField(2)
  completed,
  @HiveField(3)
  failed,
  @HiveField(4)
  cancelled,
}

@HiveType(typeId: 10)
enum ContentType {
  @HiveField(0)
  notes,
  @HiveField(1)
  meeting,
  @HiveField(2)
  todo,
  @HiveField(3)
  brainstorm,
  @HiveField(4)
  technical,
  @HiveField(5)
  personal,
  @HiveField(6)
  mixed,
}

@HiveType(typeId: 11)
enum Priority {
  @HiveField(0)
  low,
  @HiveField(1)
  medium,
  @HiveField(2)
  high,
  @HiveField(3)
  urgent,
}
