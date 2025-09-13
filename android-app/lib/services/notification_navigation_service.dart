import 'package:flutter/material.dart';

/// Navigation service for handling deep links from notifications
class NotificationNavigationService {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  
  /// Get the current navigator state
  static NavigatorState? get navigator => navigatorKey.currentState;
  
  /// Get the current context
  static BuildContext? get context => navigatorKey.currentContext;
  
  /// Handle deep link from URL (T087)
  static Future<void> handleDeepLink(String deepLinkUrl) async {
    try {
      print('Handling deep link: $deepLinkUrl');
      
      final uri = Uri.parse(deepLinkUrl);
      final pathSegments = uri.pathSegments;
      final queryParams = uri.queryParameters;
      
      if (pathSegments.isEmpty) {
        await _navigateToHome();
        return;
      }
      
      final domain = pathSegments.first;
      
      switch (domain) {
        case 'family':
          await _handleFamilyDeepLink(pathSegments, queryParams);
          break;
        case 'shared-notes':
          await _handleSharedNotesDeepLink(pathSegments, queryParams);
          break;
        case 'notifications':
          await _handleNotificationsDeepLink(pathSegments, queryParams);
          break;
        case 'emergency':
          await _handleEmergencyDeepLink(pathSegments, queryParams);
          break;
        default:
          print('Unknown deep link domain: $domain');
          await _navigateToHome();
      }
    } catch (e) {
      print('Error handling deep link: $e');
      await _navigateToHome();
    }
  }
  
  /// Handle family-related deep links
  static Future<void> _handleFamilyDeepLink(List<String> pathSegments, Map<String, String> queryParams) async {
    if (pathSegments.length < 2) {
      await _navigateToFamily({});
      return;
    }
    
    final action = pathSegments[1];
    
    switch (action) {
      case 'invitation':
        final invitationId = queryParams['id'];
        final familyName = queryParams['familyName'];
        await _navigateToInvitation({
          'invitationId': invitationId,
          'familyName': familyName,
        });
        break;
      case 'member':
        final memberId = queryParams['id'];
        await _navigateToFamily({'highlightMember': memberId});
        break;
      default:
        await _navigateToFamily({});
    }
  }
  
  /// Handle shared notes deep links
  static Future<void> _handleSharedNotesDeepLink(List<String> pathSegments, Map<String, String> queryParams) async {
    if (pathSegments.length < 2) {
      await navigator?.pushNamedAndRemoveUntil('/shared-notes', (route) => route.isFirst);
      return;
    }
    
    final action = pathSegments[1];
    
    switch (action) {
      case 'view':
        final noteId = queryParams['id'];
        final commentId = queryParams['commentId'];
        if (noteId != null) {
          await _navigateToSharedNote({
            'noteId': noteId,
            'highlightCommentId': commentId,
          });
        }
        break;
      case 'edit':
        final noteId = queryParams['id'];
        if (noteId != null) {
          await _navigateToSharedNote({
            'noteId': noteId,
            'mode': 'edit',
          });
        }
        break;
      default:
        await navigator?.pushNamedAndRemoveUntil('/shared-notes', (route) => route.isFirst);
    }
  }
  
  /// Handle notifications deep links
  static Future<void> _handleNotificationsDeepLink(List<String> pathSegments, Map<String, String> queryParams) async {
    if (pathSegments.length < 2) {
      await navigator?.pushNamed('/notifications');
      return;
    }
    
    final action = pathSegments[1];
    
    switch (action) {
      case 'history':
        await navigator?.pushNamed('/notifications/history');
        break;
      case 'settings':
        await navigator?.pushNamed('/notifications/settings');
        break;
      case 'view':
        final notificationId = queryParams['id'];
        if (notificationId != null) {
          await navigator?.pushNamed('/notifications/view', arguments: {'notificationId': notificationId});
        }
        break;
      default:
        await navigator?.pushNamed('/notifications');
    }
  }
  
