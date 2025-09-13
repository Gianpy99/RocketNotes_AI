import 'dart:developer' as developer;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_functions/cloud_functions.dart';

// FCM configuration and token management
class FCMConfig {
  static FirebaseMessaging? _messaging;
  static FlutterLocalNotificationsPlugin? _localNotifications;
  
  static FirebaseMessaging get messaging {
    _messaging ??= FirebaseMessaging.instance;
    return _messaging!;
  }
  
  static FlutterLocalNotificationsPlugin get localNotifications {
    if (_localNotifications == null) {
      _localNotifications = FlutterLocalNotificationsPlugin();
      _initializeLocalNotifications();
    }
    return _localNotifications!;
  }
  
  static Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
    );
    
    await _localNotifications!.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }
  
  static void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap
    final String? payload = response.payload;
    if (payload != null) {
      // Parse payload and navigate accordingly
      developer.log('Notification tapped with payload: $payload', name: 'FCMConfig');
    }
  }
  
  // Request notification permissions
  static Future<bool> requestPermissions() async {
    final NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
    
    return settings.authorizationStatus == AuthorizationStatus.authorized;
  }
  
  // Get FCM token
  static Future<String?> getToken() async {
    try {
      final String? token = await messaging.getToken();
      return token;
    } catch (e) {
      developer.log('Error getting FCM token: $e', name: 'FCMConfig');
      return null;
    }
  }
  
  // Update FCM token on server
  static Future<void> updateTokenOnServer(String token) async {
    try {
      final HttpsCallable callable = FirebaseFunctions.instance
          .httpsCallable('updateFCMToken');
      
      await callable.call({'token': token});
      developer.log('FCM token updated on server', name: 'FCMConfig');
    } catch (e) {
      developer.log('Error updating FCM token on server: $e', name: 'FCMConfig');
    }
  }
  
  // Configure message handlers
  static void configureMessageHandlers() {
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    
    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);
    
    // Handle message when app is opened from terminated state
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);
  }
  
  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    developer.log('Received foreground message: ${message.messageId}', name: 'FCMConfig');
    
    // Show local notification for foreground messages
    await _showLocalNotification(message);
  }
  
  static Future<void> _handleMessageOpenedApp(RemoteMessage message) async {
    developer.log('Message opened app: ${message.messageId}', name: 'FCMConfig');
    
    // Handle navigation based on message data
    _handleNotificationNavigation(message.data);
  }
  
  static Future<void> _showLocalNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'family_channel_id',
      'Family Notifications',
      channelDescription: 'Notifications for family activities',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: false,
    );
    
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    
    await localNotifications.show(
      message.hashCode,
      message.notification?.title ?? 'RocketNotes',
      message.notification?.body ?? 'You have a new notification',
      platformChannelSpecifics,
      payload: message.data.toString(),
    );
  }
  
  static void _handleNotificationNavigation(Map<String, dynamic> data) {
    final String? type = data['type'];
    
    switch (type) {
      case 'family_invitation':
        // Navigate to family invitations screen
        developer.log('Navigate to family invitations', name: 'FCMConfig');
        break;
      case 'note_shared':
        // Navigate to shared note
        final String? noteId = data['noteId'];
        developer.log('Navigate to shared note: $noteId', name: 'FCMConfig');
        break;
      case 'note_comment':
        // Navigate to note with comments
        final String? noteId = data['noteId'];
        developer.log('Navigate to note comments: $noteId', name: 'FCMConfig');
        break;
      case 'family_activity':
        // Navigate to family activity feed
        developer.log('Navigate to family activity', name: 'FCMConfig');
        break;
      default:
        developer.log('Unknown notification type: $type', name: 'FCMConfig');
    }
  }
}

// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> _handleBackgroundMessage(RemoteMessage message) async {
  developer.log('Handling background message: ${message.messageId}', name: 'FCMConfig');
  
  // Handle background message
  // Note: UI updates are not allowed in background handlers
}

// FCM Service Provider
final fcmServiceProvider = Provider<FCMService>((ref) {
  return FCMService();
});

class FCMService {
  bool _isInitialized = false;
  String? _currentToken;
  
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // Request permissions
      final bool permissionGranted = await FCMConfig.requestPermissions();
      if (!permissionGranted) {
        developer.log('FCM permissions not granted', name: 'FCMService');
        return;
      }
      
      // Configure message handlers
      FCMConfig.configureMessageHandlers();
      
      // Get and update token
      await _updateToken();
      
      // Listen for token refresh
      FirebaseMessaging.instance.onTokenRefresh.listen(_onTokenRefresh);
      
      _isInitialized = true;
      developer.log('FCM service initialized', name: 'FCMService');
      
    } catch (e) {
      developer.log('Error initializing FCM service: $e', name: 'FCMService');
    }
  }
  
  Future<void> _updateToken() async {
    try {
      final String? token = await FCMConfig.getToken();
      if (token != null && token != _currentToken) {
        await FCMConfig.updateTokenOnServer(token);
        _currentToken = token;
      }
    } catch (e) {
      developer.log('Error updating FCM token: $e', name: 'FCMService');
    }
  }
  
  Future<void> _onTokenRefresh(String token) async {
    developer.log('FCM token refreshed: $token', name: 'FCMService');
    if (token != _currentToken) {
      await FCMConfig.updateTokenOnServer(token);
      _currentToken = token;
    }
  }
  
  String? get currentToken => _currentToken;
  bool get isInitialized => _isInitialized;
  
  // Subscribe to topic (for family-wide notifications)
  Future<void> subscribeToTopic(String topic) async {
    try {
      await FirebaseMessaging.instance.subscribeToTopic(topic);
      developer.log('Subscribed to topic: $topic', name: 'FCMService');
    } catch (e) {
      developer.log('Error subscribing to topic $topic: $e', name: 'FCMService');
    }
  }
  
  // Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await FirebaseMessaging.instance.unsubscribeFromTopic(topic);
      developer.log('Unsubscribed from topic: $topic', name: 'FCMService');
    } catch (e) {
      developer.log('Error unsubscribing from topic $topic: $e', name: 'FCMService');
    }
  }
  
  // Subscribe to family notifications
  Future<void> subscribeToFamily(String familyId) async {
    await subscribeToTopic('family_$familyId');
  }
  
  // Unsubscribe from family notifications
  Future<void> unsubscribeFromFamily(String familyId) async {
    await unsubscribeFromTopic('family_$familyId');
  }
}