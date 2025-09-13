// ==========================================
// lib/services/fcm_preference_manager.dart
// ==========================================
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/notification_models.dart';

// T029: FCM Preference Manager - connects notification preferences to actual FCM token management
// - Manages FCM token lifecycle based on user preferences
// - Handles device registration and token refresh
// - Connects notification preferences to actual push notification delivery
// - Provides integration between UI preferences and Firebase backend

class FCMPreferenceManager {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static final FCMPreferenceManager _instance = FCMPreferenceManager._internal();
  factory FCMPreferenceManager() => _instance;
  FCMPreferenceManager._internal();

  User? get currentUser => _auth.currentUser;
  
  // Collections
  CollectionReference get _userTokensCollection => _firestore.collection('user_tokens');
  CollectionReference get _preferencesCollection => _firestore.collection('notification_preferences');

  /// Initialize FCM with user preferences
  Future<ServiceResult<bool>> initializeWithPreferences() async {
    try {
      final user = currentUser;
      if (user == null) {
        return ServiceResult.failure(
          error: 'User must be authenticated',
          code: 'AUTH_REQUIRED',
        );
      }

      // Check if user has enabled push notifications in preferences
      final preferencesResult = await getUserPreferences();
      if (!preferencesResult.isSuccess) {
        // No preferences found, use defaults and initialize FCM
        await _initializeFCM();
        await _storeDefaultPreferences(user.uid);
        return ServiceResult.success(data: true);
      }

      final preferences = preferencesResult.data!;
      
      // Only initialize FCM if user has enabled push notifications
      if (preferences.delivery.push) {
        await _initializeFCM();
        await _registerDeviceToken();
      } else {
        // User has disabled push notifications, unregister token
        await _unregisterDeviceToken();
      }

      return ServiceResult.success(data: true);
    } catch (e) {
      return ServiceResult.failure(
        error: 'Failed to initialize FCM with preferences: ${e.toString()}',
        code: 'INIT_FAILED',
      );
    }
  }

  /// Initialize FCM messaging
  Future<void> _initializeFCM() async {
    // Request permission
    final settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus != AuthorizationStatus.authorized) {
      throw Exception('FCM permission denied');
    }

    // Setup token refresh listener
    _messaging.onTokenRefresh.listen((token) {
      _handleTokenRefresh(token);
    });

