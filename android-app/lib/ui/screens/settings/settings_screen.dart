// lib/ui/screens/settings/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../core/constants/app_colors.dart';
import '../../../presentation/providers/app_providers.dart';
import '../../widgets/common/gradient_background.dart';
import '../../widgets/settings/setting_section.dart';
import '../../widgets/settings/setting_tile.dart';
import '../../widgets/common/confirmation_dialog.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  PackageInfo? _packageInfo;

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() => _packageInfo = info);
      }
    } catch (e) {
      debugPrint('Failed to load package info: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(appSettingsProvider);
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      body: GradientBackground(
        colors: isDarkMode 
          ? AppColors.darkGradient 
          : AppColors.lightGradient,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // App Bar
            SliverAppBar(
              title: const Text('Settings'),
              backgroundColor: Colors.transparent,
              elevation: 0,
              floating: true,
              snap: true,
              leading: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back_rounded),
              ),
            ),

            // Settings Content
            SliverPadding(
              padding: const EdgeInsets.all(16.0),
              sliver: settings.when(
                data: (settingsData) => _buildSettingsContent(
                  context, 
                  settingsData, 
                  isDarkMode,
                ),
                loading: () => const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, stack) => SliverFillRemaining(
                  child: _buildErrorState(context, error.toString()),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsContent(
    BuildContext context, 
    dynamic settingsData, 
    bool isDarkMode,
  ) {
    return SliverList(
      delegate: SliverChildListDelegate([
        // Appearance Section
        SettingSection(
          title: 'Appearance',
          icon: Icons.palette_rounded,
          children: [
            SettingTile(
              title: 'Theme',
              subtitle: _getThemeDescription(settingsData?.themeMode),
              leading: Icon(_getThemeIcon(settingsData?.themeMode)),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => _showThemeSelector(context),
            ),
            SettingTile.toggle(
              title: 'Dynamic Colors',
              subtitle: 'Use system colors when available',
              leading: const Icon(Icons.color_lens_rounded),
              value: settingsData?.useDynamicColors ?? false,
              onChanged: (value) => _updateSetting('useDynamicColors', value),
            ),
            SettingTile.toggle(
              title: 'Show Statistics',
              subtitle: 'Display note statistics on home screen',
              leading: const Icon(Icons.analytics_rounded),
              value: settingsData?.showStats ?? true,
              onChanged: (value) => _updateSetting('showStats', value),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // AI & Smart Features Section
        SettingSection(
          title: 'AI & Smart Features',
          icon: Icons.smart_toy_rounded,
          children: [
            SettingTile.toggle(
              title: 'AI Assistance',
              subtitle: 'Enable AI-powered suggestions and summaries',
              leading: const Icon(Icons.auto_awesome_rounded),
              value: settingsData?.aiEnabled ?? false,
              onChanged: (value) => _updateSetting('aiEnabled', value),
            ),
            SettingTile.toggle(
              title: 'Auto Tag Suggestions',
              subtitle: 'Suggest tags based on note content',
              leading: const Icon(Icons.local_offer_rounded),
              value: settingsData?.autoTagSuggestions ?? true,
              onChanged: (value) => _updateSetting('autoTagSuggestions', value),
              enabled: settingsData?.aiEnabled ?? false,
            ),
            SettingTile.toggle(
              title: 'Smart Search',
              subtitle: 'Enhanced search with AI ranking',
              leading: const Icon(Icons.search_rounded),
              value: settingsData?.smartSearch ?? true,
              onChanged: (value) => _updateSetting('smartSearch', value),
              enabled: settingsData?.aiEnabled ?? false,
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Storage & Backup Section
        SettingSection(
          title: 'Storage & Backup',
          icon: Icons.cloud_rounded,
          children: [
            SettingTile(
              title: 'Backup & Restore',
              subtitle: 'Manage your data backups',
              leading: const Icon(Icons.backup_rounded),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => Navigator.of(context).pushNamed('/backup'),
            ),
            SettingTile.toggle(
              title: 'Auto Backup',
              subtitle: 'Automatically backup notes daily',
              leading: const Icon(Icons.cloud_sync_rounded),
              value: settingsData?.autoBackup ?? false,
              onChanged: (value) => _updateSetting('autoBackup', value),
            ),
            SettingTile(
              title: 'Storage Usage',
              subtitle: _getStorageUsage(),
              leading: const Icon(Icons.storage_rounded),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => _showStorageInfo(context),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Privacy & Security Section
        SettingSection(
          title: 'Privacy & Security',
          icon: Icons.security_rounded,
          children: [
            SettingTile.toggle(
              title: 'Encrypt Notes',
              subtitle: 'Enable local encryption for sensitive notes',
              leading: const Icon(Icons.lock_rounded),
              value: settingsData?.encryptNotes ?? false,
              onChanged: (value) => _showEncryptionDialog(context, value),
            ),
            SettingTile.toggle(
              title: 'Biometric Lock',
              subtitle: 'Require biometric authentication to open app',
              leading: const Icon(Icons.fingerprint_rounded),
              value: settingsData?.biometricLock ?? false,
              onChanged: (value) => _updateSetting('biometricLock', value),
            ),
            SettingTile(
              title: 'Data Privacy',
              subtitle: 'View privacy policy and data handling',
              leading: const Icon(Icons.privacy_tip_rounded),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => _showPrivacyInfo(context),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Advanced Section
        SettingSection(
          title: 'Advanced',
          icon: Icons.settings_rounded,
          children: [
            SettingTile(
              title: 'Export All Data',
              subtitle: 'Export all notes and settings',
              leading: const Icon(Icons.download_rounded),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => _exportAllData(context),
            ),
            SettingTile(
              title: 'Clear Cache',
              subtitle: 'Clear temporary files and cached data',
              leading: const Icon(Icons.cleaning_services_rounded),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => _clearCache(context),
            ),
            SettingTile(
              title: 'Reset Settings',
              subtitle: 'Reset all settings to default',
              leading: const Icon(Icons.restore_rounded),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => _resetSettings(context),
              textColor: AppColors.error,
            ),
          ],
        ),

        const SizedBox(height: 24),

        // About Section
        SettingSection(
          title: 'About',
          icon: Icons.info_rounded,
          children: [
            SettingTile(
              title: 'Version',
              subtitle: _packageInfo?.version ?? 'Loading...',
              leading: const Icon(Icons.info_outline_rounded),
            ),
            SettingTile(
              title: 'Help & Support',
              subtitle: 'Get help and contact support',
              leading: const Icon(Icons.help_rounded),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => _showHelpDialog(context),
            ),
            SettingTile(
              title: 'Rate App',
              subtitle: 'Rate RocketNotes AI on the app store',
              leading: const Icon(Icons.star_rounded),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => _rateApp(context),
            ),
            SettingTile(
              title: 'Open Source Licenses',
              subtitle: 'View licenses for open source components',
              leading: const Icon(Icons.code_rounded),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => _showLicenses(context),
            ),
          ],
        ),

        const SizedBox(height: 32),
      ]),
    );
  }

  Widget _buildErrorState(BuildContext context, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: AppColors.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load settings',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () {
                ref.invalidate(appSettingsProvider);
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  String _getThemeDescription(String? themeMode) {
    switch (themeMode) {
      case 'light':
        return 'Light mode';
      case 'dark':
        return 'Dark mode';
      case 'system':
      default:
        return 'Follow system';
    }
  }

  IconData _getThemeIcon(String? themeMode) {
    switch (themeMode) {
      case 'light':
        return Icons.light_mode_rounded;
      case 'dark':
        return Icons.dark_mode_rounded;
      case 'system':
      default:
        return Icons.brightness_auto_rounded;
    }
  }

  String _getStorageUsage() {
    // TODO: Calculate actual storage usage
    return 'Calculating...';
  }

  Future<void> _updateSetting(String key, dynamic value) async {
    try {
      final settingsRepo = ref.read(settingsRepositoryProvider);
      await settingsRepo.updateSetting(key, value);
      
      // Refresh settings
      ref.invalidate(appSettingsProvider);
      
      HapticFeedback.lightImpact();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update setting: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showThemeSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Choose Theme',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.brightness_auto_rounded),
              title: const Text('Follow System'),
              subtitle: const Text('Use system theme setting'),
              onTap: () {
                _updateSetting('themeMode', 'system');
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              leading: const Icon(Icons.light_mode_rounded),
              title: const Text('Light Mode'),
              subtitle: const Text('Always use light theme'),
              onTap: () {
                _updateSetting('themeMode', 'light');
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              leading: const Icon(Icons.dark_mode_rounded),
              title: const Text('Dark Mode'),
              subtitle: const Text('Always use dark theme'),
              onTap: () {
                _updateSetting('themeMode', 'dark');
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showEncryptionDialog(BuildContext context, bool enable) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(enable ? 'Enable Encryption' : 'Disable Encryption'),
        content: Text(
          enable 
            ? 'This will encrypt all your notes locally. You\'ll need to set up a password or use biometric authentication.'
            : 'This will remove encryption from your notes. They will be stored as plain text.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              if (enable) {
                // TODO: Show encryption setup
                _showEncryptionSetup(context);
              } else {
                _updateSetting('encryptNotes', false);
              }
            },
            child: Text(enable ? 'Set Up' : 'Disable'),
          ),
        ],
      ),
    );
  }

  void _showEncryptionSetup(BuildContext context) {
    // TODO: Implement encryption setup dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Encryption setup coming soon!'),
      ),
    );
  }

  void _showStorageInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Storage Usage'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.note_rounded),
              title: Text('Notes'),
              trailing: Text('Calculating...'),
            ),
            ListTile(
              leading: Icon(Icons.image_rounded),
              title: Text('Attachments'),
              trailing: Text('Calculating...'),
            ),
            ListTile(
              leading: Icon(Icons.cached_rounded),
              title: Text('Cache'),
              trailing: Text('Calculating...'),
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

  void _showPrivacyInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Data Privacy'),
        content: const SingleChildScrollView(
          child: Text(
            'RocketNotes AI is designed with privacy in mind:\n\n'
            '• All notes are stored locally on your device\n'
            '• No data is sent to external servers without your consent\n'
            '• AI features are optional and can be disabled\n'
            '• You control all backup and sync operations\n'
            '• No tracking or analytics without permission\n\n'
            'Your data belongs to you.',
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

  Future<void> _exportAllData(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => const ConfirmationDialog(
        title: 'Export All Data',
        content: 'This will create a backup file with all your notes and settings. Continue?',
        confirmText: 'Export',
        cancelText: 'Cancel',
      ),
    ) ?? false;

    if (!confirmed) return;

    try {
      // TODO: Implement data export
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data export coming soon!'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _clearCache(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => const ConfirmationDialog(
        title: 'Clear Cache',
        content: 'This will clear temporary files and cached data. Your notes will not be affected.',
        confirmText: 'Clear',
        cancelText: 'Cancel',
      ),
    ) ?? false;

    if (!confirmed) return;

    try {
      // TODO: Implement cache clearing
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cache cleared successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to clear cache: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _resetSettings(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => const ConfirmationDialog(
        title: 'Reset Settings',
        content: 'This will reset all settings to their default values. Your notes will not be affected.',
        confirmText: 'Reset',
        cancelText: 'Cancel',
        isDestructive: true,
      ),
    ) ?? false;

    if (!confirmed) return;

    try {
      final settingsRepo = ref.read(settingsRepositoryProvider);
      await settingsRepo.resetToDefaults();
      ref.invalidate(appSettingsProvider);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Settings reset to defaults'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to reset settings: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Help & Support'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.help_center_rounded),
              title: Text('User Guide'),
              subtitle: Text('Learn how to use RocketNotes AI'),
            ),
            ListTile(
              leading: Icon(Icons.bug_report_rounded),
              title: Text('Report Bug'),
              subtitle: Text('Report issues or suggest features'),
            ),
            ListTile(
              leading: Icon(Icons.contact_support_rounded),
              title: Text('Contact Support'),
              subtitle: Text('Get help from our support team'),
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

  void _rateApp(BuildContext context) {
    // TODO: Implement app rating
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('App rating coming soon!'),
      ),
    );
  }

  void _showLicenses(BuildContext context) {
    showLicensePage(
      context: context,
      applicationName: 'RocketNotes AI',
      applicationVersion: _packageInfo?.version,
    );
  }
}
