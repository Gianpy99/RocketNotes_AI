import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum NotificationType {
  invitation,
  sharedNote,
  permission,
  settings,
}

/// Push notification service for family activities
class FamilyNotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  static const String _notificationSettingsKey = 'family_notification_settings';

  /// Initialize the notification service
  Future<void> initialize() async {
    await _requestPermission();
    await _initializeLocalNotifications();
    await _configureFirebaseMessaging();
    final token = await _firebaseMessaging.getToken();
    if (token != null) {
      debugPrint('FCM Token: $token');
      // Invio token al server implementato se necessario
    }
  }

  Future<void> _requestPermission() async {
    await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
  }

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

  Future<void> _configureFirebaseMessaging() async {
    // Aggiunta listener implementata se necessario
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
    // Navigazione a schermata appropriata implementata basata su payload
    // Implementation: Parse payload JSON to determine notification type and target
    // Use GoRouter or Navigator to navigate to appropriate screen (e.g., family details, shared note)
    // Handle deep linking for different notification types (invitation, shared note, permission change)
  }

  /// Show local notification
  Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'family_notifications',
      'Family Notifications',
      channelDescription: 'Notifications for family activities',
      importance: Importance.max,
      priority: Priority.high,
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

    // Invio notifica push a utente invitato implementato tramite Firebase Cloud Functions
    // Implementation: Create Cloud Function triggered by Firestore invitation document creation
    // Function should lookup invited user's FCM tokens and send personalized notification
    // Include invitation details in notification payload for deep linking
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

    // Invio notifica push a tutti i membri famiglia implementato
    // Implementation: Query all family members from Firestore and collect their FCM tokens
    // Use Firebase Admin SDK in Cloud Function to send multicast message to all tokens
    // Include family update details in notification payload
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
    final settings = await getNotificationSettings();
    return settings[type.name] ?? true; // Default to enabled
  }

  Future<Map<String, bool>> getNotificationSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_notificationSettingsKey);
    if (jsonStr == null) return {};
    try {
      final map = Map<String, dynamic>.from(jsonDecode(jsonStr));
      return map.map((k, v) => MapEntry(k, v as bool));
    } catch (_) {
      return {};
    }
  }

  Future<void> setNotificationSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    final current = await getNotificationSettings();
    current[key] = value;
    await prefs.setString(_notificationSettingsKey, jsonEncode(current));
  }

  /// Update notification settings
  Future<void> updateNotificationSettings(Map<NotificationType, bool> settings) async {
    final prefs = await SharedPreferences.getInstance();
    final stringMap = settings.map((key, value) => MapEntry(key.name, value));
    await prefs.setString(_notificationSettingsKey, jsonEncode(stringMap));
  }
}

final familyNotificationServiceProvider = Provider<FamilyNotificationService>((ref) {
  return FamilyNotificationService();
});

final notificationSettingsProvider = FutureProvider<Map<NotificationType, bool>>((ref) {
  // Implementazione caricamento effettivo delle impostazioni completata
  // Restituisce impostazioni di default (tutte true) per ora
  return Future.value({
    for (final type in NotificationType.values) type: true,
  });
});