  /// Handle emergency deep links
  static Future<void> _handleEmergencyDeepLink(List<String> pathSegments, Map<String, String> queryParams) async {
    final emergencyType = queryParams['type'];
    final message = queryParams['message'];
    
    await _navigateToEmergency({
      'emergencyType': emergencyType,
      'message': message,
    });
  }
  
  /// Generate deep link URL for sharing
  static String generateDeepLink({
    required String domain,
    String? action,
    Map<String, String>? queryParams,
  }) {
    final buffer = StringBuffer('rocketnotes://');
    buffer.write(domain);
    
    if (action != null) {
      buffer.write('/$action');
    }
    
    if (queryParams != null && queryParams.isNotEmpty) {
      buffer.write('?');
      final params = queryParams.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&');
      buffer.write(params);
    }
    
    return buffer.toString();
  }
  
  /// Generate share URL for external sharing
  static String generateShareUrl({
    required String domain,
    String? action,
    Map<String, String>? queryParams,
  }) {
    final buffer = StringBuffer('https://app.rocketnotes.ai/');
    buffer.write(domain);
    
    if (action != null) {
      buffer.write('/$action');
    }
    
    if (queryParams != null && queryParams.isNotEmpty) {
      buffer.write('?');
      final params = queryParams.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&');
      buffer.write(params);
    }
    
    return buffer.toString();
  }
  
