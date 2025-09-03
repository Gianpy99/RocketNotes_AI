// lib/ui/widgets/settings/ai_settings.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import 'package:dio/dio.dart';
import '../../../screens/settings_screen.dart' as settings_lib;

class AISettings extends ConsumerStatefulWidget {
  const AISettings({super.key});

  @override
  ConsumerState<AISettings> createState() => _AISettingsState();
}

class _AISettingsState extends ConsumerState<AISettings> {
  final _apiKeyController = TextEditingController();
  bool _isTestingConnection = false;
  bool _connectionTested = false;
  bool _connectionSuccess = false;

  @override
  void initState() {
    super.initState();
    _loadApiKey();
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  void _loadApiKey() {
    final appSettings = ref.read(settings_lib.settingsProvider);
    _apiKeyController.text = appSettings.aiApiKey;
  }

  Future<void> _testConnection() async {
    if (_apiKeyController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter an API key first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isTestingConnection = true;
      _connectionTested = false;
    });

    try {
      // Test the API connection using a direct HTTP call
      final testApiKey = _apiKeyController.text.trim();

      // Create a Dio instance for testing
      final dio = Dio();
      dio.options.headers = {
        'Authorization': 'Bearer $testApiKey',
        'Content-Type': 'application/json',
      };

      // Test connection by calling the models endpoint
      final response = await dio.get('https://api.openai.com/v1/models');

      if (response.statusCode == 200) {
        setState(() {
          _connectionSuccess = true;
          _connectionTested = true;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ API connection successful!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception('API returned status code: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _connectionSuccess = false;
        _connectionTested = true;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Connection failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isTestingConnection = false;
      });
    }
  }

  void _saveApiKey() {
    ref.read(settings_lib.settingsProvider.notifier).setAiApiKey(_apiKeyController.text.trim());
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('API key saved'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appSettings = ref.watch(settings_lib.settingsProvider);
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode 
          ? AppColors.surfaceDark.withValues(alpha: 0.7)
          : AppColors.surfaceLight.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDarkMode 
            ? AppColors.textSecondaryDark.withValues(alpha: 0.2)
            : AppColors.textSecondaryLight.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.auto_awesome,
                color: AppColors.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'AI Assistant Settings',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Enable AI Toggle
          _SettingsTile(
            title: 'Enable AI Assistant',
            subtitle: 'Get intelligent suggestions and improvements',
            trailing: Switch(
              value: appSettings.aiEnabled,
              onChanged: (value) {
                ref.read(settings_lib.settingsProvider.notifier).setAiEnabled(value);
              },
              activeThumbColor: AppColors.primary,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // AI Provider Selection
          _SettingsTile(
            title: 'AI Provider',
            subtitle: 'Choose your preferred AI service',
            trailing: DropdownButton<String>(
              value: appSettings.aiProvider,
              items: const [
                DropdownMenuItem(value: 'openai', child: Text('OpenAI')),
                DropdownMenuItem(value: 'gemini', child: Text('Google Gemini')),
                DropdownMenuItem(value: 'claude', child: Text('Anthropic Claude')),
              ],
              onChanged: (value) {
                if (value != null) {
                  ref.read(settings_lib.settingsProvider.notifier).setAiProvider(value);
                }
              },
              underline: const SizedBox(),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // API Key Configuration
          Text(
            'API Configuration',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          
          TextField(
            controller: _apiKeyController,
            decoration: InputDecoration(
              labelText: 'API Key',
              hintText: 'Enter your AI service API key',
              prefixIcon: const Icon(Icons.key_rounded),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_connectionTested)
                    Icon(
                      _connectionSuccess 
                        ? Icons.check_circle_rounded
                        : Icons.error_rounded,
                      color: _connectionSuccess ? Colors.green : Colors.red,
                      size: 20,
                    ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _saveApiKey,
                    icon: const Icon(Icons.save_rounded),
                    tooltip: 'Save API Key',
                  ),
                ],
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            obscureText: true,
            onChanged: (_) {
              setState(() {
                _connectionTested = false;
              });
            },
          ),
          
          const SizedBox(height: 12),
          
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _isTestingConnection ? null : _testConnection,
              icon: _isTestingConnection
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.wifi_rounded),
              label: Text(_isTestingConnection ? 'Testing...' : 'Test Connection'),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // AI Features
          Text(
            'AI Features',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          
          _FeatureTile(
            title: 'Smart Suggestions',
            subtitle: 'Get writing suggestions while typing',
            enabled: appSettings.aiSmartSuggestions,
            onChanged: (value) {
              ref.read(settings_lib.settingsProvider.notifier).setAiSmartSuggestions(value);
            },
          ),
          
          const SizedBox(height: 8),
          
          _FeatureTile(
            title: 'Auto Tag Generation',
            subtitle: 'Automatically suggest relevant tags',
            enabled: appSettings.aiAutoTags,
            onChanged: (value) {
              ref.read(settings_lib.settingsProvider.notifier).setAiAutoTags(value);
            },
          ),
          
          const SizedBox(height: 8),
          
          _FeatureTile(
            title: 'Grammar Correction',
            subtitle: 'Detect and suggest grammar fixes',
            enabled: appSettings.aiGrammarCheck,
            onChanged: (value) {
              ref.read(settings_lib.settingsProvider.notifier).setAiGrammarCheck(value);
            },
          ),
          
          const SizedBox(height: 8),
          
          _FeatureTile(
            title: 'Content Enhancement',
            subtitle: 'Suggest content improvements',
            enabled: appSettings.aiContentEnhancement,
            onChanged: (value) {
              ref.read(settings_lib.settingsProvider.notifier).setAiContentEnhancement(value);
            },
          ),
          
          const SizedBox(height: 20),
          
          // Privacy Notice
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.blue.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  color: Colors.blue,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Privacy Notice',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Your note content is sent to the selected AI service for processing. '
                        'Please review the privacy policy of your chosen AI provider.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget trailing;

  const _SettingsTile({
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDarkMode 
          ? Colors.grey[800]?.withValues(alpha: 0.3)
          : Colors.grey[100]?.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDarkMode 
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  const _FeatureTile({
    required this.title,
    required this.subtitle,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDarkMode 
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: enabled,
            onChanged: onChanged,
            activeThumbColor: AppColors.primary,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }
}
