// ==========================================
// lib/data/services/notification_service.dart
// ==========================================
import '../models/note_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  static const String channelId = 'rocketnotes_reminders';
  static const String channelName = 'Note Reminders';
  static const String channelDescription = 'Notifications for note reminders';

  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Initialize notifications
  Future<bool> initialize() async {
    try {
      // Initialize timezone data
      tz.initializeTimeZones();

      // Android initialization settings
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      // iOS initialization settings
      const DarwinInitializationSettings iosSettings =
          DarwinInitializationSettings(
            requestAlertPermission: true,
            requestBadgePermission: true,
            requestSoundPermission: true,
          );

      // Combined initialization settings
      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      // Initialize the plugin
      final bool? initialized = await _notificationsPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
        onDidReceiveBackgroundNotificationResponse: _onNotificationTapped,
      );

      // Create notification channel for Android
      await _createNotificationChannel();

      return initialized ?? false;
    } catch (e) {
      debugPrint('Error initializing notifications: $e');
      return false;
    }
  }

  // Create notification channel for Android
  Future<void> _createNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      channelId,
      channelName,
      description: channelDescription,
      importance: Importance.high,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('notification'),
    );

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  // Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
    if (response.payload != null) {
      // Navigate to the note
      // This would typically be handled by the app's navigation system
      // For now, we'll just log it
      debugPrint('Should navigate to note with ID: ${response.payload}');
    }
  }

  // Request notification permissions
  Future<bool> requestPermissions() async {
    try {
      // Request permissions for Android
      final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
          _notificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      final bool? androidGranted = await androidPlugin?.requestNotificationsPermission();

      // Request permissions for iOS
      final IOSFlutterLocalNotificationsPlugin? iosPlugin =
          _notificationsPlugin.resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();

      final bool? iosGranted = await iosPlugin?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );

      return (androidGranted ?? true) && (iosGranted ?? true);
    } catch (e) {
      debugPrint('Error requesting notification permissions: $e');
      return false;
    }
  }

  // Schedule reminder notification
  Future<void> scheduleReminder(NoteModel note) async {
    try {
      if (!note.hasReminder) return;

      final scheduledDate = note.reminderDate!;
      if (scheduledDate.isBefore(DateTime.now())) return;

      // Convert to timezone-aware datetime
      final tzScheduledDate = tz.TZDateTime.from(scheduledDate, tz.local);

      // Android notification details
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            channelId,
            channelName,
            channelDescription: channelDescription,
            importance: Importance.high,
            priority: Priority.high,
            playSound: true,
            sound: RawResourceAndroidNotificationSound('notification'),
            icon: '@mipmap/ic_launcher',
          );

      // iOS notification details
      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      // Combined notification details
      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Schedule the notification
      await _notificationsPlugin.zonedSchedule(
        note.id.hashCode, // Use note ID hash as notification ID
        'Note Reminder',
        note.title,
        tzScheduledDate,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: note.id, // Pass note ID as payload
      );

      debugPrint('Scheduling reminder for note: ${note.title} at $scheduledDate');
    } catch (e) {
      debugPrint('Error scheduling reminder: $e');
    }
  }

  // Cancel reminder notification
  Future<void> cancelReminder(String noteId) async {
    try {
      await _notificationsPlugin.cancel(noteId.hashCode);
      debugPrint('Cancelling reminder for note: $noteId');
    } catch (e) {
      debugPrint('Error cancelling reminder: $e');
    }
  }

  // Show immediate notification
  Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      // Android notification details
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            channelId,
            channelName,
            channelDescription: channelDescription,
            importance: Importance.high,
            priority: Priority.high,
            playSound: true,
            sound: RawResourceAndroidNotificationSound('notification'),
            icon: '@mipmap/ic_launcher',
          );

      // iOS notification details
      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      // Combined notification details
      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Show immediate notification
      await _notificationsPlugin.show(
        DateTime.now().millisecondsSinceEpoch, // Unique ID
        title,
        body,
        notificationDetails,
        payload: payload,
      );

      debugPrint('Showing notification: $title - $body');
    } catch (e) {
      debugPrint('Error showing notification: $e');
    }
  }

  // Get pending notifications
  Future<List<PendingNotification>> getPendingNotifications() async {
    try {
      final List<PendingNotificationRequest> pendingRequests =
          await _notificationsPlugin.pendingNotificationRequests();

      return pendingRequests.map((request) {
        return PendingNotification(
          id: request.id,
          title: request.title ?? 'Unknown',
          body: request.body ?? 'Unknown',
          scheduledDate: DateTime.now(), // This would need to be extracted from the notification details
        );
      }).toList();
    } catch (e) {
      debugPrint('Error getting pending notifications: $e');
      return [];
    }
  }

  // Cancel all notifications
  Future<void> cancelAllNotifications() async {
    try {
      await _notificationsPlugin.cancelAll();
      debugPrint('Cancelling all notifications');
    } catch (e) {
      debugPrint('Error cancelling all notifications: $e');
    }
  }
}

// Placeholder for pending notification data
class PendingNotification {
  final int id;
  final String title;
  final String body;
  final DateTime scheduledDate;

  PendingNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.scheduledDate,
  });
}

// ==================
