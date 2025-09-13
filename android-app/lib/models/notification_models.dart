
// ... (dopo i campi della classe NotificationHistory)


import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
part 'notification_models.g.dart';
/// Types of notifications
enum NotificationType {
  @JsonValue('family_invitation')
  familyInvitation,
  @JsonValue('shared_note')
  sharedNote,
  @JsonValue('comment')
  comment,
  @JsonValue('family_activity')
  familyActivity,
  @JsonValue('reminder')
  reminder,
  @JsonValue('system')
  system,
}

/// Status of a notification
enum NotificationStatus {
  @JsonValue('unread')
  unread,
  @JsonValue('read')
  read,
  @JsonValue('archived')
  archived,
  @JsonValue('deleted')
  deleted,
}

/// Priority levels for notifications
enum NotificationPriority {
  @JsonValue('low')
  low,
  @JsonValue('normal')
  normal,
  @JsonValue('high')
  high,
  @JsonValue('urgent')
  urgent,
}

/// Represents a notification in the system
@JsonSerializable()
class NotificationHistory extends Equatable {


  /// Unique identifier for the notification
  final String id;

  /// User ID this notification belongs to
  final String userId;

  /// Type of notification
  final NotificationType type;

  /// Notification title
  final String title;

  /// Notification body/message
  final String body;

  /// Additional data payload
  final Map<String, dynamic>? data;


  /// Notification status
  final NotificationStatus status;

  /// Priority level
  final NotificationPriority priority;

  /// When the notification was created
  @JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
  final DateTime createdAt;

  /// When the notification is scheduled for (if scheduled)
  @JsonKey(fromJson: _nullableDateTimeFromJson, toJson: _nullableDateTimeToJson)
  final DateTime? scheduledFor;

  /// When the notification was read (if read)
  @JsonKey(fromJson: _nullableDateTimeFromJson, toJson: _nullableDateTimeToJson)
  final DateTime? readAt;

  /// Group ID for grouping notifications
  final String? groupId;

  /// Deep link for navigation
  final String? deepLink;

  /// Getter per compatibilità UI: message (alias di body)
  String get message => body;

  /// Getter per compatibilità UI: timestamp (alias di createdAt)
  DateTime get timestamp => createdAt;

  /// Getter per compatibilità UI: actionData (estratto da data)
  Map<String, dynamic>? get actionData => data;

  const NotificationHistory({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    this.data,
    this.status = NotificationStatus.unread,
    this.priority = NotificationPriority.normal,
    required this.createdAt,
    this.scheduledFor,
    this.readAt,
    this.groupId,
    this.deepLink,
  });

  /// Creates a NotificationHistory instance from JSON
  factory NotificationHistory.fromJson(Map<String, dynamic> json) =>
      _$NotificationHistoryFromJson(json);

  /// Converts NotificationHistory instance to JSON
  Map<String, dynamic> toJson() => _$NotificationHistoryToJson(this);

