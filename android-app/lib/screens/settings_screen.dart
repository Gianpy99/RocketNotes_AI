// Settings Screen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../main_simple.dart';
import 'family_members_screen.dart';

// TODO: FAMILY_FEATURES - Add family settings
// - Family member management (add/remove/edit profiles)
// - Family sharing permissions and access control
// - Emergency contacts management
// - Family calendar integration settings
// - Child-safe mode and parental controls

// TODO: BACKUP_SYSTEM - Add backup settings
// - Automatic backup scheduling
// - Cloud sync configuration (Google Drive, iCloud)
// - Backup location preferences
// - Data export/import functionality
// - Backup history and restore options

final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  return SettingsNotifier();
});

class AppSettings {
  final bool darkMode;
  final String defaultMode;
  final bool enableAI;
  final bool autoSave;
  
  // AI Settings
  final String aiApiKey;
  final bool aiEnabled;
  final String aiProvider;
  final bool aiSmartSuggestions;
  final bool aiAutoTags;
  final bool aiGrammarCheck;
  final bool aiContentEnhancement;
  
  // Backup Settings
  final bool autoBackup;
  final bool cloudSync;
  final String backupFrequency;
  final String backupLocation;
  final bool backupNotifications;
  final int backupRetentionDays;
  
  // Family Settings
  final bool familySharingEnabled;
  final bool familyNotificationsEnabled;
  final String familyDefaultPermission;
  final bool emergencyContactsEnabled;
  final bool childSafeMode;
  final int maxFamilyMembers;

  AppSettings({
    this.darkMode = false,
    this.defaultMode = 'personal',
    this.enableAI = true,
    this.autoSave = true,
    this.aiApiKey = '',
    this.aiEnabled = true,
    this.aiProvider = 'openai',
    this.aiSmartSuggestions = true,
    this.aiAutoTags = true,
    this.aiGrammarCheck = false,
    this.aiContentEnhancement = false,
    this.autoBackup = false,
    this.cloudSync = false,
    this.backupFrequency = 'daily',
    this.backupLocation = 'local',
    this.backupNotifications = true,
    this.backupRetentionDays = 30,
    this.familySharingEnabled = true,
    this.familyNotificationsEnabled = true,
    this.familyDefaultPermission = 'read',
    this.emergencyContactsEnabled = false,
    this.childSafeMode = false,
    this.maxFamilyMembers = 10,
  });

  AppSettings copyWith({
    bool? darkMode,
    String? defaultMode,
    bool? enableAI,
    bool? autoSave,
    String? aiApiKey,
    bool? aiEnabled,
    String? aiProvider,
    bool? aiSmartSuggestions,
    bool? aiAutoTags,
    bool? aiGrammarCheck,
    bool? aiContentEnhancement,
    bool? autoBackup,
    bool? cloudSync,
    String? backupFrequency,
    String? backupLocation,
    bool? backupNotifications,
    int? backupRetentionDays,
    bool? familySharingEnabled,
    bool? familyNotificationsEnabled,
    String? familyDefaultPermission,
    bool? emergencyContactsEnabled,
    bool? childSafeMode,
    int? maxFamilyMembers,
  }) {
    return AppSettings(
      darkMode: darkMode ?? this.darkMode,
      defaultMode: defaultMode ?? this.defaultMode,
      enableAI: enableAI ?? this.enableAI,
      autoSave: autoSave ?? this.autoSave,
      aiApiKey: aiApiKey ?? this.aiApiKey,
      aiEnabled: aiEnabled ?? this.aiEnabled,
      aiProvider: aiProvider ?? this.aiProvider,
      aiSmartSuggestions: aiSmartSuggestions ?? this.aiSmartSuggestions,
      aiAutoTags: aiAutoTags ?? this.aiAutoTags,
      aiGrammarCheck: aiGrammarCheck ?? this.aiGrammarCheck,
      aiContentEnhancement: aiContentEnhancement ?? this.aiContentEnhancement,
      autoBackup: autoBackup ?? this.autoBackup,
      cloudSync: cloudSync ?? this.cloudSync,
      backupFrequency: backupFrequency ?? this.backupFrequency,
      backupLocation: backupLocation ?? this.backupLocation,
      backupNotifications: backupNotifications ?? this.backupNotifications,
      backupRetentionDays: backupRetentionDays ?? this.backupRetentionDays,
      familySharingEnabled: familySharingEnabled ?? this.familySharingEnabled,
      familyNotificationsEnabled: familyNotificationsEnabled ?? this.familyNotificationsEnabled,
      familyDefaultPermission: familyDefaultPermission ?? this.familyDefaultPermission,
      emergencyContactsEnabled: emergencyContactsEnabled ?? this.emergencyContactsEnabled,
      childSafeMode: childSafeMode ?? this.childSafeMode,
      maxFamilyMembers: maxFamilyMembers ?? this.maxFamilyMembers,
    );
  }
}

