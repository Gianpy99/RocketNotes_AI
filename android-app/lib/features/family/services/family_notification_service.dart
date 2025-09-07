import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';

/// Push notification service for family activities
class FamilyNotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  static const String _notificationSettingsKey = 'family_notification_settings';

  /// Initialize the notification service
  Future<void> initialize() async {
    // Request permission for notifications
    await _requestPermission();

    // Initialize local notifications
    await _initializeLocalNotifications();

    // Configure Firebase messaging
    await _configureFirebaseMessaging();

    // Get FCM token for push notifications
    final token = await _firebaseMessaging.getToken();
    if (token != null) {
      // TODO: Send token to server for targeted notifications
      print('FCM Token: $token');
    }
  }

  /// Request permission for notifications
  Future<void> _requestPermission() async {
    final settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    print('User granted permission: ${settings.authorizationStatus}');
  }

  /// Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }

  /// Configure Firebase messaging handlers
  Future<void> _configureFirebaseMessaging() async {
    // Handle messages when app is in foreground
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle messages when app is opened from background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);

    // Handle messages when app is terminated
    FirebaseMessaging.onBackgroundMessage(_handleTerminatedMessage);
  }

  /// Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    print('Received foreground message: ${message.notification?.title}');

    // Show local notification
    _showLocalNotification(
      title: message.notification?.title ?? 'Family Activity',
      body: message.notification?.body ?? 'New family activity',
      payload: message.data.toString(),
    );
  }

  /// Handle background messages
  void _handleBackgroundMessage(RemoteMessage message) {
    print('App opened from background: ${message.notification?.title}');
    // Handle navigation or other actions
  }

  /// Handle terminated messages
  static Future<void> _handleTerminatedMessage(RemoteMessage message) async {
    print('App opened from terminated: ${message.notification?.title}');
    // Handle navigation or other actions
  }

  /// Show local notification
  Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'family_channel',
      'Family Activities',
      channelDescription: 'Notifications for family activities',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
      payload: payload,
    );
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    print('Notification tapped: ${response.payload}');
    // TODO: Navigate to appropriate screen based on payload
  }

  /// Send notification for new family member invitation
  Future<void> notifyInvitationSent({
    required String familyName,
    required String invitedUser,
    required String invitedBy,
  }) async {
    if (!await _isNotificationEnabled(NotificationType.invitation)) return;

    await _showLocalNotification(
      title: 'Family Invitation Sent',
      body: '$invitedUser has been invited to join $familyName',
    );

    // TODO: Send push notification to invited user via Firebase Cloud Functions
  }

  /// Send notification for invitation accepted
  Future<void> notifyInvitationAccepted({
    required String familyName,
    required String newMember,
  }) async {
    if (!await _isNotificationEnabled(NotificationType.invitation)) return;

    await _showLocalNotification(
      title: 'New Family Member',
      body: '$newMember has joined $familyName',
    );

    // TODO: Send push notification to all family members
  }

  /// Send notification for shared note activity
  Future<void> notifySharedNoteActivity({
    required String noteTitle,
    required String action, // 'shared', 'commented', 'edited'
    required String userName,
  }) async {
    if (!await _isNotificationEnabled(NotificationType.sharedNote)) return;

    final actionText = _getActionText(action);
    await _showLocalNotification(
      title: 'Shared Note Activity',
      body: '$userName $actionText "$noteTitle"',
    );
  }

  /// Send notification for permission changes
  Future<void> notifyPermissionChanged({
    required String userName,
    required String permissionType,
    required String changedBy,
  }) async {
    if (!await _isNotificationEnabled(NotificationType.permission)) return;

    await _showLocalNotification(
      title: 'Permission Changed',
      body: '$changedBy changed $userName\'s $permissionType permissions',
    );
  }

  /// Send notification for family settings changes
  Future<void> notifyFamilySettingsChanged({
    required String settingName,
    required String changedBy,
  }) async {
    if (!await _isNotificationEnabled(NotificationType.settings)) return;

    await _showLocalNotification(
      title: 'Family Settings Updated',
      body: '$changedBy updated $settingName',
    );
  }

  /// Get action text for shared note activities
  String _getActionText(String action) {
    switch (action) {
      case 'shared':
        return 'shared';
      case 'commented':
        return 'commented on';
      case 'edited':
        return 'edited';
      case 'viewed':
        return 'viewed';
      default:
        return 'interacted with';
    }
  }

  /// Check if notification type is enabled
  Future<bool> _isNotificationEnabled(NotificationType type) async {
    final prefs = await SharedPreferences.getInstance();
    final settings = prefs.getString(_notificationSettingsKey);

    if (settings == null) return true; // Default to enabled

    final settingsMap = Map<String, dynamic>.from(
      settings.split(',').fold<Map<String, bool>>({}, (map, item) {
        final parts = item.split(':');
        if (parts.length == 2) {
          map[parts[0]] = parts[1] == 'true';
        }
        return map;
      }),
    );

    return settingsMap[type.name] ?? true;
  }

  /// Update notification settings
  Future<void> updateNotificationSettings(Map<NotificationType, bool> settings) async {
    final prefs = await SharedPreferences.getInstance();
    final settingsString = settings.entries
        .map((entry) => '${entry.key.name}:${entry.value}')
        .join(',');

    await prefs.setString(_notificationSettingsKey, settingsString);
  }

  /// Get current notification settings
  Future<Map<NotificationType, bool>> getNotificationSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final settings = prefs.getString(_notificationSettingsKey);

    if (settings == null) {
      // Return default settings
      return {
        for (final type in NotificationType.values) type: true,
      };
    }

    final settingsMap = <NotificationType, bool>{};
    final entries = settings.split(',');

    for (final entry in entries) {
      final parts = entry.split(':');
      if (parts.length == 2) {
        final type = NotificationType.values.firstWhere(
          (t) => t.name == parts[0],
          orElse: () => NotificationType.invitation,
        );
        settingsMap[type] = parts[1] == 'true';
      }
    }

    // Fill in any missing types with defaults
    for (final type in NotificationType.values) {
      settingsMap[type] ??= true;
    }

    return settingsMap;
  }
}