  /// Creates a copy of NotificationHistory with modified fields
  NotificationHistory copyWith({
    String? id,
    String? userId,
    NotificationType? type,
    String? title,
    String? body,
    Map<String, dynamic>? data,
    NotificationStatus? status,
    NotificationPriority? priority,
    DateTime? createdAt,
    DateTime? scheduledFor,
    DateTime? readAt,
    String? groupId,
    String? deepLink,
    bool? isRead,
  }) {
    final NotificationStatus? effectiveStatus = isRead == null
        ? status
        : (isRead ? NotificationStatus.read : NotificationStatus.unread);
    return NotificationHistory(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      data: data ?? this.data,
      status: effectiveStatus ?? this.status,
      priority: priority ?? this.priority,
      createdAt: createdAt ?? this.createdAt,
      scheduledFor: scheduledFor ?? this.scheduledFor,
      readAt: readAt ?? this.readAt,
      groupId: groupId ?? this.groupId,
      deepLink: deepLink ?? this.deepLink,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        type,
        title,
        body,
        data,
        status,
        priority,
        createdAt,
        scheduledFor,
        readAt,
        groupId,
        deepLink,
      ];

  @override
  String toString() {
    return 'NotificationHistory(id: $id, userId: $userId, type: $type, '
           'title: $title, status: $status, priority: $priority)';
  }

  /// Helper methods for DateTime serialization
  static DateTime _dateTimeFromJson(String date) => DateTime.parse(date);
  static String _dateTimeToJson(DateTime date) => date.toIso8601String();

  static DateTime? _nullableDateTimeFromJson(String? date) =>
      date != null ? DateTime.parse(date) : null;
  static String? _nullableDateTimeToJson(DateTime? date) =>
      date?.toIso8601String();

  /// Convenience getters
  bool get isRead => status == NotificationStatus.read;
  bool get isUnread => status == NotificationStatus.unread;
  bool get isScheduled => scheduledFor != null && DateTime.now().isBefore(scheduledFor!);
  bool get isHighPriority => priority == NotificationPriority.high;

  /// Mark notification as read
  NotificationHistory markAsRead() {
    return copyWith(
      status: NotificationStatus.read,
      readAt: DateTime.now(),
    );
  }
}

/// Notification preferences for a user
@JsonSerializable()
class NotificationPreferences extends Equatable {
  /// User ID these preferences belong to
  final String userId;

  /// Whether to receive family invitation notifications
  final bool familyInvitations;

  /// Whether to receive shared note notifications
  final bool sharedNotes;

  /// Whether to receive comment notifications
  final bool comments;

  /// Whether to receive family activity notifications
  final bool familyActivity;

  /// Quiet hours configuration
  final QuietHours? quietHours;

  /// Priority level preferences
  final PriorityPreferences priority;

  /// Delivery method preferences
  final DeliveryPreferences delivery;

  const NotificationPreferences({
    required this.userId,
    this.familyInvitations = true,
    this.sharedNotes = true,
    this.comments = true,
    this.familyActivity = true,
    this.quietHours,
    required this.priority,
    required this.delivery,
  });

  /// Creates a NotificationPreferences instance from JSON
  factory NotificationPreferences.fromJson(Map<String, dynamic> json) =>
      _$NotificationPreferencesFromJson(json);

  /// Converts NotificationPreferences instance to JSON
  Map<String, dynamic> toJson() => _$NotificationPreferencesToJson(this);

  /// Creates a copy of NotificationPreferences with modified fields
  NotificationPreferences copyWith({
    String? userId,
    bool? familyInvitations,
    bool? sharedNotes,
    bool? comments,
    bool? familyActivity,
    QuietHours? quietHours,
    PriorityPreferences? priority,
    DeliveryPreferences? delivery,
  }) {
    return NotificationPreferences(
      userId: userId ?? this.userId,
      familyInvitations: familyInvitations ?? this.familyInvitations,
      sharedNotes: sharedNotes ?? this.sharedNotes,
      comments: comments ?? this.comments,
      familyActivity: familyActivity ?? this.familyActivity,
      quietHours: quietHours ?? this.quietHours,
      priority: priority ?? this.priority,
      delivery: delivery ?? this.delivery,
    );
  }

  @override
  List<Object?> get props => [
        userId,
        familyInvitations,
        sharedNotes,
        comments,
        familyActivity,
        quietHours,
        priority,
        delivery,
      ];
}

/// Quiet hours configuration
@JsonSerializable()
class QuietHours extends Equatable {
  /// Whether quiet hours are enabled
  final bool enabled;

  /// Start time (24-hour format, e.g., "22:00")
  final String start;

  /// End time (24-hour format, e.g., "07:00")
  final String end;

  /// Days of the week when quiet hours apply (0 = Sunday, 6 = Saturday)
  final List<int> daysOfWeek;

  /// Time zone for quiet hours
  final String timeZone;

  const QuietHours({
    required this.enabled,
    required this.start,
    required this.end,
    this.daysOfWeek = const [0, 1, 2, 3, 4, 5, 6], // All days by default
    this.timeZone = 'UTC',
  });

  /// Creates a QuietHours instance from JSON
  factory QuietHours.fromJson(Map<String, dynamic> json) =>
      _$QuietHoursFromJson(json);

