// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shared_notebook_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SharedNotebookAdapter extends TypeAdapter<SharedNotebook> {
  @override
  final int typeId = 22;

  @override
  SharedNotebook read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SharedNotebook(
      id: fields[0] as String,
      name: fields[1] as String,
      description: fields[2] as String,
      category: fields[3] as String,
      iconName: fields[4] as String?,
      color: fields[5] as String?,
      memberIds: (fields[6] as List).cast<String>(),
      permissions: (fields[7] as Map?)?.map((dynamic k, dynamic v) =>
          MapEntry(k as String, (v as List).cast<String>())),
      createdAt: fields[8] as DateTime?,
      updatedAt: fields[9] as DateTime?,
      createdBy: fields[10] as String,
    );
  }

  @override
  void write(BinaryWriter writer, SharedNotebook obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.category)
      ..writeByte(4)
      ..write(obj.iconName)
      ..writeByte(5)
      ..write(obj.color)
      ..writeByte(6)
      ..write(obj.memberIds)
      ..writeByte(7)
      ..write(obj.permissions)
      ..writeByte(8)
      ..write(obj.createdAt)
      ..writeByte(9)
      ..write(obj.updatedAt)
      ..writeByte(10)
      ..write(obj.createdBy);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SharedNotebookAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
