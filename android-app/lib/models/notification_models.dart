/// Data models for notifications (T088-T090)

class NotificationHistory {
  final String id;
  final String type;
  final String title;
  final String message;
  final String priority;
  final DateTime timestamp;
  final bool isRead;
  final Map<String, dynamic>? actionData;
  final String? groupId;

  const NotificationHistory({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.priority,
    required this.timestamp,
    this.isRead = false,
    this.actionData,
    this.groupId,
  });

  NotificationHistory copyWith({
    String? id,
    String? type,
    String? title,
    String? message,
    String? priority,
    DateTime? timestamp,
    bool? isRead,
    Map<String, dynamic>? actionData,
    String? groupId,
  }) {
    return NotificationHistory(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      priority: priority ?? this.priority,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      actionData: actionData ?? this.actionData,
      groupId: groupId ?? this.groupId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'title': title,
      'message': message,
      'priority': priority,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
      'actionData': actionData,
      'groupId': groupId,
    };
  }

  factory NotificationHistory.fromJson(Map<String, dynamic> json) {
    return NotificationHistory(
      id: json['id'] as String,
      type: json['type'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      priority: json['priority'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      isRead: json['isRead'] as bool? ?? false,
      actionData: json['actionData'] as Map<String, dynamic>?,
      groupId: json['groupId'] as String?,
    );
  }
}

class NotificationGroup {
  final String id;
  final String type;
  final String title;
  final List<NotificationHistory> notifications;
  final DateTime lastUpdated;
  final bool isExpanded;

  const NotificationGroup({
    required this.id,
    required this.type,
    required this.title,
    required this.notifications,
    required this.lastUpdated,
    this.isExpanded = false,
  });

  NotificationGroup copyWith({
    String? id,
    String? type,
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

  int get unreadCount => notifications.where((n) => !n.isRead).length;
  int get totalCount => notifications.length;
}

class NotificationStats {
  final int totalNotifications;
  final int unreadCount;
  final int todayCount;
  final int weekCount;
  final Map<String, int> typeBreakdown;
  final Map<String, int> priorityBreakdown;

  const NotificationStats({
    required this.totalNotifications,
    required this.unreadCount,
    required this.todayCount,
    required this.weekCount,
    required this.typeBreakdown,
    required this.priorityBreakdown,
  });

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
}

/// Notification payload structure for navigation
class NotificationPayload {
  final String type;
  final Map<String, dynamic> data;
  final String? deepLink;

  const NotificationPayload({
    required this.type,
    required this.data,
    this.deepLink,
  });

  factory NotificationPayload.fromJson(Map<String, dynamic> json) {
    return NotificationPayload(
      type: json['type'] as String,
      data: json['data'] as Map<String, dynamic>? ?? {},
      deepLink: json['deepLink'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'data': data,
      'deepLink': deepLink,
    };
  }
}