    // Setup foreground message handler
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Setup background message handler
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);
  }

  /// Register device token with user preferences
  Future<void> _registerDeviceToken() async {
    try {
      final user = currentUser;
      if (user == null) return;

      final token = await _messaging.getToken();
      if (token == null) return;

      final deviceInfo = {
        'token': token,
        'platform': 'flutter',
        'registeredAt': FieldValue.serverTimestamp(),
        'lastUpdated': FieldValue.serverTimestamp(),
        'active': true,
      };

      await _userTokensCollection.doc(user.uid).set({
        'tokens': FieldValue.arrayUnion([deviceInfo]),
        'lastTokenUpdate': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      print('FCM token registered successfully');
    } catch (e) {
      print('Failed to register FCM token: $e');
    }
  }

  /// Unregister device token
  Future<void> _unregisterDeviceToken() async {
    try {
      final user = currentUser;
      if (user == null) return;

      final token = await _messaging.getToken();
      if (token == null) return;

      // Mark token as inactive instead of removing it
      final doc = await _userTokensCollection.doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final tokens = List<Map<String, dynamic>>.from(data['tokens'] ?? []);
        
        // Update the current token to inactive
        for (int i = 0; i < tokens.length; i++) {
          if (tokens[i]['token'] == token) {
            tokens[i]['active'] = false;
            tokens[i]['lastUpdated'] = FieldValue.serverTimestamp();
            break;
          }
        }

        await _userTokensCollection.doc(user.uid).update({
          'tokens': tokens,
          'lastTokenUpdate': FieldValue.serverTimestamp(),
        });
      }

      print('FCM token unregistered successfully');
    } catch (e) {
      print('Failed to unregister FCM token: $e');
    }
  }

  /// Handle token refresh
  Future<void> _handleTokenRefresh(String newToken) async {
    try {
      final user = currentUser;
      if (user == null) return;

      // Check if push notifications are enabled in preferences
      final preferencesResult = await getUserPreferences();
      if (!preferencesResult.isSuccess || !preferencesResult.data!.delivery.push) {
        return; // Don't register token if push notifications are disabled
      }

      final deviceInfo = {
        'token': newToken,
        'platform': 'flutter',
        'registeredAt': FieldValue.serverTimestamp(),
        'lastUpdated': FieldValue.serverTimestamp(),
        'active': true,
      };

      await _userTokensCollection.doc(user.uid).update({
        'tokens': FieldValue.arrayUnion([deviceInfo]),
        'lastTokenUpdate': FieldValue.serverTimestamp(),
      });

      print('FCM token refreshed and updated');
    } catch (e) {
      print('Failed to handle token refresh: $e');
    }
  }

  /// Handle foreground messages based on user preferences
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    try {
      final user = currentUser;
      if (user == null) return;

      // Check user preferences for in-app notifications
      final preferencesResult = await getUserPreferences();
      if (!preferencesResult.isSuccess || !preferencesResult.data!.delivery.inApp) {
        return; // Don't show in-app notifications if disabled
      }

      // Check quiet hours
      if (_isQuietTime(preferencesResult.data!)) {
        return; // Don't show notifications during quiet hours
      }

      // Check notification type preferences
      final messageType = _getNotificationTypeFromMessage(message);
      if (!_isNotificationTypeEnabled(preferencesResult.data!, messageType)) {
        return; // Don't show this type of notification if disabled
      }

      // Show in-app notification
      await _showInAppNotification(message);
    } catch (e) {
      print('Failed to handle foreground message: $e');
    }
  }

  /// Handle message opened app
  Future<void> _handleMessageOpenedApp(RemoteMessage message) async {
    try {
      final data = message.data;
      print('Message opened app: ${data}');
      
      // Handle deep linking based on message data
      if (data.containsKey('deepLink')) {
        // Navigate to specific screen based on deep link
        print('Navigating to: ${data['deepLink']}');
      }
    } catch (e) {
      print('Failed to handle message opened app: $e');
    }
  }

  /// Update preferences and manage FCM accordingly
  Future<ServiceResult<bool>> updatePreferencesWithFCM({
    bool? pushNotifications,
    bool? inAppNotifications,
    bool? familyInvitations,
    bool? sharedNotes,
    bool? comments,
    bool? familyActivity,
    Map<String, dynamic>? quietHours,
    Map<String, bool>? prioritySettings,
  }) async {
    try {
      final user = currentUser;
      if (user == null) {
        return ServiceResult.failure(
          error: 'User must be authenticated',
          code: 'AUTH_REQUIRED',
        );
      }

      // Get current preferences
      final currentPrefsResult = await getUserPreferences();
      final currentPrefs = currentPrefsResult.isSuccess 
          ? currentPrefsResult.data! 
          : _getDefaultPreferences(user.uid);

      // Build updated preferences
      final updates = <String, dynamic>{};
      
      if (familyInvitations != null) updates['familyInvitations'] = familyInvitations;
      if (sharedNotes != null) updates['sharedNotes'] = sharedNotes;
      if (comments != null) updates['comments'] = comments;
      if (familyActivity != null) updates['familyActivity'] = familyActivity;
      if (quietHours != null) updates['quietHours'] = quietHours;
      if (prioritySettings != null) updates['priority'] = prioritySettings;

      // Handle delivery preferences changes
      if (pushNotifications != null || inAppNotifications != null) {
        final currentDelivery = currentPrefs.delivery;
        updates['delivery'] = {
          'push': pushNotifications ?? currentDelivery.push,
          'inApp': inAppNotifications ?? currentDelivery.inApp,
          'email': currentDelivery.email,
          'sms': currentDelivery.sms,
        };

        // Manage FCM token based on push notification preference
        if (pushNotifications != null) {
          if (pushNotifications) {
            await _registerDeviceToken();
          } else {
            await _unregisterDeviceToken();
          }
        }
      }

      updates['updatedAt'] = FieldValue.serverTimestamp();

      // Update in Firestore
      await _preferencesCollection.doc(user.uid).set(updates, SetOptions(merge: true));

      return ServiceResult.success(data: true);
    } catch (e) {
      return ServiceResult.failure(
        error: 'Failed to update preferences: ${e.toString()}',
        code: 'UPDATE_FAILED',
      );
    }
  }

  /// Get user notification preferences
  Future<ServiceResult<NotificationPreferences>> getUserPreferences() async {
    try {
      final user = currentUser;
      if (user == null) {
        return ServiceResult.failure(
          error: 'User must be authenticated',
          code: 'AUTH_REQUIRED',
        );
      }

      final doc = await _preferencesCollection.doc(user.uid).get();
      
      if (!doc.exists) {
        // Return default preferences
        final defaultPrefs = _getDefaultPreferences(user.uid);
        return ServiceResult.success(data: defaultPrefs);
      }

      final data = doc.data() as Map<String, dynamic>;
      data['userId'] = user.uid;
      final preferences = NotificationPreferences.fromJson(data);

      return ServiceResult.success(data: preferences);
    } catch (e) {
      return ServiceResult.failure(
        error: 'Failed to get preferences: ${e.toString()}',
        code: 'GET_PREFERENCES_FAILED',
      );
    }
  }

  /// Store default preferences for a new user
  Future<void> _storeDefaultPreferences(String userId) async {
    try {
      final defaultPrefs = _getDefaultPreferences(userId);
      await _preferencesCollection.doc(userId).set(defaultPrefs.toJson());
    } catch (e) {
      print('Failed to store default preferences: $e');
    }
  }

  /// Get default notification preferences
  NotificationPreferences _getDefaultPreferences(String userId) {
    return NotificationPreferences(
      userId: userId,
      familyInvitations: true,
      sharedNotes: true,
      comments: true,
      familyActivity: true,
      priority: const PriorityPreferences(
        high: true,
        normal: true,
        low: true,
        urgent: true,
      ),
      delivery: const DeliveryPreferences(
        push: true,
        inApp: true,
        email: false,
        sms: false,
      ),
    );
  }

  /// Check if current time is within quiet hours
  bool _isQuietTime(NotificationPreferences preferences) {
    final quietHours = preferences.quietHours;
    if (quietHours == null || !quietHours.enabled) return false;

    return quietHours.isQuietTime();
  }

  /// Get notification type from Firebase message
  NotificationType _getNotificationTypeFromMessage(RemoteMessage message) {
    final typeString = message.data['type'] ?? 'system';
    
    switch (typeString) {
      case 'family_invitation':
        return NotificationType.familyInvitation;
      case 'shared_note':
        return NotificationType.sharedNote;
      case 'comment':
        return NotificationType.comment;
      case 'family_activity':
        return NotificationType.familyActivity;
      case 'reminder':
        return NotificationType.reminder;
      default:
        return NotificationType.system;
    }
  }

  /// Check if notification type is enabled in user preferences
  bool _isNotificationTypeEnabled(NotificationPreferences preferences, NotificationType type) {
    switch (type) {
      case NotificationType.familyInvitation:
        return preferences.familyInvitations;
      case NotificationType.sharedNote:
        return preferences.sharedNotes;
      case NotificationType.comment:
        return preferences.comments;
      case NotificationType.familyActivity:
        return preferences.familyActivity;
      case NotificationType.reminder:
      case NotificationType.system:
        return true; // Always allow system notifications
    }
  }

  /// Show in-app notification
  Future<void> _showInAppNotification(RemoteMessage message) async {
    try {
      // This would typically show a local notification or in-app banner
      print('Showing in-app notification: ${message.notification?.title}');
      print('Body: ${message.notification?.body}');
      
      // In a real implementation, this would use a package like flutter_local_notifications
      // or show a custom in-app notification UI
    } catch (e) {
      print('Failed to show in-app notification: $e');
    }
  }

  /// Get current FCM token
  Future<String?> getCurrentToken() async {
    try {
      return await _messaging.getToken();
    } catch (e) {
      print('Failed to get FCM token: $e');
      return null;
    }
  }

  /// Check if notifications are enabled for the current device
  Future<bool> areNotificationsEnabled() async {
    try {
      final settings = await _messaging.getNotificationSettings();
      return settings.authorizationStatus == AuthorizationStatus.authorized;
    } catch (e) {
      print('Failed to check notification status: $e');
      return false;
    }
  }

  /// Subscribe to topic based on user preferences
  Future<void> subscribeToTopics(NotificationPreferences preferences) async {
    try {
      if (!preferences.delivery.push) return;

      // Subscribe to relevant topics based on preferences
      if (preferences.familyInvitations) {
        await _messaging.subscribeToTopic('family_invitations');
      }
      
      if (preferences.sharedNotes) {
        await _messaging.subscribeToTopic('shared_notes');
      }
      
      if (preferences.comments) {
        await _messaging.subscribeToTopic('comments');
      }
      
      if (preferences.familyActivity) {
        await _messaging.subscribeToTopic('family_activity');
      }

      print('Subscribed to notification topics based on preferences');
    } catch (e) {
      print('Failed to subscribe to topics: $e');
    }
  }

  /// Unsubscribe from topics
  Future<void> unsubscribeFromTopics(NotificationPreferences preferences) async {
    try {
      // Unsubscribe from topics that are now disabled
      if (!preferences.familyInvitations) {
        await _messaging.unsubscribeFromTopic('family_invitations');
      }
      
      if (!preferences.sharedNotes) {
        await _messaging.unsubscribeFromTopic('shared_notes');
      }
      
      if (!preferences.comments) {
        await _messaging.unsubscribeFromTopic('comments');
      }
      
      if (!preferences.familyActivity) {
        await _messaging.unsubscribeFromTopic('family_activity');
      }

      print('Unsubscribed from disabled notification topics');
    } catch (e) {
      print('Failed to unsubscribe from topics: $e');
    }
  }

  /// Clean up inactive tokens
  Future<void> cleanupInactiveTokens() async {
    try {
      final user = currentUser;
      if (user == null) return;

      final doc = await _userTokensCollection.doc(user.uid).get();
      if (!doc.exists) return;

      final data = doc.data() as Map<String, dynamic>;
      final tokens = List<Map<String, dynamic>>.from(data['tokens'] ?? []);
      
      // Remove tokens older than 30 days and inactive
      final cutoffDate = DateTime.now().subtract(const Duration(days: 30));
      final activeTokens = tokens.where((token) {
        final registeredAt = (token['registeredAt'] as Timestamp?)?.toDate();
        final isActive = token['active'] == true;
        
        return isActive && (registeredAt == null || registeredAt.isAfter(cutoffDate));
      }).toList();

      if (activeTokens.length != tokens.length) {
        await _userTokensCollection.doc(user.uid).update({
          'tokens': activeTokens,
          'lastCleanup': FieldValue.serverTimestamp(),
        });
        
        print('Cleaned up ${tokens.length - activeTokens.length} inactive tokens');
      }
    } catch (e) {
      print('Failed to cleanup inactive tokens: $e');
    }
  }
}

        /// Result wrapper for service operations
        class ServiceResult<T> {
          final bool isSuccess;
          final T? data;
          final String? error;
          final String? code;

          const ServiceResult._({
            required this.isSuccess,
            this.data,
            this.error,
            this.code,
          });

          factory ServiceResult.success({required T data}) {
            return ServiceResult._(
              isSuccess: true,
              data: data,
            );
          }

          factory ServiceResult.failure({
            required String error,
            String? code,
          }) {
            return ServiceResult._(
              isSuccess: false,
              error: error,
              code: code,
            );
          }
        }