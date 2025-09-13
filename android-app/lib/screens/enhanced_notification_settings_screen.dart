// ==========================================
// lib/screens/enhanced_notification_settings_screen.dart
// ==========================================
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../services/notification_service.dart';
import '../core/constants/app_colors.dart';
import '../models/notification_models.dart';

// T029: Enhanced notification settings with real FCM integration
// - Connect notification preferences to actual FCM token management
// - Integrate user preferences with Firebase messaging
// - Real-time device token handling and registration
// - Advanced notification channel management

class EnhancedNotificationSettingsScreen extends ConsumerStatefulWidget {
  const EnhancedNotificationSettingsScreen({super.key});

  @override
  ConsumerState<EnhancedNotificationSettingsScreen> createState() => _EnhancedNotificationSettingsScreenState();
}

class _EnhancedNotificationSettingsScreenState extends ConsumerState<EnhancedNotificationSettingsScreen> {
  final NotificationService _notificationService = NotificationService();
  
  bool _isLoading = true;
  bool _permissionsGranted = false;
  String? _fcmToken;
  AuthorizationStatus? _authStatus;
  NotificationPreferences? _preferences;
  Map<String, bool> _channelSettings = {};

  // Notification types that can be configured
  final Map<String, String> _notificationTypes = {
    'family_invitations': 'Family Invitations',
    'shared_notes': 'Shared Notes',
    'note_comments': 'Note Comments',
    'family_activities': 'Family Activities',
    'backup_status': 'Backup Status',
    'system_updates': 'System Updates',
  };

  @override
  void initState() {
    super.initState();
    _loadNotificationSettings();
  }

