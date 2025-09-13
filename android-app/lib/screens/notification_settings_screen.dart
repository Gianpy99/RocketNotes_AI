import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/notification_providers.dart';
import '../temp_family_notification_service.dart';

/// Screen for managing notification preferences and settings (T088)
class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends ConsumerState<NotificationSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final preferences = ref.watch(notificationPreferencesProvider);
    final notificationService = ref.watch(notificationServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Impostazioni Notifiche'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // General Notification Settings
          Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Impostazioni Generali',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                SwitchListTile(
                  title: const Text('Notifiche famiglia'),
                  subtitle: const Text('Ricevi notifiche per inviti e attività familiari'),
                  value: preferences['enableInvitations'] ?? true,
                  onChanged: (value) {
                    ref.read(notificationPreferencesProvider.notifier).updatePreference('enableInvitations', value);
                    _updateServerPreferences(ref);
                  },
                  secondary: const Icon(Icons.family_restroom),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('Notifiche attività'),
                  subtitle: const Text('Ricevi notifiche per condivisioni e aggiornamenti'),
                  value: preferences['enableActivities'] ?? true,
                  onChanged: (value) {
                    ref.read(notificationPreferencesProvider.notifier).updatePreference('enableActivities', value);
                    _updateServerPreferences(ref);
                  },
                  secondary: const Icon(Icons.notifications_active),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('Notifiche commenti'),
                  subtitle: const Text('Ricevi notifiche per nuovi commenti'),
                  value: preferences['enableComments'] ?? true,
                  onChanged: (value) {
                    ref.read(notificationPreferencesProvider.notifier).updatePreference('enableComments', value);
                    _updateServerPreferences(ref);
                  },
                  secondary: const Icon(Icons.comment),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('Notifiche di sistema'),
                  subtitle: const Text('Ricevi notifiche per aggiornamenti e manutenzione'),
                  value: preferences['enableSystemNotifications'] ?? true,
                  onChanged: (value) {
                    ref.read(notificationPreferencesProvider.notifier).updatePreference('enableSystemNotifications', value);
                    _updateServerPreferences(ref);
                  },
                  secondary: const Icon(Icons.settings),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Sound and Vibration Settings
          Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Audio e Vibrazione',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                SwitchListTile(
                  title: const Text('Suono notifiche'),
                  subtitle: const Text('Riproduci suono per le notifiche'),
                  value: preferences['soundEnabled'] ?? true,
                  onChanged: (value) {
                    ref.read(notificationPreferencesProvider.notifier).updatePreference('soundEnabled', value);
                  },
                  secondary: const Icon(Icons.volume_up),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('Vibrazione'),
                  subtitle: const Text('Vibra per le notifiche'),
                  value: preferences['vibrationEnabled'] ?? true,
                  onChanged: (value) {
                    ref.read(notificationPreferencesProvider.notifier).updatePreference('vibrationEnabled', value);
                  },
                  secondary: const Icon(Icons.vibration),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Priority Settings
          Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Priorità Notifiche',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                ListTile(
                  title: const Text('Priorità predefinita'),
                  subtitle: Text('Livello: ${_getPriorityDisplayName(preferences['defaultPriority'] ?? 'normal')}'),
                  trailing: DropdownButton<String>(
                    value: preferences['defaultPriority'] ?? 'normal',
                    onChanged: (value) {
                      if (value != null) {
                        ref.read(notificationPreferencesProvider.notifier).updatePreference('defaultPriority', value);
                        _updateServerPreferences(ref);
                      }
                    },
                    items: const [
                      DropdownMenuItem(value: 'low', child: Text('Bassa')),
                      DropdownMenuItem(value: 'normal', child: Text('Normale')),
                      DropdownMenuItem(value: 'high', child: Text('Alta')),
                      DropdownMenuItem(value: 'urgent', child: Text('Urgente')),
                    ],
                  ),
                  leading: const Icon(Icons.priority_high),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('Mostra anteprima'),
                  subtitle: const Text('Mostra contenuto notifica nella lock screen'),
                  value: preferences['showPreview'] ?? true,
                  onChanged: (value) {
                    ref.read(notificationPreferencesProvider.notifier).updatePreference('showPreview', value);
                  },
                  secondary: const Icon(Icons.preview),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Quiet Hours Settings
          Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Ore di Silenzio',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                SwitchListTile(
                  title: const Text('Abilita ore di silenzio'),
                  subtitle: const Text('Disabilita notifiche durante le ore specificate'),
                  value: preferences['quietHoursEnabled'] ?? false,
                  onChanged: (value) {
                    ref.read(notificationPreferencesProvider.notifier).updatePreference('quietHoursEnabled', value);
                  },
                  secondary: const Icon(Icons.bedtime),
                ),
                if (preferences['quietHoursEnabled'] ?? false) ...[
                  const Divider(height: 1),
                  ListTile(
                    title: const Text('Ora inizio'),
                    subtitle: Text(preferences['quietHoursStart'] ?? '22:00'),
                    trailing: const Icon(Icons.access_time),
                    onTap: () => _selectTime(context, ref, 'quietHoursStart'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    title: const Text('Ora fine'),
                    subtitle: Text(preferences['quietHoursEnd'] ?? '07:00'),
                    trailing: const Icon(Icons.access_time),
                    onTap: () => _selectTime(context, ref, 'quietHoursEnd'),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Emergency Override
          Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Notifiche di Emergenza',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                SwitchListTile(
                  title: const Text('Ignora modalità silenziosa'),
                  subtitle: const Text('Le notifiche di emergenza ignorano tutte le impostazioni'),
                  value: preferences['emergencyOverride'] ?? true,
                  onChanged: (value) {
                    ref.read(notificationPreferencesProvider.notifier).updatePreference('emergencyOverride', value);
                  },
                  secondary: const Icon(Icons.emergency, color: Colors.red),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Action Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: () => _testNotification(notificationService),
                icon: const Icon(Icons.notifications),
                label: const Text('Test Notifica'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              ),
              ElevatedButton.icon(
                onPressed: () => _resetToDefaults(ref),
                icon: const Icon(Icons.restore),
                label: const Text('Ripristina'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // FCM Token Info (Debug)
          if (preferences['showDebugInfo'] ?? false)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Debug Info', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    FutureBuilder<String?>(
                      future: notificationService.getCurrentToken(),
                      builder: (context, snapshot) {
                        return Text('FCM Token: ${snapshot.data ?? 'Loading...'}');
                      },
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _getPriorityDisplayName(String priority) {
    switch (priority) {
      case 'low': return 'Bassa';
      case 'normal': return 'Normale';
      case 'high': return 'Alta';
      case 'urgent': return 'Urgente';
      default: return 'Normale';
    }
  }

  Future<void> _selectTime(BuildContext context, WidgetRef ref, String key) async {
    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    
    if (time != null) {
      final timeString = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
      ref.read(notificationPreferencesProvider.notifier).updatePreference(key, timeString);
    }
  }

  Future<void> _testNotification(FamilyNotificationService service) async {
    try {
      await service.sendHighPriorityNotification(
        recipientId: 'current_user',
        title: 'Test Notifica',
        message: 'Questa è una notifica di test per verificare le tue impostazioni.',
        data: {'type': 'test'},
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notifica di test inviata!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore invio notifica: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _resetToDefaults(WidgetRef ref) {
    ref.read(notificationPreferencesProvider.notifier).updateAllPreferences({
      'enableInvitations': true,
      'enableActivities': true,
      'enableComments': true,
      'enableSystemNotifications': true,
      'soundEnabled': true,
      'vibrationEnabled': true,
      'defaultPriority': 'normal',
      'showPreview': true,
      'quietHoursEnabled': false,
      'quietHoursStart': '22:00',
      'quietHoursEnd': '07:00',
      'emergencyOverride': true,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Impostazioni ripristinate ai valori predefiniti'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  Future<void> _updateServerPreferences(WidgetRef ref) async {
    final preferences = ref.read(notificationPreferencesProvider);
    final service = ref.read(notificationServiceProvider);
    
    try {
      await service.updateNotificationPreferences(
        enableInvitations: preferences['enableInvitations'] ?? true,
        enableActivities: preferences['enableActivities'] ?? true,
        enableComments: preferences['enableComments'] ?? true,
        priority: preferences['defaultPriority'] ?? 'normal',
      );
    } catch (e) {
      print('Error updating server preferences: $e');
    }
  }
}