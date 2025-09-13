// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'family_notification.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FamilyNotification _$FamilyNotificationFromJson(Map<String, dynamic> json) =>
    FamilyNotification(
      id: json['id'] as String,
      type: json['type'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      data: json['data'] as Map<String, dynamic>,
      createdAt: DateTime.parse(json['createdAt'] as String),
      isRead: json['isRead'] as bool? ?? false,
      senderId: json['senderId'] as String?,
      senderName: json['senderName'] as String?,
      priority: json['priority'] as String? ?? 'normal',
    );

Map<String, dynamic> _$FamilyNotificationToJson(FamilyNotification instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': instance.type,
      'title': instance.title,
      'message': instance.message,
      'data': instance.data,
      'createdAt': instance.createdAt.toIso8601String(),
      'isRead': instance.isRead,
      'senderId': instance.senderId,
      'senderName': instance.senderName,
      'priority': instance.priority,
    };

NotificationPreferences _$NotificationPreferencesFromJson(
        Map<String, dynamic> json) =>
    NotificationPreferences(
      enableInvitations: json['enableInvitations'] as bool? ?? true,
      enableActivities: json['enableActivities'] as bool? ?? true,
      enableComments: json['enableComments'] as bool? ?? true,
      enableSystemNotifications:
          json['enableSystemNotifications'] as bool? ?? true,
      defaultPriority: json['defaultPriority'] as String? ?? 'normal',
      soundEnabled: json['soundEnabled'] as bool? ?? true,
      vibrationEnabled: json['vibrationEnabled'] as bool? ?? true,
      showPreview: json['showPreview'] as bool? ?? true,
    );

Map<String, dynamic> _$NotificationPreferencesToJson(
        NotificationPreferences instance) =>
    <String, dynamic>{
      'enableInvitations': instance.enableInvitations,
      'enableActivities': instance.enableActivities,
      'enableComments': instance.enableComments,
      'enableSystemNotifications': instance.enableSystemNotifications,
      'defaultPriority': instance.defaultPriority,
      'soundEnabled': instance.soundEnabled,
      'vibrationEnabled': instance.vibrationEnabled,
      'showPreview': instance.showPreview,
    };
