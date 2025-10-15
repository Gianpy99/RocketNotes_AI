// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'note_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class NoteModelAdapter extends TypeAdapter<NoteModel> {
  @override
  final int typeId = 0;

  @override
  NoteModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return NoteModel(
      id: fields[0] as String,
      content: fields[1] as String,
      mode: fields[2] as String,
      createdAt: fields[3] as DateTime,
      updatedAt: fields[4] as DateTime,
      title: fields[9] as String,
      tags: (fields[5] as List).cast<String>(),
      aiSummary: fields[6] as String?,
      attachments: (fields[7] as List).cast<String>(),
      nfcTagId: fields[8] as String?,
      isFavorite: fields[10] as bool,
      color: fields[11] as String?,
      priority: fields[12] as int,
      reminderDate: fields[13] as DateTime?,
      isArchived: fields[14] as bool,
      userId: fields[15] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, NoteModel obj) {
    writer
      ..writeByte(16)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.content)
      ..writeByte(2)
      ..write(obj.mode)
      ..writeByte(3)
      ..write(obj.createdAt)
      ..writeByte(4)
      ..write(obj.updatedAt)
      ..writeByte(5)
      ..write(obj.tags)
      ..writeByte(6)
      ..write(obj.aiSummary)
      ..writeByte(7)
      ..write(obj.attachments)
      ..writeByte(8)
      ..write(obj.nfcTagId)
      ..writeByte(9)
      ..write(obj.title)
      ..writeByte(10)
      ..write(obj.isFavorite)
      ..writeByte(11)
      ..write(obj.color)
      ..writeByte(12)
      ..write(obj.priority)
      ..writeByte(13)
      ..write(obj.reminderDate)
      ..writeByte(14)
      ..write(obj.isArchived)
      ..writeByte(15)
      ..write(obj.userId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NoteModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
