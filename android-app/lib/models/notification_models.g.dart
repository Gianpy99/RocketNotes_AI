// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NotificationHistory _$NotificationHistoryFromJson(Map<String, dynamic> json) =>
    NotificationHistory(
      id: json['id'] as String,
      userId: json['userId'] as String,
      type: $enumDecode(_$NotificationTypeEnumMap, json['type']),
      title: json['title'] as String,
      body: json['body'] as String,
      data: json['data'] as Map<String, dynamic>?,
      status:
          $enumDecodeNullable(_$NotificationStatusEnumMap, json['status']) ??
              NotificationStatus.unread,
      priority: $enumDecodeNullable(
              _$NotificationPriorityEnumMap, json['priority']) ??
          NotificationPriority.normal,
      createdAt:
          NotificationHistory._dateTimeFromJson(json['createdAt'] as String),
      scheduledFor: NotificationHistory._nullableDateTimeFromJson(
          json['scheduledFor'] as String?),
      readAt: NotificationHistory._nullableDateTimeFromJson(
          json['readAt'] as String?),
      groupId: json['groupId'] as String?,
      deepLink: json['deepLink'] as String?,
    );

Map<String, dynamic> _$NotificationHistoryToJson(
        NotificationHistory instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'type': _$NotificationTypeEnumMap[instance.type]!,
      'title': instance.title,
      'body': instance.body,
      'data': instance.data,
      'status': _$NotificationStatusEnumMap[instance.status]!,
      'priority': _$NotificationPriorityEnumMap[instance.priority]!,
      'createdAt': NotificationHistory._dateTimeToJson(instance.createdAt),
      'scheduledFor':
          NotificationHistory._nullableDateTimeToJson(instance.scheduledFor),
      'readAt': NotificationHistory._nullableDateTimeToJson(instance.readAt),
      'groupId': instance.groupId,
      'deepLink': instance.deepLink,
    };

const _$NotificationTypeEnumMap = {
  NotificationType.familyInvitation: 'family_invitation',
  NotificationType.sharedNote: 'shared_note',
  NotificationType.comment: 'comment',
  NotificationType.familyActivity: 'family_activity',
  NotificationType.reminder: 'reminder',
  NotificationType.system: 'system',
};

const _$NotificationStatusEnumMap = {
  NotificationStatus.unread: 'unread',
  NotificationStatus.read: 'read',
  NotificationStatus.archived: 'archived',
  NotificationStatus.deleted: 'deleted',
};

const _$NotificationPriorityEnumMap = {
  NotificationPriority.low: 'low',
  NotificationPriority.normal: 'normal',
  NotificationPriority.high: 'high',
  NotificationPriority.urgent: 'urgent',
};