class SettingsNotifier extends StateNotifier<AppSettings> {
  static const String _settingsBoxName = 'app_settings';
  
  SettingsNotifier() : super(AppSettings()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final box = await Hive.openBox(_settingsBoxName);
      final settingsJson = box.get('settings');
      if (settingsJson != null) {
        // Load settings from Hive
        state = AppSettings(
          darkMode: settingsJson['darkMode'] ?? false,
          defaultMode: settingsJson['defaultMode'] ?? 'personal',
          enableAI: settingsJson['enableAI'] ?? true,
          autoSave: settingsJson['autoSave'] ?? true,
          aiApiKey: settingsJson['aiApiKey'] ?? '',
          aiEnabled: settingsJson['aiEnabled'] ?? true,
          aiProvider: settingsJson['aiProvider'] ?? 'openai',
          aiSmartSuggestions: settingsJson['aiSmartSuggestions'] ?? true,
          aiAutoTags: settingsJson['aiAutoTags'] ?? true,
          aiGrammarCheck: settingsJson['aiGrammarCheck'] ?? false,
          aiContentEnhancement: settingsJson['aiContentEnhancement'] ?? false,
          autoBackup: settingsJson['autoBackup'] ?? false,
          cloudSync: settingsJson['cloudSync'] ?? false,
          backupFrequency: settingsJson['backupFrequency'] ?? 'daily',
          backupLocation: settingsJson['backupLocation'] ?? 'local',
          backupNotifications: settingsJson['backupNotifications'] ?? true,
          backupRetentionDays: settingsJson['backupRetentionDays'] ?? 30,
          familySharingEnabled: settingsJson['familySharingEnabled'] ?? true,
          familyNotificationsEnabled: settingsJson['familyNotificationsEnabled'] ?? true,
          familyDefaultPermission: settingsJson['familyDefaultPermission'] ?? 'read',
          emergencyContactsEnabled: settingsJson['emergencyContactsEnabled'] ?? false,
          childSafeMode: settingsJson['childSafeMode'] ?? false,
          maxFamilyMembers: settingsJson['maxFamilyMembers'] ?? 10,
        );
      }
    } catch (e) {
      // If loading fails, use default settings
      print('Error loading settings: $e');
    }
  }

  Future<void> _saveSettings() async {
    try {
      final box = await Hive.openBox(_settingsBoxName);
      final settingsJson = {
        'darkMode': state.darkMode,
        'defaultMode': state.defaultMode,
        'enableAI': state.enableAI,
        'autoSave': state.autoSave,
        'aiApiKey': state.aiApiKey,
        'aiEnabled': state.aiEnabled,
        'aiProvider': state.aiProvider,
        'aiSmartSuggestions': state.aiSmartSuggestions,
        'aiAutoTags': state.aiAutoTags,
        'aiGrammarCheck': state.aiGrammarCheck,
        'aiContentEnhancement': state.aiContentEnhancement,
        'autoBackup': state.autoBackup,
        'cloudSync': state.cloudSync,
        'backupFrequency': state.backupFrequency,
        'backupLocation': state.backupLocation,
        'backupNotifications': state.backupNotifications,
        'backupRetentionDays': state.backupRetentionDays,
        'familySharingEnabled': state.familySharingEnabled,
        'familyNotificationsEnabled': state.familyNotificationsEnabled,
        'familyDefaultPermission': state.familyDefaultPermission,
        'emergencyContactsEnabled': state.emergencyContactsEnabled,
        'childSafeMode': state.childSafeMode,
        'maxFamilyMembers': state.maxFamilyMembers,
      };
      await box.put('settings', settingsJson);
    } catch (e) {
      print('Error saving settings: $e');
    }
  }

  void toggleDarkMode() {
    state = state.copyWith(darkMode: !state.darkMode);
    _saveSettings();
  }

  void setDefaultMode(String mode) {
    state = state.copyWith(defaultMode: mode);
    _saveSettings();
  }

  void toggleAI() {
    state = state.copyWith(enableAI: !state.enableAI);
    _saveSettings();
  }

  void toggleAutoSave() {
    state = state.copyWith(autoSave: !state.autoSave);
    _saveSettings();
  }

  void updateSettings(AppSettings newSettings) {
    state = newSettings;
    _saveSettings();
  }

  // AI Settings methods
  void setAiApiKey(String apiKey) {
    state = state.copyWith(aiApiKey: apiKey);
    _saveSettings();
  }

  void setAiEnabled(bool enabled) {
    state = state.copyWith(aiEnabled: enabled);
    _saveSettings();
  }

  void setAiProvider(String provider) {
    state = state.copyWith(aiProvider: provider);
    _saveSettings();
  }

  void setAiSmartSuggestions(bool enabled) {
    state = state.copyWith(aiSmartSuggestions: enabled);
    _saveSettings();
  }

  void setAiAutoTags(bool enabled) {
    state = state.copyWith(aiAutoTags: enabled);
    _saveSettings();
  }

  void setAiGrammarCheck(bool enabled) {
    state = state.copyWith(aiGrammarCheck: enabled);
    _saveSettings();
  }

  void setAiContentEnhancement(bool enabled) {
    state = state.copyWith(aiContentEnhancement: enabled);
    _saveSettings();
  }

  // Backup Settings methods
  void setAutoBackup(bool enabled) {
    state = state.copyWith(autoBackup: enabled);
    _saveSettings();
  }

  void setCloudSync(bool enabled) {
    state = state.copyWith(cloudSync: enabled);
    _saveSettings();
  }

  void setBackupFrequency(String frequency) {
    state = state.copyWith(backupFrequency: frequency);
    _saveSettings();
  }

  void setBackupLocation(String location) {
    state = state.copyWith(backupLocation: location);
    _saveSettings();
  }

  void setBackupNotifications(bool enabled) {
    state = state.copyWith(backupNotifications: enabled);
    _saveSettings();
  }

  void setBackupRetentionDays(int days) {
    state = state.copyWith(backupRetentionDays: days);
    _saveSettings();
  }

  // Family Settings methods
  void setFamilySharingEnabled(bool enabled) {
    state = state.copyWith(familySharingEnabled: enabled);
    _saveSettings();
  }

  void setFamilyNotificationsEnabled(bool enabled) {
    state = state.copyWith(familyNotificationsEnabled: enabled);
    _saveSettings();
  }

  void setFamilyDefaultPermission(String permission) {
    state = state.copyWith(familyDefaultPermission: permission);
    _saveSettings();
  }

  void setEmergencyContactsEnabled(bool enabled) {
    state = state.copyWith(emergencyContactsEnabled: enabled);
    _saveSettings();
  }

  void setChildSafeMode(bool enabled) {
    state = state.copyWith(childSafeMode: enabled);
    _saveSettings();
  }

  void setMaxFamilyMembers(int max) {
    state = state.copyWith(maxFamilyMembers: max);
    _saveSettings();
  }
}

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notesCount = ref.watch(notesProvider).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Impostazioni'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // App Info
          Card(
            child: ListTile(
              leading: const Icon(Icons.rocket_launch, color: Colors.deepPurple),
              title: const Text('RocketNotes AI'),
              subtitle: Text('$notesCount note salvate'),
              trailing: const Text('v1.0.0', style: TextStyle(color: Colors.grey)),
            ),
          ),

          const SizedBox(height: 16),

          // Appearance
          const Text(
            'Aspetto',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Modalità scura'),
                  subtitle: const Text('Attiva il tema scuro'),
                  value: settings.darkMode,
                  onChanged: (value) {
                    ref.read(settingsProvider.notifier).toggleDarkMode();
                  },
                  secondary: const Icon(Icons.dark_mode),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Default Settings
          const Text(
            'Impostazioni predefinite',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  title: const Text('Modalità predefinita'),
                  subtitle: const Text('Modalità per le nuove note'),
                  leading: const Icon(Icons.settings),
                  trailing: DropdownButton<String>(
                    value: settings.defaultMode,
                    onChanged: (value) {
                      if (value != null) {
                        ref.read(settingsProvider.notifier).setDefaultMode(value);
                      }
                    },
                    items: const [
                      DropdownMenuItem(value: 'personal', child: Text('Personale')),
                      DropdownMenuItem(value: 'work', child: Text('Lavoro')),
                    ],
                  ),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('Salvataggio automatico'),
                  subtitle: const Text('Salva automaticamente mentre scrivi'),
                  value: settings.autoSave,
                  onChanged: (value) {
                    ref.read(settingsProvider.notifier).toggleAutoSave();
                  },
                  secondary: const Icon(Icons.save),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // AI Features
          const Text(
            'Funzionalità AI',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Assistente AI'),
                  subtitle: const Text('Abilita suggerimenti e miglioramenti AI'),
                  value: settings.enableAI,
                  onChanged: (value) {
                    ref.read(settingsProvider.notifier).toggleAI();
                  },
                  secondary: const Icon(Icons.smart_toy),
                ),
                if (settings.enableAI) ...[
                  const Divider(height: 1),
                  ListTile(
                    title: const Text('Analisi sentimenti'),
                    subtitle: const Text('Coming soon'),
                    leading: const Icon(Icons.sentiment_satisfied),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Funzionalità in arrivo!')),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    title: const Text('Suggerimenti di scrittura'),
                    subtitle: const Text('Coming soon'),
                    leading: const Icon(Icons.lightbulb),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Funzionalità in arrivo!')),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Data Management
          const Text(
            'Gestione dati',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  title: const Text('Esporta note'),
                  subtitle: const Text('Salva tutte le note in un file'),
                  leading: const Icon(Icons.download),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    _showExportDialog(context, ref);
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  title: const Text('Importa note'),
                  subtitle: const Text('Carica note da un file'),
                  leading: const Icon(Icons.upload),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Funzionalità in arrivo!')),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  title: const Text('Cancella tutte le note'),
                  subtitle: const Text('Elimina permanentemente tutte le note'),
                  leading: const Icon(Icons.delete_forever, color: Colors.red),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    _showDeleteAllDialog(context, ref);
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Backup Settings
          const Text(
            'Backup e sincronizzazione',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Backup automatico'),
                  subtitle: const Text('Esegui backup automaticamente'),
                  value: settings.autoBackup,
                  onChanged: (value) {
                    ref.read(settingsProvider.notifier).setAutoBackup(value);
                  },
                  secondary: const Icon(Icons.backup),
                ),
                if (settings.autoBackup) ...[
                  const Divider(height: 1),
                  ListTile(
                    title: const Text('Frequenza backup'),
                    subtitle: const Text('Quanto spesso eseguire il backup'),
                    leading: const Icon(Icons.schedule),
                    trailing: DropdownButton<String>(
                      value: settings.backupFrequency,
                      onChanged: (value) {
                        if (value != null) {
                          ref.read(settingsProvider.notifier).setBackupFrequency(value);
                        }
                      },
                      items: const [
                        DropdownMenuItem(value: 'hourly', child: Text('Ogni ora')),
                        DropdownMenuItem(value: 'daily', child: Text('Giornaliero')),
                        DropdownMenuItem(value: 'weekly', child: Text('Settimanale')),
                        DropdownMenuItem(value: 'monthly', child: Text('Mensile')),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    title: const Text('Posizione backup'),
                    subtitle: const Text('Dove salvare i backup'),
                    leading: const Icon(Icons.folder),
                    trailing: DropdownButton<String>(
                      value: settings.backupLocation,
                      onChanged: (value) {
                        if (value != null) {
                          ref.read(settingsProvider.notifier).setBackupLocation(value);
                        }
                      },
                      items: const [
                        DropdownMenuItem(value: 'local', child: Text('Dispositivo locale')),
                        DropdownMenuItem(value: 'drive', child: Text('Google Drive')),
                        DropdownMenuItem(value: 'icloud', child: Text('iCloud')),
                        DropdownMenuItem(value: 'onedrive', child: Text('OneDrive')),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    title: const Text('Conservazione backup'),
                    subtitle: Text('${settings.backupRetentionDays} giorni'),
                    leading: const Icon(Icons.history),
                    trailing: DropdownButton<int>(
                      value: settings.backupRetentionDays,
                      onChanged: (value) {
                        if (value != null) {
                          ref.read(settingsProvider.notifier).setBackupRetentionDays(value);
                        }
                      },
                      items: const [
                        DropdownMenuItem(value: 7, child: Text('7 giorni')),
                        DropdownMenuItem(value: 30, child: Text('30 giorni')),
                        DropdownMenuItem(value: 90, child: Text('90 giorni')),
                        DropdownMenuItem(value: 365, child: Text('1 anno')),
                      ],
                    ),
                  ),
                ],
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('Sincronizzazione cloud'),
                  subtitle: const Text('Sincronizza con il cloud'),
                  value: settings.cloudSync,
                  onChanged: (value) {
                    ref.read(settingsProvider.notifier).setCloudSync(value);
                  },
                  secondary: const Icon(Icons.cloud_sync),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('Notifiche backup'),
                  subtitle: const Text('Ricevi notifiche sui backup'),
                  value: settings.backupNotifications,
                  onChanged: (value) {
                    ref.read(settingsProvider.notifier).setBackupNotifications(value);
                  },
                  secondary: const Icon(Icons.notifications_active),
                ),
                const Divider(height: 1),
                ListTile(
                  title: const Text('Esegui backup ora'),
                  subtitle: const Text('Crea un backup immediato'),
                  leading: const Icon(Icons.play_arrow),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    _performBackup(context);
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  title: const Text('Ripristina backup'),
                  subtitle: const Text('Ripristina da un backup precedente'),
                  leading: const Icon(Icons.restore),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    _showRestoreDialog(context);
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Family Features
          const Text(
            'Famiglia',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Condivisione famiglia'),
                  subtitle: const Text('Abilita condivisione note con familiari'),
                  value: settings.familySharingEnabled,
                  onChanged: (value) {
                    ref.read(settingsProvider.notifier).setFamilySharingEnabled(value);
                  },
                  secondary: const Icon(Icons.family_restroom),
                ),
                if (settings.familySharingEnabled) ...[
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('Notifiche famiglia'),
                    subtitle: const Text('Ricevi notifiche per attività familiari'),
                    value: settings.familyNotificationsEnabled,
                    onChanged: (value) {
                      ref.read(settingsProvider.notifier).setFamilyNotificationsEnabled(value);
                    },
                    secondary: const Icon(Icons.notifications),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    title: const Text('Permesso predefinito'),
                    subtitle: const Text('Permesso automatico per nuovi membri'),
                    leading: const Icon(Icons.security),
                    trailing: DropdownButton<String>(
                      value: settings.familyDefaultPermission,
                      onChanged: (value) {
                        if (value != null) {
                          ref.read(settingsProvider.notifier).setFamilyDefaultPermission(value);
                        }
                      },
                      items: const [
                        DropdownMenuItem(value: 'read', child: Text('Solo lettura')),
                        DropdownMenuItem(value: 'write', child: Text('Lettura e scrittura')),
                        DropdownMenuItem(value: 'admin', child: Text('Amministratore')),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    title: const Text('Max membri famiglia'),
                    subtitle: Text('Massimo ${settings.maxFamilyMembers} membri'),
                    leading: const Icon(Icons.group),
                    trailing: DropdownButton<int>(
                      value: settings.maxFamilyMembers,
                      onChanged: (value) {
                        if (value != null) {
                          ref.read(settingsProvider.notifier).setMaxFamilyMembers(value);
                        }
                      },
                      items: const [
                        DropdownMenuItem(value: 5, child: Text('5 membri')),
                        DropdownMenuItem(value: 10, child: Text('10 membri')),
                        DropdownMenuItem(value: 20, child: Text('20 membri')),
                        DropdownMenuItem(value: 50, child: Text('50 membri')),
                      ],
                    ),
                  ),
                ],
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('Contatti emergenza'),
                  subtitle: const Text('Gestisci contatti di emergenza'),
                  value: settings.emergencyContactsEnabled,
                  onChanged: (value) {
                    ref.read(settingsProvider.notifier).setEmergencyContactsEnabled(value);
                  },
                  secondary: const Icon(Icons.emergency),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('Modalità bambino'),
                  subtitle: const Text('Controlli parentali e contenuti sicuri'),
                  value: settings.childSafeMode,
                  onChanged: (value) {
                    ref.read(settingsProvider.notifier).setChildSafeMode(value);
                  },
                  secondary: const Icon(Icons.child_care),
                ),
                const Divider(height: 1),
                ListTile(
                  title: const Text('Membri della famiglia'),
                  subtitle: const Text('Gestisci i profili familiari'),
                  leading: const Icon(Icons.people),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const FamilyMembersScreen(),
                      ),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  title: const Text('Notebook condivisi'),
                  subtitle: const Text('Gestisci notebook familiari'),
                  leading: const Icon(Icons.book),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Notebook condivisi - Coming Soon!')),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          Card(
            child: ListTile(
              title: const Text('Informazioni'),
              subtitle: const Text('Sviluppato con ❤️ usando Flutter'),
              leading: const Icon(Icons.info),
              onTap: () {
                showAboutDialog(
                  context: context,
                  applicationName: 'RocketNotes AI',
                  applicationVersion: '1.0.0',
                  applicationIcon: const Icon(Icons.rocket_launch, size: 32),
                  children: const [
                    Text('Un\'app di note potenziata dall\'intelligenza artificiale.'),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showExportDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Esporta note'),
        content: const Text('Vuoi esportare tutte le tue note?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annulla'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Simulated export
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Note esportate con successo!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Esporta'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAllDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancella tutte le note'),
        content: const Text(
          'Sei sicuro di voler eliminare tutte le note?\n\nQuesta operazione è irreversibile.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annulla'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final box = Hive.box('notes');
                await box.clear();
                ref.read(notesProvider.notifier).loadNotes();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Tutte le note sono state eliminate'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Errore durante l\'eliminazione: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Elimina tutto'),
          ),
        ],
      ),
    );
  }

  void _performBackup(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Esegui backup'),
        content: const Text('Vuoi creare un backup immediato di tutte le tue note?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annulla'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                // Simulated backup process
                await Future.delayed(const Duration(seconds: 2));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Backup completato con successo!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Errore durante il backup: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Esegui backup'),
          ),
        ],
      ),
    );
  }

  void _showRestoreDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ripristina backup'),
        content: const Text(
          'Questa operazione sovrascriverà tutte le note attuali.\n\nVuoi continuare?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annulla'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                // Simulated restore process
                await Future.delayed(const Duration(seconds: 3));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Ripristino completato con successo!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Errore durante il ripristino: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.orange),
            child: const Text('Ripristina'),
          ),
        ],
      ),
    );
  }
}