  Future<void> _loadNotificationSettings() async {
    setState(() => _isLoading = true);
    
    try {
      // Check FCM permissions
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.getNotificationSettings();
      _authStatus = settings.authorizationStatus;
      _permissionsGranted = settings.authorizationStatus == AuthorizationStatus.authorized;
      
      // Get FCM token
      if (_permissionsGranted) {
        _fcmToken = await messaging.getToken();
      }
      
      // Load user preferences
      final preferencesResult = await _notificationService.getNotificationPreferences();
      if (preferencesResult.isSuccess) {
        _preferences = preferencesResult.data;
        _channelSettings = _buildChannelSettings(_preferences!);
      } else {
        // Set default preferences
        _preferences = _getDefaultPreferences();
        _channelSettings = _buildChannelSettings(_preferences!);
      }
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading settings: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  NotificationPreferences _getDefaultPreferences() {
    return NotificationPreferences(
      userId: _notificationService.currentUser?.uid ?? '',
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

  Map<String, bool> _buildChannelSettings(NotificationPreferences preferences) {
    final settings = <String, bool>{};
    settings['family_invitations'] = preferences.familyInvitations;
    settings['shared_notes'] = preferences.sharedNotes;
    settings['note_comments'] = preferences.comments;
    settings['family_activities'] = preferences.familyActivity;
    settings['backup_status'] = true; // Default true for these
    settings['system_updates'] = true;
    return settings;
  }

  Future<void> _requestPermissions() async {
    try {
      final result = await _notificationService.initialize();
      
      if (result.isSuccess) {
        await _loadNotificationSettings();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Notifications enabled successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to enable notifications: ${result.error}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error requesting permissions: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _updatePreferences() async {
    if (_preferences == null) return;
    
    try {
      final result = await _notificationService.updateNotificationPreferences(
        familyInvitations: _channelSettings['family_invitations'],
        sharedNotes: _channelSettings['shared_notes'],
        comments: _channelSettings['note_comments'],
        familyActivity: _channelSettings['family_activities'],
      );
      
      if (result.isSuccess) {
        // Refresh preferences after update
        await _loadNotificationSettings();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Preferences updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update preferences: ${result.error}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating preferences: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _testNotification() async {
    try {
      final result = await _notificationService.sendNotificationToFamily(
        familyId: 'test', // In real implementation, this would be the actual family ID
        title: 'Test Notification',
        body: 'This is a test notification from your settings.',
        type: NotificationType.system,
      );
      
      if (result.isSuccess && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Test notification sent!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send test notification: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Settings'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadNotificationSettings,
            tooltip: 'Refresh Settings',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildPermissionStatus(),
          const SizedBox(height: 16),
          if (_permissionsGranted) ...[
            _buildGeneralSettings(),
            const SizedBox(height: 16),
            _buildNotificationChannels(),
            const SizedBox(height: 16),
            _buildAdvancedSettings(),
            const SizedBox(height: 16),
            _buildDeviceInfo(),
            const SizedBox(height: 16),
            _buildTestSection(),
          ],
        ],
      ),
    );
  }

  Widget _buildPermissionStatus() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _permissionsGranted ? Icons.check_circle : Icons.error_outline,
                  color: _permissionsGranted ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  'Notification Permissions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _permissionsGranted ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _permissionsGranted
                  ? 'Notifications are enabled and working properly.'
                  : 'Notifications are disabled. Enable them to receive family updates.',
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
            ),
            if (!_permissionsGranted) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _requestPermissions,
                icon: const Icon(Icons.notifications),
                label: const Text('Enable Notifications'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
            if (_authStatus != null) ...[
              const SizedBox(height: 8),
              Text(
                'Status: ${_authStatus!.name}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildGeneralSettings() {
    if (_preferences == null) return const SizedBox.shrink();

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'General Settings',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          SwitchListTile(
            title: const Text('Push Notifications'),
            subtitle: const Text('Receive notifications on this device'),
            value: _preferences!.delivery.push,
            onChanged: (value) {
              // This would need to update delivery preferences
              // Implementation simplified for this example
            },
            secondary: const Icon(Icons.notifications),
          ),
          const Divider(height: 1),
          SwitchListTile(
            title: const Text('In-App Notifications'),
            subtitle: const Text('Show notifications while using the app'),
            value: _preferences!.delivery.inApp,
            onChanged: (value) {
              // This would need to update delivery preferences
              // Implementation simplified for this example
            },
            secondary: const Icon(Icons.app_settings_alt),
          ),
          const Divider(height: 1),
          SwitchListTile(
            title: const Text('Email Notifications'),
            subtitle: const Text('Receive notifications via email'),
            value: _preferences!.delivery.email,
            onChanged: (value) {
              // This would need to update delivery preferences
              // Implementation simplified for this example
            },
            secondary: const Icon(Icons.email),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationChannels() {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Notification Types',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          ..._notificationTypes.entries.map((entry) {
            final type = entry.key;
            final title = entry.value;
            
            return SwitchListTile(
              title: Text(title),
              subtitle: Text(_getChannelDescription(type)),
              value: _channelSettings[type] ?? true,
              onChanged: (value) {
                setState(() {
                  _channelSettings[type] = value;
                });
                _updatePreferences();
              },
              secondary: Icon(_getChannelIcon(type)),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildAdvancedSettings() {
    if (_preferences == null) return const SizedBox.shrink();

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Advanced Settings',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          ListTile(
            title: const Text('Priority Levels'),
            subtitle: const Text('Configure which priority levels to receive'),
            leading: const Icon(Icons.priority_high),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: _showPriorityDialog,
          ),
          const Divider(height: 1),
          ListTile(
            title: const Text('Quiet Hours'),
            subtitle: Text(
              _preferences!.quietHours?.enabled == true
                  ? 'Enabled: ${_preferences!.quietHours!.start} - ${_preferences!.quietHours!.end}'
                  : 'Disabled',
            ),
            leading: const Icon(Icons.bedtime),
            trailing: Switch(
              value: _preferences!.quietHours?.enabled ?? false,
              onChanged: (value) {
                // Implementation for quiet hours would go here
                if (value) {
                  _showQuietHoursDialog();
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Device Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (_fcmToken != null) ...[
              Text(
                'FCM Token:',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _fcmToken!.length > 50 
                      ? '${_fcmToken!.substring(0, 50)}...'
                      : _fcmToken!,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
            Text(
              'Preferences Status: ${_preferences != null ? "Loaded" : "Default"}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Test Notifications',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Send a test notification to verify your settings are working correctly.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _testNotification,
              icon: const Icon(Icons.send),
              label: const Text('Send Test Notification'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getChannelDescription(String type) {
    switch (type) {
      case 'family_invitations':
        return 'Notifications when someone invites you to join a family';
      case 'shared_notes':
        return 'Notifications when notes are shared with you';
      case 'note_comments':
        return 'Notifications for new comments on your shared notes';
      case 'family_activities':
        return 'Notifications for family member activities and updates';
      case 'backup_status':
        return 'Notifications about backup and sync status';
      case 'system_updates':
        return 'Notifications about app updates and maintenance';
      default:
        return 'General notifications';
    }
  }

  IconData _getChannelIcon(String type) {
    switch (type) {
      case 'family_invitations':
        return Icons.family_restroom;
      case 'shared_notes':
        return Icons.share;
      case 'note_comments':
        return Icons.comment;
      case 'family_activities':
        return Icons.people_alt;
      case 'backup_status':
        return Icons.backup;
      case 'system_updates':
        return Icons.system_update;
      default:
        return Icons.notifications;
    }
  }

  void _showPriorityDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notification Priority'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CheckboxListTile(
              title: const Text('High Priority'),
              subtitle: const Text('Important notifications'),
              value: _preferences!.priority.high,
              onChanged: (value) {
                // Implementation for priority changes would go here
                Navigator.of(context).pop();
              },
            ),
            CheckboxListTile(
              title: const Text('Normal Priority'),
              subtitle: const Text('Standard notifications'),
              value: _preferences!.priority.normal,
              onChanged: (value) {
                // Implementation for priority changes would go here
                Navigator.of(context).pop();
              },
            ),
            CheckboxListTile(
              title: const Text('Low Priority'),
              subtitle: const Text('Less important notifications'),
              value: _preferences!.priority.low,
              onChanged: (value) {
                // Implementation for priority changes would go here
                Navigator.of(context).pop();
              },
            ),
            CheckboxListTile(
              title: const Text('Urgent Priority'),
              subtitle: const Text('Critical notifications'),
              value: _preferences!.priority.urgent,
              onChanged: (value) {
                // Implementation for priority changes would go here
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showQuietHoursDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quiet Hours'),
        content: const Text('Quiet hours configuration will be implemented soon.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}