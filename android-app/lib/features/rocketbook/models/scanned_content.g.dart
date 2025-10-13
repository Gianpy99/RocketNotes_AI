// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scanned_content.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ScannedContentAdapter extends TypeAdapter<ScannedContent> {
  @override
  final int typeId = 10;

  @override
  ScannedContent read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ScannedContent(
      id: fields[0] as String,
      imagePath: fields[1] as String,
      rawText: fields[2] as String,
      tables: (fields[3] as List).cast<TableData>(),
      diagrams: (fields[4] as List).cast<DiagramData>(),
      ocrMetadata: fields[5] as OCRMetadata,
      aiAnalysis: fields[6] as AIAnalysis?,
      scannedAt: fields[7] as DateTime,
      status: fields[8] as ProcessingStatus,
    );
  }

  @override
  void write(BinaryWriter writer, ScannedContent obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.imagePath)
      ..writeByte(2)
      ..write(obj.rawText)
      ..writeByte(3)
      ..write(obj.tables)
      ..writeByte(4)
      ..write(obj.diagrams)
      ..writeByte(5)
      ..write(obj.ocrMetadata)
      ..writeByte(6)
      ..write(obj.aiAnalysis)
      ..writeByte(7)
      ..write(obj.scannedAt)
      ..writeByte(8)
      ..write(obj.status);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScannedContentAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class TableDataAdapter extends TypeAdapter<TableData> {
  @override
  final int typeId = 11;

  @override
  TableData read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TableData(
      rows: (fields[0] as List)
          .map((dynamic e) => (e as List).cast<String>())
          .toList(),
      title: fields[1] as String?,
      boundingBox: fields[2] as BoundingBox,
      confidence: fields[3] as double,
    );
  }

  @override
  void write(BinaryWriter writer, TableData obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.rows)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.boundingBox)
      ..writeByte(3)
      ..write(obj.confidence);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TableDataAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class DiagramDataAdapter extends TypeAdapter<DiagramData> {
  @override
  final int typeId = 12;

  @override
  DiagramData read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DiagramData(
      type: fields[0] as String,
      description: fields[1] as String,
      boundingBox: fields[2] as BoundingBox,
      elements: (fields[3] as Map).cast<String, dynamic>(),
      confidence: fields[4] as double,
    );
  }

  @override
  void write(BinaryWriter writer, DiagramData obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.type)
      ..writeByte(1)
      ..write(obj.description)
      ..writeByte(2)
      ..write(obj.boundingBox)
      ..writeByte(3)
      ..write(obj.elements)
      ..writeByte(4)
      ..write(obj.confidence);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DiagramDataAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class OCRMetadataAdapter extends TypeAdapter<OCRMetadata> {
  @override
  final int typeId = 13;

  @override
  OCRMetadata read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return OCRMetadata(
      engine: fields[0] as String,
      overallConfidence: fields[1] as double,
      detectedLanguages: (fields[2] as List).cast<String>(),
      processingTime: fields[3] as Duration,
      additionalData: (fields[4] as Map).cast<String, dynamic>(),
    );
  }

  @override
  void write(BinaryWriter writer, OCRMetadata obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.engine)
      ..writeByte(1)
      ..write(obj.overallConfidence)
      ..writeByte(2)
      ..write(obj.detectedLanguages)
      ..writeByte(3)
      ..write(obj.processingTime)
      ..writeByte(4)
      ..write(obj.additionalData);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OCRMetadataAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class AIAnalysisAdapter extends TypeAdapter<AIAnalysis> {
  @override
  final int typeId = 14;

  @override
  AIAnalysis read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AIAnalysis(
      summary: fields[0] as String,
      keyTopics: (fields[1] as List).cast<String>(),
      suggestedTags: (fields[2] as List).cast<String>(),
      suggestedTitle: fields[3] as String,
      contentType: fields[4] as ContentType,
      sentiment: fields[5] as double,
      actionItems: (fields[6] as List).cast<ActionItem>(),
      insights: (fields[7] as Map).cast<String, dynamic>(),
    );
  }

  @override
  void write(BinaryWriter writer, AIAnalysis obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.summary)
      ..writeByte(1)
      ..write(obj.keyTopics)
      ..writeByte(2)
      ..write(obj.suggestedTags)
      ..writeByte(3)
      ..write(obj.suggestedTitle)
      ..writeByte(4)
      ..write(obj.contentType)
      ..writeByte(5)
      ..write(obj.sentiment)
      ..writeByte(6)
      ..write(obj.actionItems)
      ..writeByte(7)
      ..write(obj.insights);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AIAnalysisAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ActionItemAdapter extends TypeAdapter<ActionItem> {
  @override
  final int typeId = 15;

  @override
  ActionItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ActionItem(
      text: fields[0] as String,
      dueDate: fields[1] as DateTime?,
      priority: fields[2] as Priority,
      isCompleted: fields[3] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, ActionItem obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.text)
      ..writeByte(1)
      ..write(obj.dueDate)
      ..writeByte(2)
      ..write(obj.priority)
      ..writeByte(3)
      ..write(obj.isCompleted);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ActionItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class BoundingBoxAdapter extends TypeAdapter<BoundingBox> {
  @override
  final int typeId = 16;

  @override
  BoundingBox read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BoundingBox(
      left: fields[0] as double,
      top: fields[1] as double,
      width: fields[2] as double,
      height: fields[3] as double,
    );
  }

  @override
  void write(BinaryWriter writer, BoundingBox obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.left)
      ..writeByte(1)
      ..write(obj.top)
      ..writeByte(2)
      ..write(obj.width)
      ..writeByte(3)
      ..write(obj.height);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BoundingBoxAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ProcessingStatusAdapter extends TypeAdapter<ProcessingStatus> {
  @override
  final int typeId = 17;

  @override
  ProcessingStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ProcessingStatus.pending;
      case 1:
        return ProcessingStatus.processing;
      case 2:
        return ProcessingStatus.completed;
      case 3:
        return ProcessingStatus.failed;
      case 4:
        return ProcessingStatus.cancelled;
      default:
        return ProcessingStatus.pending;
    }
  }

  @override
  void write(BinaryWriter writer, ProcessingStatus obj) {
    switch (obj) {
      case ProcessingStatus.pending:
        writer.writeByte(0);
        break;
      case ProcessingStatus.processing:
        writer.writeByte(1);
        break;
      case ProcessingStatus.completed:
        writer.writeByte(2);
        break;
      case ProcessingStatus.failed:
        writer.writeByte(3);
        break;
      case ProcessingStatus.cancelled:
        writer.writeByte(4);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProcessingStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ContentTypeAdapter extends TypeAdapter<ContentType> {
  @override
  final int typeId = 18;

  @override
  ContentType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ContentType.notes;
      case 1:
        return ContentType.meeting;
      case 2:
        return ContentType.todo;
      case 3:
        return ContentType.brainstorm;
      case 4:
        return ContentType.technical;
      case 5:
        return ContentType.personal;
      case 6:
        return ContentType.mixed;
      default:
        return ContentType.notes;
    }
  }

  @override
  void write(BinaryWriter writer, ContentType obj) {
    switch (obj) {
      case ContentType.notes:
        writer.writeByte(0);
        break;
      case ContentType.meeting:
        writer.writeByte(1);
        break;
      case ContentType.todo:
        writer.writeByte(2);
        break;
      case ContentType.brainstorm:
        writer.writeByte(3);
        break;
      case ContentType.technical:
        writer.writeByte(4);
        break;
      case ContentType.personal:
        writer.writeByte(5);
        break;
      case ContentType.mixed:
        writer.writeByte(6);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ContentTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class PriorityAdapter extends TypeAdapter<Priority> {
  @override
  final int typeId = 21;

  @override
  Priority read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return Priority.low;
      case 1:
        return Priority.medium;
      case 2:
        return Priority.high;
      case 3:
        return Priority.urgent;
      default:
        return Priority.low;
    }
  }

  @override
  void write(BinaryWriter writer, Priority obj) {
    switch (obj) {
      case Priority.low:
        writer.writeByte(0);
        break;
      case Priority.medium:
        writer.writeByte(1);
        break;
      case Priority.high:
        writer.writeByte(2);
        break;
      case Priority.urgent:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PriorityAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
