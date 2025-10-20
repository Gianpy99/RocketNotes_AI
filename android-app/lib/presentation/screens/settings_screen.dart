// lib/presentation/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_constants.dart';
import '../../data/services/nfc_service.dart';
import '../providers/app_providers.dart';
import '../../features/rocketbook/ai_analysis/ai_service.dart';
import '../../features/family/services/biometric_auth_service.dart';
import 'cost_monitoring_screen.dart';

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

          // OCR Engine Section
          _buildSectionHeader('OCR Engine'),
          Card(
            child: Column(
              children: [
                Consumer(
                  builder: (context, ref, child) {
                    return ref.watch(appSettingsProvider).when(
                      data: (settings) => ListTile(
                        leading: const Icon(Icons.text_fields),
                        title: const Text('OCR Engine'),
                        subtitle: Text(_getOCRProviderName(settings.effectiveOcrProvider)),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () => _showOCRProviderDialog(),
                      ),
                      loading: () => const ListTile(
                        leading: Icon(Icons.text_fields),
                        title: Text('OCR Engine'),
                        subtitle: Text('Loading...'),
                      ),
                      error: (_, __) => const ListTile(
                        leading: Icon(Icons.text_fields),
                        title: Text('OCR Engine'),
                        subtitle: Text('Error loading settings'),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // AI Configuration Section
          _buildSectionHeader('AI Configuration'),
          Card(
            child: Column(
              children: [
                // Toggle: Auto AI after OCR in Quick Capture
                Consumer(
                  builder: (context, ref, child) {
                    return ref.watch(appSettingsProvider).when(
                      data: (settings) => SwitchListTile(
                        secondary: const Icon(Icons.flash_on),
                        title: const Text('Auto-analisi AI in Quick Capture'),
                        subtitle: const Text('Esegui automaticamente l\'analisi AI dopo l\'OCR'),
                        value: settings.autoQuickCaptureAI,
                        onChanged: (val) async {
                          await ref.read(appSettingsProvider.notifier).updateSettings(
                            settings.copyWith(autoQuickCaptureAI: val),
                          );
                        },
                      ),
                      loading: () => const ListTile(
                        leading: Icon(Icons.flash_on),
                        title: Text('Auto-analisi AI in Quick Capture'),
                        subtitle: Text('Loading...'),
                      ),
                      error: (_, __) => const SizedBox.shrink(),
                    );
                  },
                ),
                const Divider(),
                Consumer(
                  builder: (context, ref, child) {
                    return ref.watch(appSettingsProvider).when(
                      data: (settings) => ListTile(
                        leading: const Icon(Icons.smart_toy),
                        title: const Text('AI Provider'),
                        subtitle: Text(_getAIProviderName(settings.effectiveAiProvider)),
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
                        leading: const Icon(Icons.summarize),
                        title: const Text('Text Summarization Model'),
                        subtitle: Text(_getModelDisplayName(settings.effectiveTextSummarizationModel)),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () => _showTextSummarizationModelDialog(settings.effectiveAiProvider),
                      ),
                      loading: () => const ListTile(
                        leading: Icon(Icons.summarize),
                        title: Text('Text Summarization Model'),
                        subtitle: Text('Loading...'),
                      ),
                      error: (_, __) => const ListTile(
                        leading: Icon(Icons.summarize),
                        title: Text('Text Summarization Model'),
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
                        leading: const Icon(Icons.image_search),
                        title: const Text('Image Analysis Model'),
                        subtitle: Text(_getModelDisplayName(settings.effectiveImageAnalysisModel)),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () => _showImageAnalysisModelDialog(settings.effectiveAiProvider),
                      ),
                      loading: () => const ListTile(
                        leading: Icon(Icons.image_search),
                        title: Text('Image Analysis Model'),
                        subtitle: Text('Loading...'),
                      ),
                      error: (_, __) => const ListTile(
                        leading: Icon(Icons.image_search),
                        title: Text('Image Analysis Model'),
                        subtitle: Text('Error loading settings'),
                      ),
                    );
                  },
                ),
                const Divider(),
                // Audio Transcription Model
                Consumer(
                  builder: (context, ref, child) {
                    return ref.watch(appSettingsProvider).when(
                      data: (settings) => ListTile(
                        leading: const Icon(Icons.mic),
                        title: const Text('Audio Transcription Model'),
                        subtitle: Text(_getModelDisplayName(settings.effectiveAudioTranscriptionModel)),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () => _showAudioTranscriptionModelDialog(settings.effectiveAiProvider),
                      ),
                      loading: () => const ListTile(
                        leading: Icon(Icons.mic),
                        title: Text('Audio Transcription Model'),
                        subtitle: Text('Loading...'),
                      ),
                      error: (_, __) => const ListTile(
                        leading: Icon(Icons.mic),
                        title: Text('Audio Transcription Model'),
                        subtitle: Text('Error loading settings'),
                      ),
                    );
                  },
                ),
                const Divider(),
                // Cost Monitoring
                ListTile(
                  leading: const Icon(Icons.analytics_outlined),
                  title: const Text('Cost Monitoring'),
                  subtitle: const Text('Track API usage and costs'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CostMonitoringScreen(),
                      ),
                    );
                  },
                ),
                const Divider(),
                // OpenAI Service Tier option (only show for OpenAI provider)
                Consumer(
                  builder: (context, ref, child) {
                    return ref.watch(appSettingsProvider).when(
                      data: (settings) {
                        if (settings.effectiveAiProvider != 'openai') {
                          return const SizedBox.shrink(); // Hide for non-OpenAI providers
                        }
                        return ListTile(
                          leading: const Icon(Icons.speed),
                          title: const Text('OpenAI Service Tier'),
                          subtitle: Text(_getServiceTierDisplayName(settings.effectiveOpenAIServiceTier)),
                          trailing: const Icon(Icons.arrow_forward_ios),
                          onTap: () => _showServiceTierDialog(),
                        );
                      },
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Privacy & Security Section
          _buildSectionHeader('Privacy & Security'),
          Card(
            child: Column(
              children: [
                Consumer(
                  builder: (context, ref, child) {
                    return ref.watch(appSettingsProvider).when(
                      data: (settings) {
                        debugPrint('🔐 [SETTINGS] Rendering Biometric Lock toggle - value: ${settings.enableBiometric}');
                        return SwitchListTile(
                          secondary: const Icon(Icons.fingerprint),
                          title: const Text('Biometric Lock'),
                          subtitle: const Text('Require biometric authentication to open app'),
                          value: settings.enableBiometric,
                          onChanged: (value) async {
                            debugPrint('🔐 [SETTINGS] Biometric Lock toggle tapped - new value: $value');
                            await _toggleBiometricLock(value);
                          },
                        );
                      },
                      loading: () => const ListTile(
                        leading: Icon(Icons.fingerprint),
                        title: Text('Biometric Lock'),
                        subtitle: Text('Loading...'),
                      ),
                      error: (_, __) => const SizedBox.shrink(),
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
                  title: const Text('About Pensieve'),
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

          const SizedBox(height: 24),

          // Account Section
          _buildSectionHeader('Account'),
          Card(
            child: Column(
              children: [
                StreamBuilder<User?>(
                  stream: FirebaseAuth.instance.authStateChanges(),
                  builder: (context, snapshot) {
                    final user = snapshot.data;
                    
                    if (user == null) {
                      return ListTile(
                        leading: const Icon(Icons.person_outline),
                        title: const Text('Not logged in'),
                        subtitle: const Text('Tap to sign in'),
                        onTap: () => context.go('/login'),
                      );
                    }

                    // Load user data from Firestore
                    return StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('users')
                          .doc(user.uid)
                          .snapshots(),
                      builder: (context, userDoc) {
                        Map<String, dynamic>? userData;
                        if (userDoc.hasData) {
                          final doc = userDoc.data!;
                          userData = doc.data() as Map<String, dynamic>?;
                        }
                        final displayName = userData?['displayName'] ?? 
                                          user.displayName ?? 
                                          'User';
                        final email = user.email ?? 'No email';
                        final isAnonymous = user.isAnonymous;

                        return Column(
                          children: [
                            ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Theme.of(context).primaryColor,
                                child: Text(
                                  displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              title: Text(displayName),
                              subtitle: Text(isAnonymous ? 'Guest Account' : email),
                            ),
                            if (!isAnonymous) ...[
                              const Divider(),
                              ListTile(
                                leading: const Icon(Icons.edit_outlined),
                                title: const Text('Edit Profile'),
                                trailing: const Icon(Icons.arrow_forward_ios),
                                onTap: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Profile editing coming soon!'),
                                    ),
                                  );
                                },
                              ),
                            ],
                            const Divider(),
                            ListTile(
                              leading: Icon(
                                Icons.logout,
                                color: Theme.of(context).colorScheme.error,
                              ),
                              title: Text(
                                'Logout',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              ),
                              onTap: () => _showLogoutDialog(),
                            ),
                          ],
                        );
                      },
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

  Future<void> _toggleBiometricLock(bool enable) async {
    try {
      if (enable) {
        // Verify biometric capability before enabling - usa direttamente il service
        final biometricService = BiometricAuthService();
        final isAvailable = await biometricService.isBiometricAvailable();
        
        if (!isAvailable) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Biometric authentication not available on this device'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        // Authenticate before enabling
        final authenticated = await biometricService.authenticate(
          reason: 'Enable biometric lock',
        );
        
        if (!authenticated) {
          return; // User cancelled or failed authentication
        }
      }

      // Update settings
      final settingsAsync = ref.read(appSettingsProvider);
      if (settingsAsync.hasValue && settingsAsync.value != null) {
        await ref.read(appSettingsProvider.notifier).updateSettings(
          settingsAsync.value!.copyWith(enableBiometric: enable),
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(enable
                  ? 'Blocco biometrico abilitato'
                  : 'Blocco biometrico disabilitato'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error toggling biometric lock: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
                'How to use NFC tags with Pensieve:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              Text('1. Get programmable NFC tags'),
              SizedBox(height: 8),
              Text('2. Write these URLs to your tags:'),
              SizedBox(height: 8),
              Text('   • Work mode: pensieve://work'),
              Text('   • Personal mode: pensieve://personal'),
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
          gradient: LinearGradient(
            colors: [Colors.deepPurple, Colors.purpleAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.deepPurple.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(
          Icons.psychology, // Brain/mind icon perfect for Pensieve
          size: 32,
          color: Colors.white,
        ),
      ),
      children: [
        const SizedBox(height: 16),
        const Text(
          'Pensieve is an intelligent memory storage system that captures '
          'and organizes your thoughts, notes, and memories with AI assistance.',
          style: TextStyle(fontSize: 14),
        ),
        const SizedBox(height: 16),
        const Text(
          'Features:\n'
          '• Smart work/personal mode switching\n'
          '• NFC tag quick access\n'
          '• AI-powered note enhancement\n'
          '• Biometric security\n'
          '• Rocketbook scanning integration\n'
          '• Cloud sync with Firebase\n'
          '• Family sharing capabilities',
          style: TextStyle(fontSize: 13),
        ),
      ],
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  await FirebaseAuth.instance.signOut();
                  if (mounted) {
                    Navigator.of(context).pop();
                    context.go('/login');
                  }
                } catch (e) {
                  if (mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error logging out: $e')),
                    );
                  }
                }
              },
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }

  // OCR Engine Methods
  String _getOCRProviderName(String provider) {
    switch (provider) {
      case 'google_ml_kit':
        return 'Google ML Kit (Recommended)';
      case 'tesseract':
        return 'Tesseract OCR';
      default:
        return 'Unknown Engine';
    }
  }

  void _showOCRProviderDialog() {
    final ocrProviders = [
      {
        'id': 'google_ml_kit', 
        'name': 'Google ML Kit', 
        'description': 'Fast & accurate OCR engine (Recommended)'
      },
      {
        'id': 'tesseract', 
        'name': 'Tesseract OCR', 
        'description': 'Traditional open-source OCR'
      },
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select OCR Engine'),
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

  // AI Configuration Methods
  String _getAIProviderName(String provider) {
    switch (provider) {
      case 'openai':
        return 'OpenAI (GPT Models)';
      case 'gemini':
        return 'Google Gemini';
      case 'ollama':
        return 'Ollama Cloud (FREE!)';
      default:
        return 'Unknown Provider';
    }
  }

  String _getModelDisplayName(String model) {
    switch (model) {
      case 'gpt-4o':
        return 'GPT-4o (Latest)';
      case 'gpt-4-turbo':
        return 'GPT-4 Turbo';
      case 'gpt-4':
        return 'GPT-4';
      case 'gpt-3.5-turbo':
        return 'GPT-3.5 Turbo';
      case 'gpt-5':
        return 'GPT-5 (Latest)';
      case 'gpt-5-mini':
        return 'GPT-5 Mini';
      case 'gpt-5-nano':
        return 'GPT-5 Nano';
      case 'gpt-4o-mini-transcribe':
        return 'GPT-4o Mini Transcribe';
      case 'gpt-4o-transcribe':
        return 'GPT-4o Transcribe';
      case 'whisper':
        return 'Whisper';
      case 'gemini-pro':
        return 'Gemini Pro';
      case 'gemini-pro-vision':
        return 'Gemini Pro Vision';
      case 'gemini-2.5-flash':
        return 'Gemini 2.5 Flash';
      case 'gemini-2.5-flash-lite':
        return 'Gemini 2.5 Flash Lite';
      case 'gemini-2.5-flash-batch':
        return 'Gemini 2.5 Flash Batch';
      case 'gemini-2.5-flash-lite-batch':
        return 'Gemini 2.5 Flash Lite Batch';
      case 'gemini-2.5-flash-native-audio':
        return 'Gemini 2.5 Flash Native Audio';
      // Ollama Cloud models
      case 'deepseek-v3.1:671b-cloud':
        return 'DeepSeek V3.1 (671B Cloud)';
      case 'gpt-oss:120b-cloud':
        return 'GPT-OSS (120B Cloud)';
      case 'gpt-oss:20b-cloud':
        return 'GPT-OSS (20B Cloud)';
      case 'kimi-k2:1t-cloud':
        return 'Kimi K2 (1T Cloud)';
      case 'qwen3-coder:480b-cloud':
        return 'Qwen3 Coder (480B Cloud)';
      case 'glm-4.6:cloud':
        return 'GLM 4.6 (Cloud)';
      case 'llama3.2-vision:90b':
        return 'Llama 3.2 Vision (90B)';
      case 'gpt-oss:120b':
        return 'GPT-OSS (120B)';
      case 'llama3.1:70b':
        return 'Llama 3.1 (70B)';
      case 'mistral-nemo':
        return 'Mistral Nemo (12B)';
      default:
        return 'Unknown Model';
    }
  }

  void _showAIProviderDialog() {
    final aiProviders = [
      {
        'id': 'openai', 
        'name': 'OpenAI', 
        'description': 'GPT-4o, GPT-4 Turbo, and GPT-3.5 models'
      },
      {
        'id': 'gemini', 
        'name': 'Google Gemini', 
        'description': 'Gemini Pro and Gemini Pro Vision'
      },
      {
        'id': 'ollama', 
        'name': 'Ollama Cloud (FREE!)', 
        'description': 'GPT-OSS 120B, Llama 3.2 Vision 90B, DeepSeek V3.1 671B'
      },
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
                  
                  // Reinitialize AIService with new provider settings
                  try {
                    await AIService.instance.initialize();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('AI Provider changed to ${provider['name']}')),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Warning: ${e.toString()}'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    }
                  }
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

  void _showTextSummarizationModelDialog(String provider) async {
    final settingsAsync = ref.read(appSettingsProvider);
    final settings = settingsAsync.maybeWhen(
      data: (settings) => settings,
      orElse: () => null,
    );
    
    final tier = provider == 'openai' && settings != null ? settings.effectiveOpenAIServiceTier : 'standard';
    final models = AIModelConfig.getModelsForProvider(provider, tier: tier);
    
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Text Summarization Model'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: models.length,
            itemBuilder: (context, index) {
              final model = models[index];
              return ListTile(
                title: Row(
                  children: [
                    Expanded(child: Text(model['name'])),
                    if (model['inputPrice'] != null) 
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getCategoryColor(model['category']),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '\$${model['inputPrice'].toStringAsFixed(2)}/1M',
                          style: const TextStyle(
                            fontSize: 10, 
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                subtitle: Text(model['description'] ?? ''),
                onTap: () async {
                  Navigator.of(context).pop();
                  await ref.read(settingsRepositoryProvider).updateTextSummarizationModel(model['id']);
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

  void _showImageAnalysisModelDialog(String provider) async {
    final settingsAsync = ref.read(appSettingsProvider);
    final settings = settingsAsync.maybeWhen(
      data: (settings) => settings,
      orElse: () => null,
    );
    
    final tier = provider == 'openai' && settings != null ? settings.effectiveOpenAIServiceTier : 'standard';
    final allModels = AIModelConfig.getModelsForProvider(provider, tier: tier);
    final models = allModels.where((m) => m['supportsVision'] == true).toList();
    
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Image Analysis Model'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: models.length,
            itemBuilder: (context, index) {
              final model = models[index];
              return ListTile(
                title: Row(
                  children: [
                    Expanded(child: Text(model['name'])),
                    if (model['inputPrice'] != null) 
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getCategoryColor(model['category']),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '\$${model['inputPrice'].toStringAsFixed(2)}/1M',
                          style: const TextStyle(
                            fontSize: 10, 
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                subtitle: Text(model['description'] ?? ''),
                onTap: () async {
                  Navigator.of(context).pop();
                  await ref.read(settingsRepositoryProvider).updateImageAnalysisModel(model['id']);
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

  void _showAudioTranscriptionModelDialog(String provider) async {
    final models = AIModelConfig.getAudioModelsForProvider(provider);
    
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Audio Transcription Model'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: models.length,
            itemBuilder: (context, index) {
              final model = models[index];
              return ListTile(
                title: Row(
                  children: [
                    Expanded(child: Text(model['name'])),
                    if (model['estimatedCostPerMinute'] != null) 
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getCategoryColor(model['category']),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '\$${model['estimatedCostPerMinute'].toStringAsFixed(3)}/min',
                          style: const TextStyle(
                            fontSize: 10, 
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    else if (model['costPerMinute'] != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getCategoryColor(model['category']),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '\$${model['costPerMinute'].toStringAsFixed(3)}/min',
                          style: const TextStyle(
                            fontSize: 10, 
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                subtitle: Text(model['description'] ?? ''),
                onTap: () async {
                  Navigator.of(context).pop();
                  await ref.read(settingsRepositoryProvider).updateAudioTranscriptionModel(model['id']);
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

  // Helper method to get category colors for price badges
  Color _getCategoryColor(String? category) {
    switch (category) {
      case 'premium':
        return Colors.purple;
      case 'balanced':
        return Colors.blue;
      case 'economical':
        return Colors.green;
      case 'reasoning':
        return Colors.orange;
      case 'standard':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  // Service Tier helper methods
  String _getServiceTierDisplayName(String serviceTier) {
    switch (serviceTier) {
      case 'flex':
        return 'Flex (Best Value)';
      case 'standard':
        return 'Standard';
      case 'priority':
        return 'Priority (Fastest)';
      default:
        return 'Flex (Best Value)';
    }
  }

  void _showServiceTierDialog() {
    final tiers = [
      {
        'id': 'flex',
        'name': 'Flex (Best Value)',
        'description': 'Best cost/performance ratio - GPT-5 access at lower prices'
      },
      {
        'id': 'standard',
        'name': 'Standard',
        'description': 'Standard processing speed and quality'
      },
      {
        'id': 'priority',
        'name': 'Priority (Fastest)',
        'description': 'Faster responses at higher cost'
      },
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select OpenAI Service Tier'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: tiers.length,
            itemBuilder: (context, index) {
              final tier = tiers[index];
              return ListTile(
                title: Text(tier['name']!),
                subtitle: Text(tier['description']!),
                onTap: () async {
                  Navigator.of(context).pop();
                  await ref.read(settingsRepositoryProvider).updateOpenAIServiceTier(tier['id']!);
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
