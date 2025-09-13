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
      print('Notification tapped with payload: $payload');
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
      print('Error getting FCM token: $e');
      return null;
    }
  }
  
  // Update FCM token on server
  static Future<void> updateTokenOnServer(String token) async {
    try {
      final HttpsCallable callable = FirebaseFunctions.instance
          .httpsCallable('updateFCMToken');
      
      await callable.call({'token': token});
      print('FCM token updated on server');
    } catch (e) {
      print('Error updating FCM token on server: $e');
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
    print('Received foreground message: ${message.messageId}');
    
    // Show local notification for foreground messages
    await _showLocalNotification(message);
  }
  
  static Future<void> _handleMessageOpenedApp(RemoteMessage message) async {
    print('Message opened app: ${message.messageId}');
    
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
        print('Navigate to family invitations');
        break;
      case 'note_shared':
        // Navigate to shared note
        final String? noteId = data['noteId'];
        print('Navigate to shared note: $noteId');
        break;
      case 'note_comment':
        // Navigate to note with comments
        final String? noteId = data['noteId'];
        print('Navigate to note comments: $noteId');
        break;
      case 'family_activity':
        // Navigate to family activity feed
        print('Navigate to family activity');
        break;
      default:
        print('Unknown notification type: $type');
    }
  }
}

// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> _handleBackgroundMessage(RemoteMessage message) async {
  print('Handling background message: ${message.messageId}');
  
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
        print('FCM permissions not granted');
        return;
      }
      
      // Configure message handlers
      FCMConfig.configureMessageHandlers();
      
      // Get and update token
      await _updateToken();
      
      // Listen for token refresh
      FirebaseMessaging.instance.onTokenRefresh.listen(_onTokenRefresh);
      
      _isInitialized = true;
      print('FCM service initialized');
      
    } catch (e) {
      print('Error initializing FCM service: $e');
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
      print('Error updating FCM token: $e');
    }
  }
  
  Future<void> _onTokenRefresh(String token) async {
    print('FCM token refreshed: $token');
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
      print('Subscribed to topic: $topic');
    } catch (e) {
      print('Error subscribing to topic $topic: $e');
    }
  }
  
  // Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await FirebaseMessaging.instance.unsubscribeFromTopic(topic);
      print('Unsubscribed from topic: $topic');
    } catch (e) {
      print('Error unsubscribing from topic $topic: $e');
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