// lib/presentation/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../data/services/nfc_service.dart';
import '../providers/app_providers.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final NfcService _nfcService = NfcService();
  bool _isNfcAvailable = false;

  @override
  void initState() {
    super.initState();
    _checkNfcAvailability();
  }

  Future<void> _checkNfcAvailability() async {
    try {
      final availability = await _nfcService.checkAvailability();
      setState(() {
        _isNfcAvailable = availability.toString().contains('available');
      });
    } catch (e) {
      setState(() {
        _isNfcAvailable = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final currentMode = ref.watch(appModeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // App Info Section
          _buildSectionHeader('App Information'),
          Card(
            child: Column(
              children: [
                const ListTile(
                  leading: Icon(Icons.rocket_launch),
                  title: Text(AppConstants.appName),
                  subtitle: Text('Version ${AppConstants.appVersion}'),
                ),
                const Divider(),
                ListTile(
                  leading: Icon(
                    currentMode == 'work' ? Icons.work : Icons.home,
                    color: currentMode == 'work'
                        ? Colors.blue
                        : Colors.green,
                  ),
                  title: const Text('Current Mode'),
                  subtitle: Text('${currentMode.toUpperCase()} MODE'),
                  trailing: Switch(
                    value: currentMode == 'work',
                    onChanged: (value) {
                      ref.read(appModeProvider.notifier).setMode(
                        value ? 'work' : 'personal',
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Appearance Section
          _buildSectionHeader('Appearance'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.palette),
                  title: const Text('Theme'),
                  subtitle: Text(_getThemeModeText(themeMode)),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () => _showThemeDialog(),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // NFC Section
          _buildSectionHeader('NFC Settings'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(
                    Icons.nfc,
                    color: _isNfcAvailable ? Colors.green : Colors.grey,
                  ),
                  title: const Text('NFC Status'),
                  subtitle: Text(
                    _isNfcAvailable 
                        ? 'Available - Tap NFC tags to switch modes'
                        : 'Not available on this device',
                  ),
                  trailing: _isNfcAvailable
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : const Icon(Icons.cancel, color: Colors.grey),
                ),
                if (_isNfcAvailable) ...[
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.help_outline),
                    title: const Text('NFC Instructions'),
                    subtitle: const Text('Learn how to use NFC tags'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () => _showNfcInstructions(),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Data Section
          _buildSectionHeader('Data Management'),
          Card(
            child: Column(
              children: [
                Consumer(
                  builder: (context, ref, child) {
                    return ref.watch(notesProvider).when(
                      data: (notes) => ListTile(
                        leading: const Icon(Icons.storage),
                        title: const Text('Notes Count'),
                        subtitle: Text('${notes.length} notes stored locally'),
                        trailing: Text(
                          '${notes.where((n) => n.mode == 'work').length}W / ${notes.where((n) => n.mode == 'personal').length}P',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                      loading: () => const ListTile(
                        leading: Icon(Icons.storage),
                        title: Text('Notes Count'),
                        subtitle: Text('Loading...'),
                      ),
                      error: (_, __) => const ListTile(
                        leading: Icon(Icons.storage),
                        title: Text('Notes Count'),
                        subtitle: Text('Error loading notes'),
                      ),
                    );
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.delete_sweep, color: Colors.red),
                  title: const Text('Clear All Data'),
                  subtitle: const Text('This action cannot be undone'),
                  onTap: () => _showClearDataDialog(),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // OCR Settings Section
          _buildSectionHeader('OCR Settings'),
          Card(
            child: Column(
              children: [
                Consumer(
                  builder: (context, ref, child) {
                    return ref.watch(appSettingsProvider).when(
                      data: (settings) => ListTile(
                        leading: const Icon(Icons.text_fields),
                        title: const Text('OCR Provider'),
                        subtitle: Text(_getOCRProviderName(settings.ocrProvider)),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () => _showOCRProviderDialog(),
                      ),
                      loading: () => const ListTile(
                        leading: Icon(Icons.text_fields),
                        title: Text('OCR Provider'),
                        subtitle: Text('Loading...'),
                      ),
                      error: (_, __) => const ListTile(
                        leading: Icon(Icons.text_fields),
                        title: Text('OCR Provider'),
                        subtitle: Text('Error loading settings'),
                      ),
                    );
                  },
                ),
                const Divider(),
                Consumer(
                  builder: (context, ref, child) {
                    return ref.watch(appSettingsProvider).when(
                      data: (settings) => ListTile(
                        leading: const Icon(Icons.memory),
                        title: const Text('OCR Model'),
                        subtitle: Text(_getOCRModelName(settings.ocrModel)),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () => _showOCRModelDialog(settings.ocrProvider),
                      ),
                      loading: () => const ListTile(
                        leading: Icon(Icons.memory),
                        title: Text('OCR Model'),
                        subtitle: Text('Loading...'),
                      ),
                      error: (_, __) => const ListTile(
                        leading: Icon(Icons.memory),
                        title: Text('OCR Model'),
                        subtitle: Text('Error loading settings'),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // AI Settings Section
          _buildSectionHeader('AI Settings'),
          Card(
            child: Column(
              children: [
                Consumer(
                  builder: (context, ref, child) {
                    return ref.watch(appSettingsProvider).when(
                      data: (settings) => ListTile(
                        leading: const Icon(Icons.smart_toy),
                        title: const Text('AI Provider'),
                        subtitle: Text(_getAIProviderName(settings.aiProvider)),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () => _showAIProviderDialog(),
                      ),
                      loading: () => const ListTile(
                        leading: Icon(Icons.smart_toy),
                        title: Text('AI Provider'),
                        subtitle: Text('Loading...'),
                      ),
                      error: (_, __) => const ListTile(
                        leading: Icon(Icons.smart_toy),
                        title: Text('AI Provider'),
                        subtitle: Text('Error loading settings'),
                      ),
                    );
                  },
                ),
                const Divider(),
                Consumer(
                  builder: (context, ref, child) {
                    return ref.watch(appSettingsProvider).when(
                      data: (settings) => ListTile(
                        leading: const Icon(Icons.psychology),
                        title: const Text('AI Model'),
                        subtitle: Text(_getAIModelName(settings.aiModel)),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () => _showAIModelDialog(settings.aiProvider),
                      ),
                      loading: () => const ListTile(
                        leading: Icon(Icons.psychology),
                        title: Text('AI Model'),
                        subtitle: Text('Loading...'),
                      ),
                      error: (_, __) => const ListTile(
                        leading: Icon(Icons.psychology),
                        title: Text('AI Model'),
                        subtitle: Text('Error loading settings'),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // About Section
          _buildSectionHeader('About'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('About RocketNotes AI'),
                  subtitle: const Text('Smart note-taking with NFC switching'),
                  onTap: () => _showAboutDialog(),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.feedback_outlined),
                  title: const Text('Send Feedback'),
                  subtitle: const Text('Help us improve the app'),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Feedback feature coming soon!'),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
  }

  String _getThemeModeText(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System';
    }
  }

  void _showThemeDialog() {
    showDialog(
      context: context,
      builder: (context) => const AlertDialog(
        title: Text('Choose Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<ThemeMode>(
              title: Text('Light'),
              value: ThemeMode.light,
            ),
            RadioListTile<ThemeMode>(
              title: Text('Dark'),
              value: ThemeMode.dark,
            ),
            RadioListTile<ThemeMode>(
              title: Text('System'),
              value: ThemeMode.system,
            ),
          ],
        ),
      ),
    );
  }

  void _showNfcInstructions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('NFC Instructions'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'How to use NFC tags with RocketNotes:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              Text('1. Get programmable NFC tags'),
              SizedBox(height: 8),
              Text('2. Write these URLs to your tags:'),
              SizedBox(height: 8),
              Text('   • Work mode: rocketnotes://work'),
              Text('   • Personal mode: rocketnotes://personal'),
              SizedBox(height: 16),
              Text('3. Tap the NFC tag with your phone to quickly switch modes'),
              SizedBox(height: 16),
              Text(
                'Tip: Place work tags at your office and personal tags at home!',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  void _showClearDataDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data'),
        content: const Text(
          'This will permanently delete all your notes and settings. '
          'This action cannot be undone. Are you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await ref.read(notesProvider.notifier).clearAllNotes();
              if (context.mounted) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('All data cleared'),
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showAboutDialog(
      context: context,
      applicationName: AppConstants.appName,
      applicationVersion: AppConstants.appVersion,
      applicationIcon: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.rocket_launch,
          size: 32,
          color: Colors.white,
        ),
      ),
      children: [
        const SizedBox(height: 16),
        const Text(
          'RocketNotes AI is a smart note-taking app that uses NFC tags '
          'to quickly switch between work and personal modes.',
        ),
        const SizedBox(height: 16),
        const Text(
          'Features:\n'
          '• Work/Personal mode switching\n'
          '• NFC tag integration\n'
          '• AI-powered note enhancement\n'
          '• Local storage with sync\n'
          '• Dark/Light theme support',
        ),
      ],
    );
  }

  // OCR Settings Methods
  String _getOCRProviderName(String provider) {
    switch (provider) {
      case 'trocr-handwritten':
        return 'TrOCR Handwritten';
      case 'trocr-printed':
        return 'TrOCR Printed';
      case 'tesseract':
        return 'Tesseract OCR';
      default:
        return 'Unknown Provider';
    }
  }

  String _getOCRModelName(String model) {
    switch (model) {
      case 'microsoft/trocr-base-handwritten':
        return 'TrOCR Base Handwritten';
      case 'microsoft/trocr-large-handwritten':
        return 'TrOCR Large Handwritten';
      case 'microsoft/trocr-base-printed':
        return 'TrOCR Base Printed';
      case 'microsoft/trocr-large-printed':
        return 'TrOCR Large Printed';
      case 'tesseract-ocr':
        return 'Tesseract Default';
      default:
        return 'Unknown Model';
    }
  }

  void _showOCRProviderDialog() {
    final ocrProviders = [
      {'id': 'trocr-handwritten', 'name': 'TrOCR Handwritten', 'description': 'Best for handwritten text'},
      {'id': 'trocr-printed', 'name': 'TrOCR Printed', 'description': 'Best for printed text'},
      {'id': 'tesseract', 'name': 'Tesseract OCR', 'description': 'Traditional OCR (local)'},
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select OCR Provider'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: ocrProviders.length,
            itemBuilder: (context, index) {
              final provider = ocrProviders[index];
              return ListTile(
                title: Text(provider['name']!),
                subtitle: Text(provider['description']!),
                onTap: () async {
                  Navigator.of(context).pop();
                  await ref.read(settingsRepositoryProvider).updateOcrProvider(provider['id']!);
                  ref.invalidate(appSettingsProvider);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showOCRModelDialog(String provider) {
    List<Map<String, String>> models;
    
    switch (provider) {
      case 'trocr-handwritten':
        models = [
          {'id': 'microsoft/trocr-base-handwritten', 'name': 'TrOCR Base Handwritten'},
          {'id': 'microsoft/trocr-large-handwritten', 'name': 'TrOCR Large Handwritten'},
        ];
        break;
      case 'trocr-printed':
        models = [
          {'id': 'microsoft/trocr-base-printed', 'name': 'TrOCR Base Printed'},
          {'id': 'microsoft/trocr-large-printed', 'name': 'TrOCR Large Printed'},
        ];
        break;
      case 'tesseract':
        models = [
          {'id': 'tesseract-ocr', 'name': 'Tesseract Default'},
        ];
        break;
      default:
        models = [];
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select OCR Model'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: models.length,
            itemBuilder: (context, index) {
              final model = models[index];
              return ListTile(
                title: Text(model['name']!),
                onTap: () async {
                  Navigator.of(context).pop();
                  await ref.read(settingsRepositoryProvider).updateOcrModel(model['id']!);
                  ref.invalidate(appSettingsProvider);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  // AI Settings Methods
  String _getAIProviderName(String provider) {
    switch (provider) {
      case 'openai':
        return 'OpenAI';
      case 'gemini':
        return 'Google Gemini';
      case 'huggingface':
        return 'HuggingFace';
      case 'mock':
        return 'Mock AI (Testing)';
      default:
        return 'Unknown Provider';
    }
  }

  String _getAIModelName(String model) {
    switch (model) {
      case 'gpt-4-turbo-preview':
        return 'GPT-4 Turbo Preview';
      case 'gpt-4':
        return 'GPT-4';
      case 'gpt-3.5-turbo':
        return 'GPT-3.5 Turbo';
      case 'gemini-pro':
        return 'Gemini Pro';
      case 'gemini-pro-vision':
        return 'Gemini Pro Vision';
      case 'mistralai/Mistral-7B-Instruct-v0.1':
        return 'Mistral 7B Instruct';
      case 'meta-llama/Llama-2-7b-chat-hf':
        return 'Llama 2 7B Chat';
      case 'google/flan-t5-large':
        return 'FLAN-T5 Large';
      default:
        return 'Unknown Model';
    }
  }

  void _showAIProviderDialog() {
    final aiProviders = [
      {'id': 'openai', 'name': 'OpenAI', 'description': 'GPT-4 and GPT-3.5 models'},
      {'id': 'gemini', 'name': 'Google Gemini', 'description': 'Google\'s AI models'},
      {'id': 'huggingface', 'name': 'HuggingFace', 'description': 'Open source models'},
      {'id': 'mock', 'name': 'Mock AI', 'description': 'For testing (no API required)'},
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select AI Provider'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: aiProviders.length,
            itemBuilder: (context, index) {
              final provider = aiProviders[index];
              return ListTile(
                title: Text(provider['name']!),
                subtitle: Text(provider['description']!),
                onTap: () async {
                  Navigator.of(context).pop();
                  await ref.read(settingsRepositoryProvider).updateAiProvider(provider['id']!);
                  ref.invalidate(appSettingsProvider);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showAIModelDialog(String provider) {
    List<Map<String, String>> models;
    
    switch (provider) {
      case 'openai':
        models = [
          {'id': 'gpt-4-turbo-preview', 'name': 'GPT-4 Turbo Preview'},
          {'id': 'gpt-4', 'name': 'GPT-4'},
          {'id': 'gpt-3.5-turbo', 'name': 'GPT-3.5 Turbo'},
        ];
        break;
      case 'gemini':
        models = [
          {'id': 'gemini-pro', 'name': 'Gemini Pro'},
          {'id': 'gemini-pro-vision', 'name': 'Gemini Pro Vision'},
        ];
        break;
      case 'huggingface':
        models = [
          {'id': 'mistralai/Mistral-7B-Instruct-v0.1', 'name': 'Mistral 7B Instruct'},
          {'id': 'meta-llama/Llama-2-7b-chat-hf', 'name': 'Llama 2 7B Chat'},
          {'id': 'google/flan-t5-large', 'name': 'FLAN-T5 Large'},
        ];
        break;
      default:
        models = [];
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select AI Model'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: models.length,
            itemBuilder: (context, index) {
              final model = models[index];
              return ListTile(
                title: Text(model['name']!),
                onTap: () async {
                  Navigator.of(context).pop();
                  await ref.read(settingsRepositoryProvider).updateAiModel(model['id']!);
                  ref.invalidate(appSettingsProvider);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}