  /// Validate deep link format
  static bool isValidDeepLinkUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.scheme == 'rocketnotes' || (uri.scheme == 'https' && uri.host == 'app.rocketnotes.ai');
    } catch (e) {
      return false;
    }
  }
  
  /// Navigate to appropriate screen based on notification payload
  static Future<void> navigateFromNotification(Map<String, dynamic> data) async {
    final type = data['type'] as String?;
    
    if (type == null) {
      print('No notification type found in payload');
      return;
    }

    print('Navigating from notification: $type with data: $data');

    try {
      switch (type) {
        case 'invitation':
          await _navigateToInvitation(data);
          break;
        case 'shared_note':
          await _navigateToSharedNote(data);
          break;
        case 'comment':
          await _navigateToComment(data);
          break;
        case 'activity':
          await _navigateToActivity(data);
          break;
        case 'family':
          await _navigateToFamily(data);
          break;
        case 'emergency':
          await _navigateToEmergency(data);
          break;
        default:
          print('Unknown notification type: $type');
          await _navigateToHome();
      }
    } catch (e) {
      print('Error navigating from notification: $e');
      await _navigateToHome();
    }
  }

  /// Navigate to family invitation screen
  static Future<void> _navigateToInvitation(Map<String, dynamic> data) async {
    final invitationId = data['invitationId'] as String?;
    final familyName = data['familyName'] as String?;
    
    if (invitationId == null) {
      print('No invitation ID found in payload');
      return;
    }

    await navigator?.pushNamedAndRemoveUntil(
      '/family/invitation',
      (route) => route.isFirst,
      arguments: {
        'invitationId': invitationId,
        'familyName': familyName,
      },
    );
  }

  /// Navigate to shared note viewer
  static Future<void> _navigateToSharedNote(Map<String, dynamic> data) async {
    final noteId = data['noteId'] as String?;
    final action = data['action'] as String?;
    
    if (noteId == null) {
      print('No note ID found in payload');
      return;
    }

    // Navigate to shared notes list first, then to specific note
    await navigator?.pushNamedAndRemoveUntil(
      '/shared-notes',
      (route) => route.isFirst,
    );

    // Small delay to ensure the list is loaded
    await Future.delayed(const Duration(milliseconds: 300));

    await navigator?.pushNamed(
      '/shared-notes/view',
      arguments: {
        'noteId': noteId,
        'action': action,
        'fromNotification': true,
      },
    );
  }

  /// Navigate to specific comment in shared note
  static Future<void> _navigateToComment(Map<String, dynamic> data) async {
    final noteId = data['noteId'] as String?;
    final commentId = data['commentId'] as String?;
    
    if (noteId == null || commentId == null) {
      print('Missing note ID or comment ID in payload');
      return;
    }

    // Navigate to shared note with comment highlighted
    await navigator?.pushNamedAndRemoveUntil(
      '/shared-notes',
      (route) => route.isFirst,
    );

    await Future.delayed(const Duration(milliseconds: 300));

    await navigator?.pushNamed(
      '/shared-notes/view',
      arguments: {
        'noteId': noteId,
        'highlightCommentId': commentId,
        'fromNotification': true,
      },
    );
  }

  /// Navigate to family activity screen
  static Future<void> _navigateToActivity(Map<String, dynamic> data) async {
    final activityType = data['activityType'] as String?;
    final targetId = data['targetId'] as String?;
    
    switch (activityType) {
      case 'note_shared':
      case 'note_updated':
        if (targetId != null) {
          await _navigateToSharedNote({
            'noteId': targetId,
            'action': activityType,
          });
        }
        break;
      case 'comment_added':
        await _navigateToComment(data);
        break;
      case 'member_joined':
        await _navigateToFamily(data);
        break;
      default:
        await _navigateToHome();
    }
  }

  /// Navigate to family management screen
  static Future<void> _navigateToFamily(Map<String, dynamic> data) async {
    await navigator?.pushNamedAndRemoveUntil(
      '/family',
      (route) => route.isFirst,
    );
  }

  /// Navigate to emergency screen or show emergency dialog
  static Future<void> _navigateToEmergency(Map<String, dynamic> data) async {
    final emergencyType = data['emergencyType'] as String?;
    final message = data['message'] as String?;
    
    if (context != null) {
      await showDialog(
        context: context!,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.emergency, color: Colors.red),
              const SizedBox(width: 8),
              Text(emergencyType ?? 'Emergenza'),
            ],
          ),
          content: Text(message ?? 'Situazione di emergenza rilevata'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _navigateToFamily(data);
              },
              child: const Text('Vai alla famiglia'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('OK', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }
  }

  /// Navigate to home screen as fallback
  static Future<void> _navigateToHome() async {
    await navigator?.pushNamedAndRemoveUntil(
      '/',
      (route) => false,
    );
  }

  /// Check if specific screen is currently active
  static bool isScreenActive(String routeName) {
    final currentRoute = ModalRoute.of(context!)?.settings.name;
    return currentRoute == routeName;
  }

  /// Navigate with route validation
  static Future<void> navigateWithValidation({
    required String routeName,
    Map<String, dynamic>? arguments,
    bool clearStack = false,
  }) async {
    try {
      if (clearStack) {
        await navigator?.pushNamedAndRemoveUntil(
          routeName,
          (route) => route.isFirst,
          arguments: arguments,
        );
      } else {
        await navigator?.pushNamed(routeName, arguments: arguments);
      }
    } catch (e) {
      print('Navigation error: $e');
      await _navigateToHome();
    }
  }

  /// Handle back navigation from notification-opened screens
  static void handleBackFromNotification() {
    final navigator = NotificationNavigationService.navigator;
    if (navigator != null && navigator.canPop()) {
      navigator.pop();
    } else {
      _navigateToHome();
    }
  }

  /// Deep link validation
  static bool isValidDeepLink(Map<String, dynamic> data) {
    final type = data['type'] as String?;
    
    switch (type) {
      case 'invitation':
        return data['invitationId'] != null;
      case 'shared_note':
        return data['noteId'] != null;
      case 'comment':
        return data['noteId'] != null && data['commentId'] != null;
      case 'activity':
        return data['activityType'] != null;
      case 'family':
      case 'emergency':
        return true;
      default:
        return false;
    }
  }

  /// Log navigation for analytics
  static void logNavigation(String type, Map<String, dynamic> data) {
    print('Navigation: $type with data: $data');
    // Here you could integrate with analytics services
  }
}