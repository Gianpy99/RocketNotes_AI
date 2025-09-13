import 'dart:async';
import 'dart:developer' as developer;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:pensieve/models/notification_models.dart';
import 'package:pensieve/services/family_service.dart';

/// Service for managing Firebase Cloud Messaging and in-app notifications
class NotificationService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final FirebaseMessaging _messaging;
  final FamilyService _familyService;

  NotificationService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    FirebaseMessaging? messaging,
    FamilyService? familyService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _messaging = messaging ?? FirebaseMessaging.instance,
        _familyService = familyService ?? FamilyService();

  // Collection references
  CollectionReference<Map<String, dynamic>> get _notificationsCollection =>
      _firestore.collection('notifications');

  CollectionReference<Map<String, dynamic>> get _userTokensCollection =>
      _firestore.collection('user_tokens');

  CollectionReference<Map<String, dynamic>> get _preferencesCollection =>
      _firestore.collection('notification_preferences');

  /// Gets the current authenticated user
  User? get currentUser => _auth.currentUser;

  /// Initialize notification service and request permissions
  Future<ServiceResult<bool>> initialize() async {
    try {
      // Request notification permissions
      final settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        return ServiceResult.failure(
          error: 'Notification permissions denied',
          code: 'PERMISSIONS_DENIED',
        );
      }

      // Get FCM token and store it
      final token = await _messaging.getToken();
      if (token != null) {
        await _storeDeviceToken(token);
      }

      // Listen for token refresh
      _messaging.onTokenRefresh.listen(_storeDeviceToken);

      // Setup message handlers
      _setupMessageHandlers();

      return ServiceResult.success(data: true);
    } catch (e) {
      return ServiceResult.failure(
        error: 'Failed to initialize notifications: ${e.toString()}',
        code: 'INITIALIZATION_FAILED',
      );
    }
  }

  /// Stores device FCM token for the current user
  Future<void> _storeDeviceToken(String token) async {
    try {
      final user = currentUser;
      if (user == null) return;

      await _userTokensCollection.doc(user.uid).set({
        'tokens': FieldValue.arrayUnion([
          {
            'token': token,
            'platform': defaultTargetPlatform.name,
            'updatedAt': FieldValue.serverTimestamp(),
          }
        ]),
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      developer.log('Failed to store device token: $e', name: 'NotificationService');
    }
  }

  /// Setup message handlers for foreground, background, and terminated states
  void _setupMessageHandlers() {
    // Foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Background message handler (when app is in background but not terminated)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);

    // Handle notification when app is launched from terminated state
    _messaging.getInitialMessage().then((message) {
      if (message != null) {
        _handleBackgroundMessage(message);
      }
    });
  }

  /// Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    developer.log('Received foreground message: ${message.notification?.title}', name: 'NotificationService');
    // Create in-app notification
    _createInAppNotification(message);
  }

  /// Handle background messages (when app is opened from notification)
  void _handleBackgroundMessage(RemoteMessage message) {
    developer.log('Opened app from notification: ${message.notification?.title}', name: 'NotificationService');
    // Handle navigation or actions based on message data
    _handleNotificationAction(message);
  }

  /// Creates an in-app notification for real-time display
  Future<void> _createInAppNotification(RemoteMessage message) async {
    try {
      final user = currentUser;
      if (user == null) return;

      final notification = NotificationHistory(
        id: message.messageId ?? _notificationsCollection.doc().id,
        userId: user.uid,
        type: _getNotificationTypeFromMessage(message),
        title: message.notification?.title ?? 'New Notification',
        body: message.notification?.body ?? '',
        data: message.data,
        status: NotificationStatus.unread,
        priority: _getPriorityFromMessage(message),
        createdAt: DateTime.now(),
        readAt: null,
      );

      await _notificationsCollection.doc(notification.id).set(notification.toJson());
    } catch (e) {
      developer.log('Failed to create in-app notification: $e', name: 'NotificationService');
    }
  }

  /// Handles notification action when app is opened from notification
  void _handleNotificationAction(RemoteMessage message) {
    // This would typically trigger navigation or specific actions
    // based on the notification type and data
    final data = message.data;
    developer.log('Handling notification action for type: ${data['type']}', name: 'NotificationService');
  }

  /// Sends a notification to specific users
  Future<ServiceResult<bool>> sendNotificationToUsers({
    required List<String> userIds,
    required String title,
    required String body,
    required NotificationType type,
    Map<String, dynamic>? data,
    NotificationPriority priority = NotificationPriority.normal,
    DateTime? scheduledFor,
  }) async {
    try {
      final user = currentUser;
      if (user == null) {
        return ServiceResult.failure(
          error: 'User must be authenticated',
          code: 'AUTH_REQUIRED',
        );
      }

      final batch = _firestore.batch();

      for (final userId in userIds) {
        // Check user notification preferences
        final preferencesAllowed = await _checkNotificationPreferences(userId, type);
        if (!preferencesAllowed) continue;

        // Create notification record
        final notificationId = _notificationsCollection.doc().id;
        final notification = NotificationHistory(
          id: notificationId,
          userId: userId,
          type: type,
          title: title,
          body: body,
          data: data ?? {},
          status: NotificationStatus.unread,
          priority: priority,
          createdAt: DateTime.now(),
          scheduledFor: scheduledFor,
        );

        batch.set(
          _notificationsCollection.doc(notificationId),
          notification.toJson(),
        );

        // Send push notification if not scheduled
        if (scheduledFor == null) {
          await _sendPushNotification(
            userId: userId,
            title: title,
            body: body,
            data: data ?? {},
            priority: priority,
          );
        }
      }

      await batch.commit();
      return ServiceResult.success(data: true);
    } catch (e) {
      return ServiceResult.failure(
        error: 'Failed to send notification: ${e.toString()}',
        code: 'SEND_FAILED',
      );
    }
  }

  /// Sends a notification to all family members
  Future<ServiceResult<bool>> sendNotificationToFamily({
    required String familyId,
    required String title,
    required String body,
    required NotificationType type,
    Map<String, dynamic>? data,
    NotificationPriority priority = NotificationPriority.normal,
    String? excludeUserId,
  }) async {
    try {
      // Get family members
      final membersResult = await _familyService.getFamilyMembers(familyId);
      if (!membersResult.isSuccess) {
        return ServiceResult.failure(
          error: 'Failed to get family members',
          code: 'FAMILY_ACCESS_FAILED',
        );
      }

      final members = membersResult.data!;
      final userIds = members
          .where((member) => member.userId != excludeUserId)
          .map((member) => member.userId)
          .toList();

      if (userIds.isEmpty) {
        return ServiceResult.success(data: true);
      }

      return await sendNotificationToUsers(
        userIds: userIds,
        title: title,
        body: body,
        type: type,
        data: {
          ...?data,
          'familyId': familyId,
        },
        priority: priority,
      );
    } catch (e) {
      return ServiceResult.failure(
        error: 'Failed to send family notification: ${e.toString()}',
        code: 'SEND_FAMILY_FAILED',
      );
    }
  }

  /// Sends a push notification to a specific user
  Future<void> _sendPushNotification({
    required String userId,
    required String title,
    required String body,
    required Map<String, dynamic> data,
    required NotificationPriority priority,
  }) async {
    try {
      // Get user's FCM tokens
      final tokensDoc = await _userTokensCollection.doc(userId).get();
      if (!tokensDoc.exists) return;

      final tokensData = tokensDoc.data()!;
      final tokens = tokensData['tokens'] as List?;
      if (tokens == null || tokens.isEmpty) return;

      // Extract active tokens
      final activeTokens = tokens
          .map((tokenData) => tokenData['token'] as String)
          .where((token) => token.isNotEmpty)
          .toList();

      if (activeTokens.isEmpty) return;

      // Send to each token (Firebase functions would handle this in production)
      for (final token in activeTokens) {
        await _sendToToken(
          token: token,
          title: title,
          body: body,
          data: data,
          priority: priority,
        );
      }
    } catch (e) {
      developer.log('Failed to send push notification: $e', name: 'NotificationService');
    }
  }

  /// Sends notification to a specific FCM token
  Future<void> _sendToToken({
    required String token,
    required String title,
    required String body,
    required Map<String, dynamic> data,
    required NotificationPriority priority,
  }) async {
    try {
      // In a real implementation, this would use Firebase Admin SDK
      // or call a Cloud Function to send the notification
      developer.log('Sending notification to token: $token', name: 'NotificationService');
      developer.log('Title: $title', name: 'NotificationService');
      developer.log('Body: $body', name: 'NotificationService');
      developer.log('Data: $data', name: 'NotificationService');
    } catch (e) {
      developer.log('Failed to send to token $token: $e', name: 'NotificationService');
    }
  }

  /// Gets notifications for the current user
  Future<ServiceResult<List<NotificationHistory>>> getUserNotifications({
    int limit = 50,
    DateTime? since,
    NotificationStatus? status,
  }) async {
    try {
      final user = currentUser;
      if (user == null) {
        return ServiceResult.failure(
          error: 'User must be authenticated',
          code: 'AUTH_REQUIRED',
        );
      }

      var query = _notificationsCollection
          .where('userId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (since != null) {
        query = query.where('createdAt', isGreaterThan: since.toIso8601String());
      }

      if (status != null) {
        query = query.where('status', isEqualTo: status.toString());
      }

      final snapshot = await query.get();
      final notifications = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return NotificationHistory.fromJson(data);
      }).toList();

      return ServiceResult.success(data: notifications);
    } catch (e) {
      return ServiceResult.failure(
        error: 'Failed to get notifications: ${e.toString()}',
        code: 'GET_NOTIFICATIONS_FAILED',
      );
    }
  }

  /// Marks a notification as read
  Future<ServiceResult<bool>> markAsRead(String notificationId) async {
    try {
      final user = currentUser;
      if (user == null) {
        return ServiceResult.failure(
          error: 'User must be authenticated',
          code: 'AUTH_REQUIRED',
        );
      }

      await _notificationsCollection.doc(notificationId).update({
        'status': NotificationStatus.read.toString(),
        'readAt': FieldValue.serverTimestamp(),
      });

      return ServiceResult.success(data: true);
    } catch (e) {
      return ServiceResult.failure(
        error: 'Failed to mark notification as read: ${e.toString()}',
        code: 'MARK_READ_FAILED',
      );
    }
  }

  /// Marks all notifications as read for the current user
  Future<ServiceResult<bool>> markAllAsRead() async {
    try {
      final user = currentUser;
      if (user == null) {
        return ServiceResult.failure(
          error: 'User must be authenticated',
          code: 'AUTH_REQUIRED',
        );
      }

      final batch = _firestore.batch();
      final unreadQuery = await _notificationsCollection
          .where('userId', isEqualTo: user.uid)
          .where('status', isEqualTo: NotificationStatus.unread.toString())
          .get();

      for (final doc in unreadQuery.docs) {
        batch.update(doc.reference, {
          'status': NotificationStatus.read.toString(),
          'readAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
      return ServiceResult.success(data: true);
    } catch (e) {
      return ServiceResult.failure(
        error: 'Failed to mark all notifications as read: ${e.toString()}',
        code: 'MARK_ALL_READ_FAILED',
      );
    }
  }

  /// Updates notification preferences for the current user
  Future<ServiceResult<bool>> updateNotificationPreferences({
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

      final updates = <String, dynamic>{};
      if (familyInvitations != null) updates['familyInvitations'] = familyInvitations;
      if (sharedNotes != null) updates['sharedNotes'] = sharedNotes;
      if (comments != null) updates['comments'] = comments;
      if (familyActivity != null) updates['familyActivity'] = familyActivity;
      if (quietHours != null) updates['quietHours'] = quietHours;
      if (prioritySettings != null) updates['priority'] = prioritySettings;

      updates['updatedAt'] = FieldValue.serverTimestamp();

      await _preferencesCollection.doc(user.uid).set(updates, SetOptions(merge: true));

      return ServiceResult.success(data: true);
    } catch (e) {
      return ServiceResult.failure(
        error: 'Failed to update preferences: ${e.toString()}',
        code: 'UPDATE_PREFERENCES_FAILED',
      );
    }
  }

  /// Gets notification preferences for the current user
  Future<ServiceResult<NotificationPreferences>> getNotificationPreferences() async {
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
        final defaultPrefs = NotificationPreferences(
          userId: user.uid,
          familyInvitations: true,
          sharedNotes: true,
          comments: true,
          familyActivity: true,
          priority: PriorityPreferences(
            high: true,
            normal: true,
            low: true,
            urgent: true,
          ),
          delivery: DeliveryPreferences(
            push: true,
            inApp: true,
            email: false,
            sms: false,
          ),
        );
        return ServiceResult.success(data: defaultPrefs);
      }

      final data = doc.data()!;
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

  /// Gets real-time stream of notifications for the current user
  Stream<List<NotificationHistory>> getNotificationsStream({
    int limit = 50,
  }) {
    final user = currentUser;
    if (user == null) return Stream.value([]);

    return _notificationsCollection
        .where('userId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return NotificationHistory.fromJson(data);
      }).toList();
    });
  }

  /// Gets count of unread notifications
  Future<ServiceResult<int>> getUnreadCount() async {
    try {
      final user = currentUser;
      if (user == null) {
        return ServiceResult.failure(
          error: 'User must be authenticated',
          code: 'AUTH_REQUIRED',
        );
      }

      final snapshot = await _notificationsCollection
          .where('userId', isEqualTo: user.uid)
          .where('status', isEqualTo: NotificationStatus.unread.toString())
          .get();

      return ServiceResult.success(data: snapshot.docs.length);
    } catch (e) {
      return ServiceResult.failure(
        error: 'Failed to get unread count: ${e.toString()}',
        code: 'GET_UNREAD_COUNT_FAILED',
      );
    }
  }

  // Helper methods

  /// Checks if user has enabled notifications for the given type
  Future<bool> _checkNotificationPreferences(String userId, NotificationType type) async {
    try {
      final doc = await _preferencesCollection.doc(userId).get();
      if (!doc.exists) return true; // Default to enabled

      final data = doc.data()!;
      
      switch (type) {
        case NotificationType.familyInvitation:
          return data['familyInvitations'] ?? true;
        case NotificationType.sharedNote:
          return data['sharedNotes'] ?? true;
        case NotificationType.comment:
          return data['comments'] ?? true;
        case NotificationType.familyActivity:
          return data['familyActivity'] ?? true;
        case NotificationType.reminder:
          return data['reminders'] ?? true;
        case NotificationType.system:
          return true; // Always enabled for system messages
      }
    } catch (e) {
      return true; // Default to enabled on error
    }
  }

  /// Extracts notification type from FCM message
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

  /// Extracts priority from FCM message
  NotificationPriority _getPriorityFromMessage(RemoteMessage message) {
    final priorityString = message.data['priority'] ?? 'normal';
    
    switch (priorityString) {
      case 'low':
        return NotificationPriority.low;
      case 'high':
        return NotificationPriority.high;
      case 'urgent':
        return NotificationPriority.urgent;
      default:
        return NotificationPriority.normal;
    }
  }
}

/// Base service result class for consistent error handling
class ServiceResult<T> {
  final T? data;
  final String? error;
  final String? code;
  final bool isSuccess;

  const ServiceResult._({
    this.data,
    this.error,
    this.code,
    required this.isSuccess,
  });

  factory ServiceResult.success({required T data}) {
    return ServiceResult._(data: data, isSuccess: true);
  }

  factory ServiceResult.failure({required String error, String? code}) {
    return ServiceResult._(error: error, code: code, isSuccess: false);
  }

  ServiceResult<R> asFailure<R>() {
    return ServiceResult<R>.failure(error: error!, code: code);
  }
}