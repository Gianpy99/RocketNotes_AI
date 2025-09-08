import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../temp_family_notification_service.dart';

// Notification Service Provider
final notificationServiceProvider = Provider<FamilyNotificationService>((ref) {
  return FamilyNotificationService();
});

// Notification Preferences Provider
final notificationPreferencesProvider = StateNotifierProvider<NotificationPreferencesNotifier, Map<String, dynamic>>((ref) {
  return NotificationPreferencesNotifier();
});

class NotificationPreferencesNotifier extends StateNotifier<Map<String, dynamic>> {
  NotificationPreferencesNotifier() : super({
    'enableInvitations': true,
    'enableActivities': true,
    'enableComments': true,
    'enableSystemNotifications': true,
    'soundEnabled': true,
    'vibrationEnabled': true,
    'defaultPriority': 'normal',
  });

  void updatePreference(String key, dynamic value) {
    state = {...state, key: value};
  }

  void updateAllPreferences(Map<String, dynamic> preferences) {
    state = {...state, ...preferences};
  }

  bool getPreference(String key, {bool defaultValue = false}) {
    return state[key] ?? defaultValue;
  }

  String getStringPreference(String key, {String defaultValue = ''}) {
    return state[key] ?? defaultValue;
  }
}

// Notification History Provider
final notificationHistoryProvider = StateNotifierProvider<NotificationHistoryNotifier, List<Map<String, dynamic>>>((ref) {
  return NotificationHistoryNotifier();
});

class NotificationHistoryNotifier extends StateNotifier<List<Map<String, dynamic>>> {
  NotificationHistoryNotifier() : super([]);

  void addNotification(Map<String, dynamic> notification) {
    state = [notification, ...state];
  }

  void markAsRead(String notificationId) {
    state = state.map((notification) {
      if (notification['id'] == notificationId) {
        return {...notification, 'isRead': true};
      }
      return notification;
    }).toList();
  }

  void removeNotification(String notificationId) {
    state = state.where((notification) => notification['id'] != notificationId).toList();
  }

  void clearAll() {
    state = [];
  }

  void clearRead() {
    state = state.where((notification) => !(notification['isRead'] ?? false)).toList();
  }

  int get unreadCount {
    return state.where((notification) => !(notification['isRead'] ?? false)).length;
  }

  List<Map<String, dynamic>> getUnread() {
    return state.where((notification) => !(notification['isRead'] ?? false)).toList();
  }

  List<Map<String, dynamic>> getByType(String type) {
    return state.where((notification) => notification['type'] == type).toList();
  }
}

// Notification Statistics Provider
final notificationStatsProvider = StateNotifierProvider<NotificationStatsNotifier, Map<String, int>>((ref) {
  return NotificationStatsNotifier();
});

class NotificationStatsNotifier extends StateNotifier<Map<String, int>> {
  NotificationStatsNotifier() : super({
    'total': 0,
    'unread': 0,
    'invitations': 0,
    'activities': 0,
    'comments': 0,
    'system': 0,
  });

  void updateStats(Map<String, int> stats) {
    state = {...state, ...stats};
  }

  void incrementStat(String key) {
    state = {...state, key: (state[key] ?? 0) + 1};
  }

  void decrementStat(String key) {
    state = {...state, key: ((state[key] ?? 0) - 1).clamp(0, double.infinity).toInt()};
  }

  void resetStats() {
    state = {
      'total': 0,
      'unread': 0,
      'invitations': 0,
      'activities': 0,
      'comments': 0,
      'system': 0,
    };
  }
}

// FCM Token Provider
final fcmTokenProvider = StateNotifierProvider<FCMTokenNotifier, String?>((ref) {
  return FCMTokenNotifier();
});

class FCMTokenNotifier extends StateNotifier<String?> {
  FCMTokenNotifier() : super(null);

  void setToken(String token) {
    state = token;
  }

  void clearToken() {
    state = null;
  }
}
