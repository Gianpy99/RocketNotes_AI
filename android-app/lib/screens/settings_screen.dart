// Settings Screen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../main_simple.dart';

final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  return SettingsNotifier();
});

class AppSettings {
  final bool darkMode;
  final String defaultMode;
  final bool enableAI;
  final bool autoSave;

  AppSettings({
    this.darkMode = false,
    this.defaultMode = 'personal',
    this.enableAI = true,
    this.autoSave = true,
  });

  AppSettings copyWith({
    bool? darkMode,
    String? defaultMode,
    bool? enableAI,
    bool? autoSave,
  }) {
    return AppSettings(
      darkMode: darkMode ?? this.darkMode,
      defaultMode: defaultMode ?? this.defaultMode,
      enableAI: enableAI ?? this.enableAI,
      autoSave: autoSave ?? this.autoSave,
    );
  }
}

class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsNotifier() : super(AppSettings());

  void toggleDarkMode() {
    state = state.copyWith(darkMode: !state.darkMode);
  }

  void setDefaultMode(String mode) {
    state = state.copyWith(defaultMode: mode);
  }

  void toggleAI() {
    state = state.copyWith(enableAI: !state.enableAI);
  }

  void toggleAutoSave() {
    state = state.copyWith(autoSave: !state.autoSave);
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

          const SizedBox(height: 24),

          // About
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
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Tutte le note sono state eliminate'),
                    backgroundColor: Colors.red,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Errore durante l\'eliminazione: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Elimina tutto'),
          ),
        ],
      ),
    );
  }
}
