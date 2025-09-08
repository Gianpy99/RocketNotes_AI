import 'package:json_annotation/json_annotation.dart';

part 'family_notification.g.dart';

/// Model for family notifications
@JsonSerializable()
class FamilyNotification {
  final String id;
  final String type; // 'invitation', 'activity', 'comment'
  final String title;
  final String message;
  final Map<String, dynamic> data;
  final DateTime createdAt;
  final bool isRead;
  final String? senderId;
  final String? senderName;
  final String? priority; // 'low', 'normal', 'high', 'urgent'

  FamilyNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.data,
    required this.createdAt,
    this.isRead = false,
    this.senderId,
    this.senderName,
    this.priority = 'normal',
  });

  factory FamilyNotification.fromJson(Map<String, dynamic> json) =>
      _$FamilyNotificationFromJson(json);

  Map<String, dynamic> toJson() => _$FamilyNotificationToJson(this);

  /// Create invitation notification
  factory FamilyNotification.invitation({
    required String id,
    required String inviterName,
    required String familyName,
    required String invitationId,
  }) {
    return FamilyNotification(
      id: id,
      type: 'invitation',
      title: 'Invito alla famiglia',
      message: '$inviterName ti ha invitato a unirti alla famiglia "$familyName"',
      data: {
        'invitationId': invitationId,
        'familyName': familyName,
        'inviterName': inviterName,
      },
      createdAt: DateTime.now(),
      priority: 'high',
    );
  }

  /// Create activity notification
  factory FamilyNotification.activity({
    required String id,
    required String activityType,
    required String message,
    required String senderName,
    String? targetId,
    String? priority = 'normal',
  }) {
    return FamilyNotification(
      id: id,
      type: 'activity',
      title: 'Attività famiglia',
      message: message,
      data: {
        'activityType': activityType,
        'targetId': targetId,
      },
      createdAt: DateTime.now(),
      senderName: senderName,
      priority: priority,
    );
  }

  /// Create comment notification
  factory FamilyNotification.comment({
    required String id,
    required String commenterName,
    required String noteTitle,
    required String commentPreview,
    required String noteId,
    required String commentId,
  }) {
    return FamilyNotification(
      id: id,
      type: 'comment',
      title: 'Nuovo commento',
      message: '$commenterName ha commentato "$noteTitle": $commentPreview',
      data: {
        'noteId': noteId,
        'commentId': commentId,
        'noteTitle': noteTitle,
      },
      createdAt: DateTime.now(),
      senderName: commenterName,
      priority: 'normal',
    );
  }
}

/// Notification preferences model
@JsonSerializable()
class NotificationPreferences {
  final bool enableInvitations;
  final bool enableActivities;
  final bool enableComments;
  final bool enableSystemNotifications;
  final String defaultPriority;
  final bool soundEnabled;
  final bool vibrationEnabled;
  final bool showPreview;

  NotificationPreferences({
    this.enableInvitations = true,
    this.enableActivities = true,
    this.enableComments = true,
    this.enableSystemNotifications = true,
    this.defaultPriority = 'normal',
    this.soundEnabled = true,
    this.vibrationEnabled = true,
    this.showPreview = true,
  });

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) =>
      _$NotificationPreferencesFromJson(json);

  Map<String, dynamic> toJson() => _$NotificationPreferencesToJson(this);
}
