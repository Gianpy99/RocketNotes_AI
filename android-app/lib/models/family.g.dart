// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'family.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Family _$FamilyFromJson(Map<String, dynamic> json) => Family(
      id: json['id'] as String,
      name: json['name'] as String,
      adminUserId: json['adminUserId'] as String,
      createdAt: Family._dateTimeFromJson(json['createdAt'] as String),
      memberIds:
          (json['memberIds'] as List<dynamic>).map((e) => e as String).toList(),
      settings:
          FamilySettings.fromJson(json['settings'] as Map<String, dynamic>),
      updatedAt: Family._dateTimeFromJson(json['updatedAt'] as String),
    );

Map<String, dynamic> _$FamilyToJson(Family instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'adminUserId': instance.adminUserId,
      'createdAt': Family._dateTimeToJson(instance.createdAt),
      'memberIds': instance.memberIds,
      'settings': instance.settings.toJson(),
      'updatedAt': Family._dateTimeToJson(instance.updatedAt),
    };

FamilySettings _$FamilySettingsFromJson(Map<String, dynamic> json) =>
    FamilySettings(
      allowPublicSharing: json['allowPublicSharing'] as bool,
      requireApprovalForSharing: json['requireApprovalForSharing'] as bool,
      maxMembers: (json['maxMembers'] as num).toInt(),
      defaultNoteExpiration: FamilySettings._durationFromJson(
          json['defaultNoteExpiration'] as String),
      enableRealTimeSync: json['enableRealTimeSync'] as bool,
      notifications: NotificationPreferences.fromJson(
          json['notifications'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$FamilySettingsToJson(FamilySettings instance) =>
    <String, dynamic>{
      'allowPublicSharing': instance.allowPublicSharing,
      'requireApprovalForSharing': instance.requireApprovalForSharing,
      'maxMembers': instance.maxMembers,
      'defaultNoteExpiration':
          FamilySettings._durationToJson(instance.defaultNoteExpiration),
      'enableRealTimeSync': instance.enableRealTimeSync,
      'notifications': instance.notifications.toJson(),
    };

NotificationPreferences _$NotificationPreferencesFromJson(
        Map<String, dynamic> json) =>
    NotificationPreferences(
      emailInvitations: json['emailInvitations'] as bool,
      pushNotifications: json['pushNotifications'] as bool,
      activityDigest:
          $enumDecode(_$ActivityDigestFrequencyEnumMap, json['activityDigest']),
    );

Map<String, dynamic> _$NotificationPreferencesToJson(
        NotificationPreferences instance) =>
    <String, dynamic>{
      'emailInvitations': instance.emailInvitations,
      'pushNotifications': instance.pushNotifications,
      'activityDigest':
          _$ActivityDigestFrequencyEnumMap[instance.activityDigest]!,
    };

const _$ActivityDigestFrequencyEnumMap = {
  ActivityDigestFrequency.never: 'never',
  ActivityDigestFrequency.daily: 'daily',
  ActivityDigestFrequency.weekly: 'weekly',
};
