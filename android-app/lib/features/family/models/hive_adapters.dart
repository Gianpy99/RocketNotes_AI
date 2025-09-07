/// Hive Adapters for Family Data Models
///
/// This file contains Hive type adapters for all family-related models:
/// - Family adapter for storing family information locally
/// - FamilyMember adapter for storing member data locally
/// - FamilySettings adapter for storing family preferences
/// - MemberPermissions adapter for storing permission flags
/// - FamilyRole adapter for storing role enums
///
/// These adapters enable offline storage and caching of family data.

import 'package:hive/hive.dart';
import '../../../models/family.dart';
import '../../../models/family_member.dart';

/// Hive adapter for Family model
class FamilyAdapter extends TypeAdapter<Family> {
  @override
  final int typeId = 100; // Unique type ID for Family

  @override
  Family read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };

    return Family(
      id: fields[0] as String,
      name: fields[1] as String,
      adminUserId: fields[2] as String,
      createdAt: fields[3] as DateTime,
      memberIds: (fields[4] as List).cast<String>(),
      settings: fields[5] as FamilySettings,
      updatedAt: fields[6] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, Family obj) {
    writer
      ..writeByte(7) // Number of fields
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.adminUserId)
      ..writeByte(3)
      ..write(obj.createdAt)
      ..writeByte(4)
      ..write(obj.memberIds)
      ..writeByte(5)
      ..write(obj.settings)
      ..writeByte(6)
      ..write(obj.updatedAt);
  }
}

/// Hive adapter for FamilySettings model
class FamilySettingsAdapter extends TypeAdapter<FamilySettings> {
  @override
  final int typeId = 101; // Unique type ID for FamilySettings

  @override
  FamilySettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };

    return FamilySettings(
      allowPublicSharing: fields[0] as bool,
      requireApprovalForSharing: fields[1] as bool,
      maxMembers: fields[2] as int,
      defaultNoteExpiration: fields[3] as Duration,
      enableRealTimeSync: fields[4] as bool,
      notifications: fields[5] as NotificationPreferences,
    );
  }

  @override
  void write(BinaryWriter writer, FamilySettings obj) {
    writer
      ..writeByte(6) // Number of fields
      ..writeByte(0)
      ..write(obj.allowPublicSharing)
      ..writeByte(1)
      ..write(obj.requireApprovalForSharing)
      ..writeByte(2)
      ..write(obj.maxMembers)
      ..writeByte(3)
      ..write(obj.defaultNoteExpiration)
      ..writeByte(4)
      ..write(obj.enableRealTimeSync)
      ..writeByte(5)
      ..write(obj.notifications);
  }
}

/// Hive adapter for NotificationPreferences model
class NotificationPreferencesAdapter extends TypeAdapter<NotificationPreferences> {
  @override
  final int typeId = 102; // Unique type ID for NotificationPreferences

  @override
  NotificationPreferences read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };

    return NotificationPreferences(
      emailInvitations: fields[0] as bool,
      pushNotifications: fields[1] as bool,
      activityDigest: fields[2] as ActivityDigestFrequency,
    );
  }

  @override
  void write(BinaryWriter writer, NotificationPreferences obj) {
    writer
      ..writeByte(3) // Number of fields
      ..writeByte(0)
      ..write(obj.emailInvitations)
      ..writeByte(1)
      ..write(obj.pushNotifications)
      ..writeByte(2)
      ..write(obj.activityDigest);
  }
}

/// Hive adapter for FamilyMember model
class FamilyMemberAdapter extends TypeAdapter<FamilyMember> {
  @override
  final int typeId = 103; // Unique type ID for FamilyMember

  @override
  FamilyMember read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };

    return FamilyMember(
      userId: fields[0] as String,
      familyId: fields[1] as String,
      role: fields[2] as FamilyRole,
      permissions: fields[3] as MemberPermissions,
      joinedAt: fields[4] as DateTime,
      lastActiveAt: fields[5] as DateTime?,
      isActive: fields[6] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, FamilyMember obj) {
    writer
      ..writeByte(7) // Number of fields
      ..writeByte(0)
      ..write(obj.userId)
      ..writeByte(1)
      ..write(obj.familyId)
      ..writeByte(2)
      ..write(obj.role)
      ..writeByte(3)
      ..write(obj.permissions)
      ..writeByte(4)
      ..write(obj.joinedAt)
      ..writeByte(5)
      ..write(obj.lastActiveAt)
      ..writeByte(6)
      ..write(obj.isActive);
  }
}

/// Hive adapter for MemberPermissions model
class MemberPermissionsAdapter extends TypeAdapter<MemberPermissions> {
  @override
  final int typeId = 104; // Unique type ID for MemberPermissions

  @override
  MemberPermissions read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };

    return MemberPermissions(
      canInviteMembers: fields[0] as bool,
      canRemoveMembers: fields[1] as bool,
      canShareNotes: fields[2] as bool,
      canEditSharedNotes: fields[3] as bool,
      canDeleteSharedNotes: fields[4] as bool,
      canManagePermissions: fields[5] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, MemberPermissions obj) {
    writer
      ..writeByte(6) // Number of fields
      ..writeByte(0)
      ..write(obj.canInviteMembers)
      ..writeByte(1)
      ..write(obj.canRemoveMembers)
      ..writeByte(2)
      ..write(obj.canShareNotes)
      ..writeByte(3)
      ..write(obj.canEditSharedNotes)
      ..writeByte(4)
      ..write(obj.canDeleteSharedNotes)
      ..writeByte(5)
      ..write(obj.canManagePermissions);
  }
}

/// Hive adapter for FamilyRole enum
class FamilyRoleAdapter extends TypeAdapter<FamilyRole> {
  @override
  final int typeId = 105; // Unique type ID for FamilyRole

  @override
  FamilyRole read(BinaryReader reader) {
    final index = reader.readByte();
    return FamilyRole.values[index];
  }

  @override
  void write(BinaryWriter writer, FamilyRole obj) {
    writer.writeByte(obj.index);
  }
}

/// Hive adapter for ActivityDigestFrequency enum
class ActivityDigestFrequencyAdapter extends TypeAdapter<ActivityDigestFrequency> {
  @override
  final int typeId = 106; // Unique type ID for ActivityDigestFrequency

  @override
  ActivityDigestFrequency read(BinaryReader reader) {
    final index = reader.readByte();
    return ActivityDigestFrequency.values[index];
  }

  @override
  void write(BinaryWriter writer, ActivityDigestFrequency obj) {
    writer.writeByte(obj.index);
  }
}

/// Utility class for registering all family-related Hive adapters
class FamilyHiveAdapters {
  static void registerAll() {
    Hive
      ..registerAdapter(FamilyAdapter())
      ..registerAdapter(FamilySettingsAdapter())
      ..registerAdapter(NotificationPreferencesAdapter())
      ..registerAdapter(FamilyMemberAdapter())
      ..registerAdapter(MemberPermissionsAdapter())
      ..registerAdapter(FamilyRoleAdapter())
      ..registerAdapter(ActivityDigestFrequencyAdapter());
  }

  /// Initialize Hive boxes for family data
  static Future<void> initializeBoxes() async {
    await Hive.openBox<Family>('families');
    await Hive.openBox<FamilyMember>('family_members');
    await Hive.openBox<Map>('family_cache'); // For temporary data
  }
}

/// Extension methods for easy Hive box access
extension FamilyHiveBoxes on HiveInterface {
  Box<Family> get families => box<Family>('families');
  Box<FamilyMember> get familyMembers => box<FamilyMember>('family_members');
  Box<Map> get familyCache => box<Map>('family_cache');
}