/// Types of notifications
enum NotificationType {
  invitation,
  sharedNote,
  permission,
  settings,
}

/// Provider for family notification service
final familyNotificationServiceProvider = Provider<FamilyNotificationService>((ref) {
  return FamilyNotificationService();
});

/// Provider for notification settings
final notificationSettingsProvider = FutureProvider<Map<NotificationType, bool>>((ref) {
  final service = ref.watch(familyNotificationServiceProvider);
  return service.getNotificationSettings();
});

/// Notification settings widget
class NotificationSettingsWidget extends ConsumerStatefulWidget {
  const NotificationSettingsWidget({super.key});

  @override
  ConsumerState<NotificationSettingsWidget> createState() => _NotificationSettingsWidgetState();
}

class _NotificationSettingsWidgetState extends ConsumerState<NotificationSettingsWidget> {
  late Map<NotificationType, bool> _settings;

  @override
  void initState() {
    super.initState();
    _settings = {};
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(notificationSettingsProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Notification Settings',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Choose which family activities you want to be notified about.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            settingsAsync.when(
              data: (settings) {
                _settings = Map.from(settings);
                return Column(
                  children: NotificationType.values.map((type) {
                    return SwitchListTile(
                      title: Text(_getNotificationTypeTitle(type)),
                      subtitle: Text(_getNotificationTypeDescription(type)),
                      value: _settings[type] ?? true,
                      onChanged: (value) {
                        setState(() {
                          _settings[type] = value;
                        });
                        _saveSettings();
                      },
                    );
                  }).toList(),
                );
              },
              loading: () => const CircularProgressIndicator(),
              error: (error, stack) => Text('Error loading settings: $error'),
            ),
          ],
        ),
      ),
    );
  }

  String _getNotificationTypeTitle(NotificationType type) {
    switch (type) {
      case NotificationType.invitation:
        return 'Family Invitations';
      case NotificationType.sharedNote:
        return 'Shared Notes';
      case NotificationType.permission:
        return 'Permission Changes';
      case NotificationType.settings:
        return 'Settings Changes';
    }
  }

  String _getNotificationTypeDescription(NotificationType type) {
    switch (type) {
      case NotificationType.invitation:
        return 'When members are invited or join the family';
      case NotificationType.sharedNote:
        return 'When notes are shared, commented on, or edited';
      case NotificationType.permission:
        return 'When family permissions are modified';
      case NotificationType.settings:
        return 'When family settings are updated';
    }
  }

  Future<void> _saveSettings() async {
    final service = ref.read(familyNotificationServiceProvider);
    await service.updateNotificationSettings(_settings);
    ref.invalidate(notificationSettingsProvider);
  }
}

/// Utility function to send family activity notifications
Future<void> notifyFamilyActivity({
  required WidgetRef ref,
  required NotificationType type,
  required Map<String, dynamic> data,
}) async {
  final service = ref.read(familyNotificationServiceProvider);

  switch (type) {
    case NotificationType.invitation:
      if (data.containsKey('familyName') && data.containsKey('invitedUser') && data.containsKey('invitedBy')) {
        await service.notifyInvitationSent(
          familyName: data['familyName'],
          invitedUser: data['invitedUser'],
          invitedBy: data['invitedBy'],
        );
      }
      break;

    case NotificationType.sharedNote:
      if (data.containsKey('noteTitle') && data.containsKey('action') && data.containsKey('userName')) {
        await service.notifySharedNoteActivity(
          noteTitle: data['noteTitle'],
          action: data['action'],
          userName: data['userName'],
        );
      }
      break;

    case NotificationType.permission:
      if (data.containsKey('userName') && data.containsKey('permissionType') && data.containsKey('changedBy')) {
        await service.notifyPermissionChanged(
          userName: data['userName'],
          permissionType: data['permissionType'],
          changedBy: data['changedBy'],
        );
      }
      break;

    case NotificationType.settings:
      if (data.containsKey('settingName') && data.containsKey('changedBy')) {
        await service.notifyFamilySettingsChanged(
          settingName: data['settingName'],
          changedBy: data['changedBy'],
        );
      }
      break;
  }
}