  /// Converts QuietHours instance to JSON
  Map<String, dynamic> toJson() => _$QuietHoursToJson(this);

  @override
  List<Object?> get props => [enabled, start, end, daysOfWeek, timeZone];

  /// Check if the current time is within quiet hours
  bool isQuietTime([DateTime? time]) {
    if (!enabled) return false;
    
    final checkTime = time ?? DateTime.now();
    final currentHour = checkTime.hour;
    final currentMinute = checkTime.minute;
    final currentTotalMinutes = currentHour * 60 + currentMinute;

    final startParts = start.split(':');
    final startTotalMinutes = int.parse(startParts[0]) * 60 + int.parse(startParts[1]);

    final endParts = end.split(':');
    final endTotalMinutes = int.parse(endParts[0]) * 60 + int.parse(endParts[1]);

    // Check if current day is included
    if (!daysOfWeek.contains(checkTime.weekday % 7)) return false;

    // Handle overnight quiet hours (e.g., 22:00 to 07:00)
    if (startTotalMinutes > endTotalMinutes) {
      return currentTotalMinutes >= startTotalMinutes || currentTotalMinutes <= endTotalMinutes;
    } else {
      return currentTotalMinutes >= startTotalMinutes && currentTotalMinutes <= endTotalMinutes;
    }
  }
}

/// Priority level preferences
@JsonSerializable()
class PriorityPreferences extends Equatable {
  /// Whether to receive high priority notifications
  final bool high;

  /// Whether to receive normal priority notifications
  final bool normal;

  /// Whether to receive low priority notifications
  final bool low;

  /// Whether to receive urgent priority notifications
  final bool urgent;

  const PriorityPreferences({
    this.high = true,
    this.normal = true,
    this.low = false,
    this.urgent = true,
  });

  /// Creates a PriorityPreferences instance from JSON
  factory PriorityPreferences.fromJson(Map<String, dynamic> json) =>
      _$PriorityPreferencesFromJson(json);

  /// Converts PriorityPreferences instance to JSON
  Map<String, dynamic> toJson() => _$PriorityPreferencesToJson(this);

  @override
  List<Object?> get props => [high, normal, low, urgent];

  /// Check if a specific priority level is enabled
  bool isPriorityEnabled(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.low:
        return low;
      case NotificationPriority.normal:
        return normal;
      case NotificationPriority.high:
        return high;
      case NotificationPriority.urgent:
        return urgent;
    }
  }
}

/// Delivery method preferences
@JsonSerializable()
class DeliveryPreferences extends Equatable {
  /// Whether to send push notifications
  final bool push;

  /// Whether to send email notifications
  final bool email;

  /// Whether to send SMS notifications
  final bool sms;

  /// Whether to show in-app notifications
  final bool inApp;

  const DeliveryPreferences({
    this.push = true,
    this.email = false,
    this.sms = false,
    this.inApp = true,
  });

  /// Creates a DeliveryPreferences instance from JSON
  factory DeliveryPreferences.fromJson(Map<String, dynamic> json) =>
      _$DeliveryPreferencesFromJson(json);

  /// Converts DeliveryPreferences instance to JSON
  Map<String, dynamic> toJson() => _$DeliveryPreferencesToJson(this);

  @override
  List<Object?> get props => [push, email, sms, inApp];
}

/// Notification group for organizing notifications
@JsonSerializable()
class NotificationGroup extends Equatable {
  /// Unique identifier for the group
  final String id;

  /// Type of notifications in this group
  final NotificationType type;

  /// Human-readable title for the group
  final String title;

  /// List of notifications in this group
  final List<NotificationHistory> notifications;

  /// When the group was last updated
  @JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
  final DateTime lastUpdated;

  /// Whether the group is expanded in UI
  final bool isExpanded;

  const NotificationGroup({
    required this.id,
    required this.type,
    required this.title,
    required this.notifications,
    required this.lastUpdated,
    this.isExpanded = false,
  });

  /// Creates a NotificationGroup instance from JSON
  factory NotificationGroup.fromJson(Map<String, dynamic> json) =>
      _$NotificationGroupFromJson(json);

