// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_profile.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserProfileAdapter extends TypeAdapter<UserProfile> {
  @override
  final int typeId = 12;

  @override
  UserProfile read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserProfile(
      userId: fields[0] as String,
      displayName: fields[1] as String,
      email: fields[2] as String,
      isAnonymous: fields[3] as bool,
      lastSyncTime: fields[4] as DateTime,
      syncSettings: (fields[5] as Map).cast<String, dynamic>(),
      profileImageUrl: fields[6] as String?,
      createdAt: fields[7] as DateTime,
      updatedAt: fields[8] as DateTime,
      cloudSyncEnabled: fields[9] as bool,
      cloudProvider: fields[10] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, UserProfile obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.userId)
      ..writeByte(1)
      ..write(obj.displayName)
      ..writeByte(2)
      ..write(obj.email)
      ..writeByte(3)
      ..write(obj.isAnonymous)
      ..writeByte(4)
      ..write(obj.lastSyncTime)
      ..writeByte(5)
      ..write(obj.syncSettings)
      ..writeByte(6)
      ..write(obj.profileImageUrl)
      ..writeByte(7)
      ..write(obj.createdAt)
      ..writeByte(8)
      ..write(obj.updatedAt)
      ..writeByte(9)
      ..write(obj.cloudSyncEnabled)
      ..writeByte(10)
      ..write(obj.cloudProvider);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserProfileAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
