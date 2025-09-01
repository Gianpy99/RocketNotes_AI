// lib/ui/widgets/settings/backup_settings.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/settings_provider.dart';

class BackupSettings extends ConsumerStatefulWidget {
  const BackupSettings({super.key});

  @override
  ConsumerState<BackupSettings> createState() => _BackupSettingsState();
}

class _BackupSettingsState extends ConsumerState<BackupSettings> {
  bool _isBackingUp = false;
  bool _isRestoring = false;
  DateTime? _lastBackup;

  @override
  void initState() {
    super.initState();
    _loadLastBackupDate();
  }

  void _loadLastBackupDate() {
    // TODO: Load from shared preferences or settings
    // _lastBackup = ...;
  }

  Future<void> _performBackup() async {
    setState(() {
      _isBackingUp = true;
    });

    try {
      // TODO: Implement backup logic
      await Future.delayed(const Duration(seconds: 3)); // Simulate backup
      
      setState(() {
        _lastBackup = DateTime.now();
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Backup completed successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Backup failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isBackingUp = false;
      });
    }
  }

  Future<void> _performRestore() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore from Backup'),
        content: const Text(
          'This will replace all current notes with backed up data. '
          'This action cannot be undone. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Restore'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isRestoring = true;
    });

    try {
      // TODO: Implement restore logic
      await Future.delayed(const Duration(seconds: 3)); // Simulate restore
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Restore completed successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Restore failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isRestoring = false;
      });
    }
  }

  Future<void> _exportNotes() async {
    try {
      // TODO: Implement export to JSON/CSV
      await Future.delayed(const Duration(seconds: 2)); // Simulate export
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notes exported successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
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
              Icon(
                Icons.backup_rounded,
                color: AppColors.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Backup & Sync',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Auto Backup Toggle
          _SettingsTile(
            title: 'Auto Backup',
            subtitle: 'Automatically backup notes daily',
            trailing: Switch(
              value: settings?.autoBackup ?? false,
              onChanged: (value) {
                ref.read(settingsProvider.notifier).updateSettings(
                  autoBackup: value,
                );
              },
              activeThumbColor: AppColors.primary,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Cloud Sync Toggle
          _SettingsTile(
            title: 'Cloud Sync',
            subtitle: 'Sync notes across devices (coming soon)',
            trailing: Switch(
              value: settings?.cloudSync ?? false,
              onChanged: null, // Disabled for now
              activeThumbColor: AppColors.primary,
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Backup Status
          if (_lastBackup != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.green.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    color: Colors.green,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Last backup: ${_formatDate(_lastBackup!)}',
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          // Action Buttons
          Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _isBackingUp ? null : _performBackup,
                  icon: _isBackingUp
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.backup_rounded),
                  label: Text(_isBackingUp ? 'Backing up...' : 'Backup Now'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                  ),
                ),
              ),
              
              const SizedBox(height: 12),
              
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isRestoring ? null : _performRestore,
                  icon: _isRestoring
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.restore_rounded),
                  label: Text(_isRestoring ? 'Restoring...' : 'Restore from Backup'),
                ),
              ),
              
              const SizedBox(height: 12),
              
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _exportNotes,
                  icon: const Icon(Icons.download_rounded),
                  label: const Text('Export Notes'),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Storage Info
          _StorageInfo(),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
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

class _StorageInfo extends StatelessWidget {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Storage Usage',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Notes Data:',
                style: theme.textTheme.bodySmall,
              ),
              Text(
                '2.4 MB', // TODO: Calculate actual size
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 4),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Backup Size:',
                style: theme.textTheme.bodySmall,
              ),
              Text(
                '1.8 MB', // TODO: Calculate actual size
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
