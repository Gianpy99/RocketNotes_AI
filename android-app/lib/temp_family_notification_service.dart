import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/notification_navigation_service.dart';

/// Service for handling family notifications including push notifications,
/// local notifications, and server communication
class FamilyNotificationService {
  static const String _notificationBoxName = 'family_notifications';
  static const String _fcmTokenKey = 'fcm_token';

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  final NotificationNavigationService navigationService = NotificationNavigationService();

  bool _isInitialized = false;

  // Notification channels
  static const String _familyChannelId = 'family_channel';
  static const String _invitationChannelId = 'invitation_channel';
  static const String _activityChannelId = 'activity_channel';

  /// Initialize the notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Request permission for notifications
      await _requestPermissions();

      // Initialize local notifications
      await _initializeLocalNotifications();

      // Configure FCM
      await _configureFCM();

      // Load saved FCM token
      await _loadSavedToken();

      _isInitialized = true;
    } catch (e) {
      print('Error initializing notification service: $e');
      rethrow;
    }
  }

  /// Request notification permissions
  Future<void> _requestPermissions() async {
    // Request FCM permissions
    final NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      print('User granted provisional permission');
    } else {
      print('User declined or has not accepted permission');
    }

    // Request local notification permissions (Android)
    await _localNotifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();
  }

  /// Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channels
    await _createNotificationChannels();
  }

  /// Create notification channels for Android
  Future<void> _createNotificationChannels() async {
    const AndroidNotificationChannel familyChannel = AndroidNotificationChannel(
      _familyChannelId,
      'Family Notifications',
      description: 'Notifications for family activities',
      importance: Importance.high,
      playSound: true,
    );

    const AndroidNotificationChannel invitationChannel = AndroidNotificationChannel(
      _invitationChannelId,
      'Family Invitations',
      description: 'Notifications for family invitations',
      importance: Importance.high,
      playSound: true,
    );

    const AndroidNotificationChannel activityChannel = AndroidNotificationChannel(
      _activityChannelId,
      'Family Activities',
      description: 'Notifications for family activities and updates',
      importance: Importance.defaultImportance,
      playSound: true,
    );

    await _localNotifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(familyChannel);

    await _localNotifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(invitationChannel);

    await _localNotifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(activityChannel);
  }

  /// Configure Firebase Cloud Messaging
  Future<void> _configureFCM() async {
    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_onForegroundMessage);

    // Handle notification taps when app is terminated
    FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpenedApp);
  }

  /// Handle background messages
  static Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    print('Handling background message: ${message.messageId}');
    // Handle background message processing
  }

  /// Handle foreground messages (T086)
  void _onForegroundMessage(RemoteMessage message) {
    print('Received foreground message: ${message.notification?.title}');

    final notification = message.notification;
    if (notification != null) {
      // Check if we should show in-app notification or navigate immediately
      final messageData = message.data;
      final notificationType = messageData['type'] as String?;
      
      if (notificationType == 'emergency') {
        // Emergency notifications should navigate immediately
        _handleNotificationTap(messageData);
      } else {
        // For other notifications, show local notification and handle in-app
        _showLocalNotification(
          title: notification.title ?? 'Family Notification',
          body: notification.body ?? '',
          payload: jsonEncode(messageData),
        );
        
        // Also show in-app banner for immediate action
        handleNotificationInApp(messageData);
      }
    }
  }

  /// Handle notification taps when app is opened from terminated state
  void _onMessageOpenedApp(RemoteMessage message) {
    print('Message opened app: ${message.notification?.title}');
    _handleNotificationTap(message.data);
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    if (response.payload != null) {
      final data = jsonDecode(response.payload!);
      _handleNotificationTap(data);
    }
  }

  /// Handle notification tap based on data (T086)
  void _handleNotificationTap(Map<String, dynamic> data) {
    print('Handling notification tap with data: $data');
    
    // Validate the notification data
    if (!NotificationNavigationService.isValidDeepLink(data)) {
      print('Invalid notification data for navigation');
      return;
    }

    // Log navigation for analytics
    NotificationNavigationService.logNavigation(data['type'] ?? 'unknown', data);
    
    // Navigate to appropriate screen
    NotificationNavigationService.navigateFromNotification(data);
  }

  /// Handle notification tap with enhanced error handling
  Future<void> handleNotificationTapSafe(Map<String, dynamic> data) async {
    try {
      await Future.delayed(const Duration(milliseconds: 100)); // Small delay for app initialization
      _handleNotificationTap(data);
    } catch (e) {
      print('Error handling notification tap: $e');
      // Fallback to home screen
      NotificationNavigationService.navigateFromNotification({'type': 'home'});
    }
  }

  /// Handle notification when app is in background/foreground
  void handleNotificationInApp(Map<String, dynamic> data) {
    final type = data['type'] as String?;
    
    // Show in-app notification banner for less intrusive notifications
    if (type == 'activity' || type == 'comment') {
      _showInAppNotificationBanner(data);
    } else {
      // For important notifications (invitations, emergency), navigate immediately
      _handleNotificationTap(data);
    }
  }

  /// Show in-app notification banner
  void _showInAppNotificationBanner(Map<String, dynamic> data) {
    final context = NotificationNavigationService.context;
    if (context != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(data['message'] ?? 'Nuova notifica'),
          action: SnackBarAction(
            label: 'Apri',
            onPressed: () => _handleNotificationTap(data),
          ),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  /// Show local notification
  Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
    int id = 0,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      _familyChannelId,
      'Family Notifications',
      channelDescription: 'Notifications for family activities',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(id, title, body, details, payload: payload);
  }

  /// Load saved FCM token
  Future<void> _loadSavedToken() async {
    try {
      final box = await Hive.openBox(_notificationBoxName);
      final savedToken = box.get(_fcmTokenKey);

      if (savedToken != null) {
        print('Loaded saved FCM token');
      } else {
        await _getAndSaveToken();
      }
    } catch (e) {
      print('Error loading saved token: $e');
    }
  }

  /// Get FCM token and save it
  Future<String?> _getAndSaveToken() async {
    try {
      final token = await _firebaseMessaging.getToken();
      if (token != null) {
        await _saveToken(token);
        await _sendTokenToServer(token);
        print('FCM Token obtained and saved: $token');
        return token;
      }
    } catch (e) {
      print('Error getting FCM token: $e');
    }
    return null;
  }

  /// Save FCM token locally
  Future<void> _saveToken(String token) async {
    try {
      final box = await Hive.openBox(_notificationBoxName);
      await box.put(_fcmTokenKey, token);
    } catch (e) {
      print('Error saving token: $e');
    }
  }

  /// Send FCM token to server
  Future<void> _sendTokenToServer(String token) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('No authenticated user, skipping token send');
        return;
      }

      final callable = _functions.httpsCallable('registerDeviceToken');
      final result = await callable.call({
        'token': token,
        'userId': user.uid,
        'platform': 'mobile',
      });

      print('Token sent to server successfully: ${result.data}');
    } catch (e) {
      print('Error sending token to server: $e');
      rethrow;
    }
  }

  /// Send push notification for family invitation (T082)
  Future<void> sendInvitationNotification({
    required String recipientId,
    required String inviterName,
    required String familyName,
    String? invitationId,
  }) async {
    try {
      final callable = _functions.httpsCallable('sendFamilyInvitationNotification');
      final result = await callable.call({
        'recipientId': recipientId,
        'inviterName': inviterName,
        'familyName': familyName,
        'invitationId': invitationId,
        'type': 'invitation',
        'priority': 'high',
        'timestamp': DateTime.now().toIso8601String(),
      });

      print('Invitation notification sent successfully: ${result.data}');
    } catch (e) {
      print('Error sending invitation notification: $e');
      rethrow;
    }
  }

  /// Send push notification for family activity (T083)
  Future<void> sendActivityNotification({
    required List<String> recipientIds,
    required String activityType,
    required String message,
    String? targetId,
    String? priority = 'normal',
  }) async {
    try {
      final callable = _functions.httpsCallable('sendFamilyActivityNotification');
      final result = await callable.call({
        'recipientIds': recipientIds,
        'activityType': activityType,
        'message': message,
        'targetId': targetId,
        'priority': priority,
        'type': 'activity',
        'timestamp': DateTime.now().toIso8601String(),
      });

      print('Activity notification sent successfully: ${result.data}');
    } catch (e) {
      print('Error sending activity notification: $e');
      rethrow;
    }
  }

  /// Send push notification for new comment
  Future<void> sendCommentNotification({
    required List<String> recipientIds,
    required String commenterName,
    required String noteTitle,
    required String commentPreview,
    required String noteId,
    required String commentId,
  }) async {
    try {
      final callable = _functions.httpsCallable('sendCommentNotification');
      final result = await callable.call({
        'recipientIds': recipientIds,
        'commenterName': commenterName,
        'noteTitle': noteTitle,
        'commentPreview': commentPreview,
        'noteId': noteId,
        'commentId': commentId,
        'type': 'comment',
        'priority': 'normal',
        'timestamp': DateTime.now().toIso8601String(),
      });

      print('Comment notification sent successfully: ${result.data}');
    } catch (e) {
      print('Error sending comment notification: $e');
      rethrow;
    }
  }

  /// Send push notification for shared note update
  Future<void> sendSharedNoteNotification({
    required List<String> recipientIds,
    required String senderName,
    required String noteTitle,
    required String action, // 'shared', 'updated', 'deleted'
    required String noteId,
  }) async {
    try {
      final callable = _functions.httpsCallable('sendSharedNoteNotification');
      final result = await callable.call({
        'recipientIds': recipientIds,
        'senderName': senderName,
        'noteTitle': noteTitle,
        'action': action,
        'noteId': noteId,
        'type': 'shared_note',
        'priority': 'normal',
        'timestamp': DateTime.now().toIso8601String(),
      });

      print('Shared note notification sent successfully: ${result.data}');
    } catch (e) {
      print('Error sending shared note notification: $e');
      rethrow;
    }
  }

  /// Send batch notifications (T084)
  Future<void> sendBatchNotifications({
    required List<Map<String, dynamic>> notifications,
  }) async {
    try {
      if (notifications.isEmpty) {
        print('No notifications to send');
        return;
      }

      // Validate batch size (limit to 100 notifications per batch)
      if (notifications.length > 100) {
        throw Exception('Batch size exceeds maximum limit of 100 notifications');
      }

      final callable = _functions.httpsCallable('sendBatchNotifications');
      final result = await callable.call({
        'notifications': notifications,
        'batchId': DateTime.now().millisecondsSinceEpoch.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      });

      print('Batch notifications sent successfully: ${result.data}');
    } catch (e) {
      print('Error sending batch notifications: $e');
      rethrow;
    }
  }

  /// Send batch notifications with priority grouping (T084)
  Future<void> sendPrioritizedBatchNotifications({
    required List<Map<String, dynamic>> highPriority,
    required List<Map<String, dynamic>> normalPriority,
    required List<Map<String, dynamic>> lowPriority,
  }) async {
    try {
      final allNotifications = <Map<String, dynamic>>[];

      // Add high priority notifications first
      allNotifications.addAll(highPriority.map((n) => {
        ...n,
        'priority': 'high',
        'batchOrder': 1,
      }));

      // Add normal priority notifications
      allNotifications.addAll(normalPriority.map((n) => {
        ...n,
        'priority': 'normal',
        'batchOrder': 2,
      }));

      // Add low priority notifications
      allNotifications.addAll(lowPriority.map((n) => {
        ...n,
        'priority': 'low',
        'batchOrder': 3,
      }));

      await sendBatchNotifications(notifications: allNotifications);
    } catch (e) {
      print('Error sending prioritized batch notifications: $e');
      rethrow;
    }
  }

  /// Create batch notification for family invitations
  List<Map<String, dynamic>> createInvitationBatch({
    required List<String> recipientIds,
    required String inviterName,
    required String familyName,
    String? invitationId,
  }) {
    return recipientIds.map((recipientId) => {
      'recipientId': recipientId,
      'type': 'invitation',
      'title': 'Invito alla famiglia',
      'message': '$inviterName ti ha invitato a unirti alla famiglia "$familyName"',
      'data': {
        'invitationId': invitationId,
        'familyName': familyName,
        'inviterName': inviterName,
      },
      'priority': 'high',
      'timestamp': DateTime.now().toIso8601String(),
    }).toList();
  }

  /// Create batch notification for family activities
  List<Map<String, dynamic>> createActivityBatch({
    required List<String> recipientIds,
    required String activityType,
    required String message,
    String? targetId,
    String? priority = 'normal',
  }) {
    return recipientIds.map((recipientId) => {
      'recipientId': recipientId,
      'type': 'activity',
      'title': 'Attività famiglia',
      'message': message,
      'data': {
        'activityType': activityType,
        'targetId': targetId,
      },
      'priority': priority,
      'timestamp': DateTime.now().toIso8601String(),
    }).toList();
  }

  /// Send notification with priority level (T085)
  Future<void> sendPriorityNotification({
    required String recipientId,
    required String type,
    required String title,
    required String message,
    required String priority, // 'low', 'normal', 'high', 'urgent'
    Map<String, dynamic>? data,
    Duration? timeToLive,
  }) async {
    try {
      final callable = _functions.httpsCallable('sendPriorityNotification');
      final result = await callable.call({
        'recipientId': recipientId,
        'type': type,
        'title': title,
        'message': message,
        'priority': priority,
        'data': data ?? {},
        'timeToLive': timeToLive?.inSeconds,
        'timestamp': DateTime.now().toIso8601String(),
      });

      print('Priority notification sent successfully: ${result.data}');
    } catch (e) {
      print('Error sending priority notification: $e');
      rethrow;
    }
  }

  /// Send urgent notification (highest priority)
  Future<void> sendUrgentNotification({
    required String recipientId,
    required String title,
    required String message,
    Map<String, dynamic>? data,
  }) async {
    await sendPriorityNotification(
      recipientId: recipientId,
      type: 'urgent',
      title: title,
      message: message,
      priority: 'urgent',
      data: data,
      timeToLive: const Duration(hours: 1), // Urgent notifications expire in 1 hour
    );
  }

  /// Send high priority notification
  Future<void> sendHighPriorityNotification({
    required String recipientId,
    required String title,
    required String message,
    Map<String, dynamic>? data,
  }) async {
    await sendPriorityNotification(
      recipientId: recipientId,
      type: 'high_priority',
      title: title,
      message: message,
      priority: 'high',
      data: data,
      timeToLive: const Duration(hours: 24), // High priority expire in 24 hours
    );
  }

  /// Send normal priority notification
  Future<void> sendNormalPriorityNotification({
    required String recipientId,
    required String title,
    required String message,
    Map<String, dynamic>? data,
  }) async {
    await sendPriorityNotification(
      recipientId: recipientId,
      type: 'normal',
      title: title,
      message: message,
      priority: 'normal',
      data: data,
      timeToLive: const Duration(days: 7), // Normal notifications expire in 7 days
    );
  }

  /// Send low priority notification
  Future<void> sendLowPriorityNotification({
    required String recipientId,
    required String title,
    required String message,
    Map<String, dynamic>? data,
  }) async {
    await sendPriorityNotification(
      recipientId: recipientId,
      type: 'low_priority',
      title: title,
      message: message,
      priority: 'low',
      data: data,
      timeToLive: const Duration(days: 30), // Low priority expire in 30 days
    );
  }

  /// Configure notification priority settings
  Future<void> configurePrioritySettings({
    required String userId,
    required Map<String, String> priorityMappings, // type -> priority
    required Map<String, Duration> timeToLiveSettings, // priority -> duration
  }) async {
    try {
      final callable = _functions.httpsCallable('configureNotificationPriority');
      final result = await callable.call({
        'userId': userId,
        'priorityMappings': priorityMappings,
        'timeToLiveSettings': timeToLiveSettings.map(
          (key, value) => MapEntry(key, value.inSeconds)
        ),
        'timestamp': DateTime.now().toIso8601String(),
      });

      print('Priority settings configured successfully: ${result.data}');
    } catch (e) {
      print('Error configuring priority settings: $e');
      rethrow;
    }
  }

  /// Get notification priority statistics
  Future<Map<String, dynamic>> getPriorityStatistics({
    required String userId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final callable = _functions.httpsCallable('getNotificationPriorityStats');
      final result = await callable.call({
        'userId': userId,
        'startDate': startDate?.toIso8601String(),
        'endDate': endDate?.toIso8601String(),
        'timestamp': DateTime.now().toIso8601String(),
      });

      return Map<String, dynamic>.from(result.data ?? {});
    } catch (e) {
      print('Error getting priority statistics: $e');
      return {};
    }
  }

  /// Send emergency notification (highest priority, bypasses user preferences)
  Future<void> sendEmergencyNotification({
    required List<String> recipientIds,
    required String title,
    required String message,
    Map<String, dynamic>? data,
  }) async {
    try {
      final callable = _functions.httpsCallable('sendEmergencyNotification');
      final result = await callable.call({
        'recipientIds': recipientIds,
        'title': title,
        'message': message,
        'data': data ?? {},
        'priority': 'emergency',
        'bypassPreferences': true,
        'timestamp': DateTime.now().toIso8601String(),
      });

      print('Emergency notification sent successfully: ${result.data}');
    } catch (e) {
      print('Error sending emergency notification: $e');
      rethrow;
    }
  }

  /// Update notification preferences
  Future<void> updateNotificationPreferences({
    required bool enableInvitations,
    required bool enableActivities,
    required bool enableComments,
    required String priority,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final callable = _functions.httpsCallable('updateNotificationPreferences');
      await callable.call({
        'userId': user.uid,
        'preferences': {
          'enableInvitations': enableInvitations,
          'enableActivities': enableActivities,
          'enableComments': enableComments,
          'priority': priority,
        },
      });

      print('Notification preferences updated successfully');
    } catch (e) {
      print('Error updating notification preferences: $e');
      rethrow;
    }
  }

  /// Get notification history
  Future<List<Map<String, dynamic>>> getNotificationHistory({
    int limit = 50,
    String? startAfter,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return [];

      final callable = _functions.httpsCallable('getNotificationHistory');
      final result = await callable.call({
        'userId': user.uid,
        'limit': limit,
        'startAfter': startAfter,
      });

      return List<Map<String, dynamic>>.from(result.data ?? []);
    } catch (e) {
      print('Error getting notification history: $e');
      return [];
    }
  }

  /// Mark notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final callable = _functions.httpsCallable('markNotificationAsRead');
      await callable.call({
        'userId': user.uid,
        'notificationId': notificationId,
      });

      print('Notification marked as read');
    } catch (e) {
      print('Error marking notification as read: $e');
      rethrow;
    }
  }

  /// Get current FCM token
  Future<String?> getCurrentToken() async {
    try {
      return await _firebaseMessaging.getToken();
    } catch (e) {
      print('Error getting current token: $e');
      return null;
    }
  }

  /// Refresh FCM token
  Future<void> refreshToken() async {
    try {
      await _getAndSaveToken();
      print('FCM token refreshed');
    } catch (e) {
      print('Error refreshing token: $e');
      rethrow;
    }
  }

  /// Dispose resources
  void dispose() {
    // Clean up resources if needed
  }
}