  /// Converts NotificationGroup instance to JSON
  Map<String, dynamic> toJson() => _$NotificationGroupToJson(this);

  /// Creates a copy of NotificationGroup with modified fields
  NotificationGroup copyWith({
    String? id,
    NotificationType? type,
    String? title,
    List<NotificationHistory>? notifications,
    DateTime? lastUpdated,
    bool? isExpanded,
  }) {
    return NotificationGroup(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      notifications: notifications ?? this.notifications,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      isExpanded: isExpanded ?? this.isExpanded,
    );
  }

  @override
  List<Object?> get props => [id, type, title, notifications, lastUpdated, isExpanded];

  /// Helper methods for DateTime serialization
  static DateTime _dateTimeFromJson(String date) => DateTime.parse(date);
  static String _dateTimeToJson(DateTime date) => date.toIso8601String();

  /// Get count of unread notifications in this group
  int get unreadCount => notifications.where((n) => n.isUnread).length;

  /// Get total count of notifications in this group
  int get totalCount => notifications.length;

  /// Get the most recent notification in this group
  NotificationHistory? get latestNotification {
    if (notifications.isEmpty) return null;
    return notifications.reduce((a, b) => 
        a.createdAt.isAfter(b.createdAt) ? a : b);
  }
}

/// Statistics about notifications
@JsonSerializable()
class NotificationStats extends Equatable {
  /// Total number of notifications
  final int totalNotifications;

  /// Number of unread notifications
  final int unreadCount;

  /// Number of notifications from today
  final int todayCount;

  /// Number of notifications from this week
  final int weekCount;

  /// Breakdown by notification type
  final Map<String, int> typeBreakdown;

  /// Breakdown by priority level
  final Map<String, int> priorityBreakdown;

  const NotificationStats({
    required this.totalNotifications,
    required this.unreadCount,
    required this.todayCount,
    required this.weekCount,
    required this.typeBreakdown,
    required this.priorityBreakdown,
  });

  /// Creates a NotificationStats instance from JSON
  factory NotificationStats.fromJson(Map<String, dynamic> json) =>
      _$NotificationStatsFromJson(json);

  /// Converts NotificationStats instance to JSON
  Map<String, dynamic> toJson() => _$NotificationStatsToJson(this);

  /// Creates a copy of NotificationStats with modified fields
  NotificationStats copyWith({
    int? totalNotifications,
    int? unreadCount,
    int? todayCount,
    int? weekCount,
    Map<String, int>? typeBreakdown,
    Map<String, int>? priorityBreakdown,
  }) {
    return NotificationStats(
      totalNotifications: totalNotifications ?? this.totalNotifications,
      unreadCount: unreadCount ?? this.unreadCount,
      todayCount: todayCount ?? this.todayCount,
      weekCount: weekCount ?? this.weekCount,
      typeBreakdown: typeBreakdown ?? this.typeBreakdown,
      priorityBreakdown: priorityBreakdown ?? this.priorityBreakdown,
    );
  }

  @override
  List<Object?> get props => [
        totalNotifications,
        unreadCount,
        todayCount,
        weekCount,
        typeBreakdown,
        priorityBreakdown,
      ];

  /// Get read percentage
  double get readPercentage {
    if (totalNotifications == 0) return 0.0;
    return ((totalNotifications - unreadCount) / totalNotifications) * 100;
  }
}

/// Notification payload structure for navigation
@JsonSerializable()
class NotificationPayload extends Equatable {
  /// Type of notification
  final String type;

  /// Additional data for the notification
  final Map<String, dynamic> data;

  /// Deep link for navigation
  final String? deepLink;

  const NotificationPayload({
    required this.type,
    required this.data,
    this.deepLink,
  });

  /// Creates a NotificationPayload instance from JSON
  factory NotificationPayload.fromJson(Map<String, dynamic> json) =>
      _$NotificationPayloadFromJson(json);

  /// Converts NotificationPayload instance to JSON
  Map<String, dynamic> toJson() => _$NotificationPayloadToJson(this);

  @override
  List<Object?> get props => [type, data, deepLink];
}