NotificationPreferences _$NotificationPreferencesFromJson(
        Map<String, dynamic> json) =>
    NotificationPreferences(
      userId: json['userId'] as String,
      familyInvitations: json['familyInvitations'] as bool? ?? true,
      sharedNotes: json['sharedNotes'] as bool? ?? true,
      comments: json['comments'] as bool? ?? true,
      familyActivity: json['familyActivity'] as bool? ?? true,
      quietHours: json['quietHours'] == null
          ? null
          : QuietHours.fromJson(json['quietHours'] as Map<String, dynamic>),
      priority: PriorityPreferences.fromJson(
          json['priority'] as Map<String, dynamic>),
      delivery: DeliveryPreferences.fromJson(
          json['delivery'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$NotificationPreferencesToJson(
        NotificationPreferences instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'familyInvitations': instance.familyInvitations,
      'sharedNotes': instance.sharedNotes,
      'comments': instance.comments,
      'familyActivity': instance.familyActivity,
      'quietHours': instance.quietHours,
      'priority': instance.priority,
      'delivery': instance.delivery,
    };

QuietHours _$QuietHoursFromJson(Map<String, dynamic> json) => QuietHours(
      enabled: json['enabled'] as bool,
      start: json['start'] as String,
      end: json['end'] as String,
      daysOfWeek: (json['daysOfWeek'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          const [0, 1, 2, 3, 4, 5, 6],
      timeZone: json['timeZone'] as String? ?? 'UTC',
    );

Map<String, dynamic> _$QuietHoursToJson(QuietHours instance) =>
    <String, dynamic>{
      'enabled': instance.enabled,
      'start': instance.start,
      'end': instance.end,
      'daysOfWeek': instance.daysOfWeek,
      'timeZone': instance.timeZone,
    };

PriorityPreferences _$PriorityPreferencesFromJson(Map<String, dynamic> json) =>
    PriorityPreferences(
      high: json['high'] as bool? ?? true,
      normal: json['normal'] as bool? ?? true,
      low: json['low'] as bool? ?? false,
      urgent: json['urgent'] as bool? ?? true,
    );

Map<String, dynamic> _$PriorityPreferencesToJson(
        PriorityPreferences instance) =>
    <String, dynamic>{
      'high': instance.high,
      'normal': instance.normal,
      'low': instance.low,
      'urgent': instance.urgent,
    };

DeliveryPreferences _$DeliveryPreferencesFromJson(Map<String, dynamic> json) =>
    DeliveryPreferences(
      push: json['push'] as bool? ?? true,
      email: json['email'] as bool? ?? false,
      sms: json['sms'] as bool? ?? false,
      inApp: json['inApp'] as bool? ?? true,
    );

Map<String, dynamic> _$DeliveryPreferencesToJson(
        DeliveryPreferences instance) =>
    <String, dynamic>{
      'push': instance.push,
      'email': instance.email,
      'sms': instance.sms,
      'inApp': instance.inApp,
    };

NotificationGroup _$NotificationGroupFromJson(Map<String, dynamic> json) =>
    NotificationGroup(
      id: json['id'] as String,
      type: $enumDecode(_$NotificationTypeEnumMap, json['type']),
      title: json['title'] as String,
      notifications: (json['notifications'] as List<dynamic>)
          .map((e) => NotificationHistory.fromJson(e as Map<String, dynamic>))
          .toList(),
      lastUpdated:
          NotificationGroup._dateTimeFromJson(json['lastUpdated'] as String),
      isExpanded: json['isExpanded'] as bool? ?? false,
    );

Map<String, dynamic> _$NotificationGroupToJson(NotificationGroup instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': _$NotificationTypeEnumMap[instance.type]!,
      'title': instance.title,
      'notifications': instance.notifications,
      'lastUpdated': NotificationGroup._dateTimeToJson(instance.lastUpdated),
      'isExpanded': instance.isExpanded,
    };

NotificationStats _$NotificationStatsFromJson(Map<String, dynamic> json) =>
    NotificationStats(
      totalNotifications: (json['totalNotifications'] as num).toInt(),
      unreadCount: (json['unreadCount'] as num).toInt(),
      todayCount: (json['todayCount'] as num).toInt(),
      weekCount: (json['weekCount'] as num).toInt(),
      typeBreakdown: Map<String, int>.from(json['typeBreakdown'] as Map),
      priorityBreakdown:
          Map<String, int>.from(json['priorityBreakdown'] as Map),
    );

Map<String, dynamic> _$NotificationStatsToJson(NotificationStats instance) =>
    <String, dynamic>{
      'totalNotifications': instance.totalNotifications,
      'unreadCount': instance.unreadCount,
      'todayCount': instance.todayCount,
      'weekCount': instance.weekCount,
      'typeBreakdown': instance.typeBreakdown,
      'priorityBreakdown': instance.priorityBreakdown,
    };

NotificationPayload _$NotificationPayloadFromJson(Map<String, dynamic> json) =>
    NotificationPayload(
      type: json['type'] as String,
      data: json['data'] as Map<String, dynamic>,
      deepLink: json['deepLink'] as String?,
    );

Map<String, dynamic> _$NotificationPayloadToJson(
        NotificationPayload instance) =>
    <String, dynamic>{
      'type': instance.type,
      'data': instance.data,
      'deepLink': instance.deepLink,
    };
