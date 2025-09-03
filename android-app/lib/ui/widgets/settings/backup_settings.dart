// lib/ui/widgets/settings/backup_settings.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/note_model.dart';
import '../../../screens/settings_screen.dart';
import '../../../main_simple.dart';

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
    // Load from shared preferences or settings
    try {
      final box = Hive.box('settings');
      final lastBackupTimestamp = box.get('lastBackupDate');
      if (lastBackupTimestamp != null) {
        _lastBackup = DateTime.fromMillisecondsSinceEpoch(lastBackupTimestamp);
      }
    } catch (e) {
      debugPrint('Error loading last backup date: $e');
    }
  }

  Future<void> _performBackup() async {
    setState(() {
      _isBackingUp = true;
    });

    try {
      // Get all notes from Hive
      final notesBox = Hive.box<NoteModel>('notes');
      final notes = notesBox.values.cast<NoteModel>().toList();

      // Create backup data
      final backupData = {
        'version': '1.0',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'notes': notes.map((note) => {
          'id': note.id,
          'title': note.title,
          'content': note.content,
          'mode': note.mode,
          'createdAt': note.createdAt.millisecondsSinceEpoch,
          'updatedAt': note.updatedAt.millisecondsSinceEpoch,
          'tags': note.tags,
          'aiSummary': note.aiSummary,
          'attachments': note.attachments,
          'nfcTagId': note.nfcTagId,
          'isFavorite': note.isFavorite,
          'color': note.color,
          'priority': note.priority,
        }).toList(),
      };

      // Convert to JSON
      final jsonString = jsonEncode(backupData);

      // Get backup directory
      final directory = await getApplicationDocumentsDirectory();
      final backupDir = Directory('${directory.path}/backups');
      if (!await backupDir.exists()) {
        await backupDir.create(recursive: true);
      }

      // Create backup file
      final timestamp = DateTime.now().toString().replaceAll(':', '-').replaceAll(' ', '_').split('.')[0];
      final backupFile = File('${backupDir.path}/rocketnotes_backup_$timestamp.json');
      await backupFile.writeAsString(jsonString);

      // Save last backup date to settings
      final settingsBox = Hive.box('settings');
      await settingsBox.put('lastBackupDate', DateTime.now().millisecondsSinceEpoch);

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
      // Get backup directory
      final directory = await getApplicationDocumentsDirectory();
      final backupDir = Directory('${directory.path}/backups');

      if (!await backupDir.exists()) {
        throw Exception('No backup directory found');
      }

      // Get the most recent backup file
      final backupFiles = await backupDir.list().toList();
      final jsonFiles = backupFiles.whereType<File>()
          .where((file) => file.path.endsWith('.json'))
          .toList();

      if (jsonFiles.isEmpty) {
        throw Exception('No backup files found');
      }

      // Sort by modification time (most recent first)
      jsonFiles.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
      final latestBackup = jsonFiles.first;

      // Read backup file
      final jsonString = await latestBackup.readAsString();
      final backupData = jsonDecode(jsonString) as Map<String, dynamic>;

      // Clear existing notes
      final notesBox = Hive.box<NoteModel>('notes');
      await notesBox.clear();

      // Restore notes from backup
      final notesData = backupData['notes'] as List<dynamic>;
      for (final noteData in notesData) {
        final note = NoteModel(
          id: noteData['id'],
          title: noteData['title'] ?? '',
          content: noteData['content'] ?? '',
          mode: noteData['mode'] ?? 'personal',
          createdAt: DateTime.fromMillisecondsSinceEpoch(noteData['createdAt']),
          updatedAt: DateTime.fromMillisecondsSinceEpoch(noteData['updatedAt']),
          tags: List<String>.from(noteData['tags'] ?? []),
          aiSummary: noteData['aiSummary'],
          attachments: List<String>.from(noteData['attachments'] ?? []),
          nfcTagId: noteData['nfcTagId'],
          isFavorite: noteData['isFavorite'] ?? false,
          color: noteData['color'],
          priority: noteData['priority'] ?? 0,
        );
        await notesBox.put(note.id, note);
      }

      // Refresh the notes provider
      ref.invalidate(notesProvider);

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
      // Get all notes
      final notesBox = Hive.box<NoteModel>('notes');
      final notes = notesBox.values.cast<NoteModel>().toList();

      // Create export data in JSON format
      final exportData = {
        'exportDate': DateTime.now().toIso8601String(),
        'appVersion': '1.0.0',
        'totalNotes': notes.length,
        'notes': notes.map((note) => {
          'id': note.id,
          'title': note.title,
          'content': note.content,
          'mode': note.mode,
          'createdAt': note.createdAt.toIso8601String(),
          'updatedAt': note.updatedAt.toIso8601String(),
          'tags': note.tags,
          'aiSummary': note.aiSummary,
          'attachments': note.attachments,
          'nfcTagId': note.nfcTagId,
          'isFavorite': note.isFavorite,
          'color': note.color,
          'priority': note.priority,
        }).toList(),
      };

      // Convert to JSON string
      final jsonString = jsonEncode(exportData);

      // Get temporary directory for export file
      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().toString().replaceAll(':', '-').replaceAll(' ', '_').split('.')[0];
      final exportFile = File('${directory.path}/rocketnotes_export_$timestamp.json');

      // Write JSON to file
      await exportFile.writeAsString(jsonString);

      // Share the export file
      // ignore: deprecated_member_use
      await Share.shareXFiles(
        [XFile(exportFile.path)],
        subject: 'RocketNotes AI Export - $timestamp',
        text: 'Exported ${notes.length} notes from RocketNotes AI',
      );

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
              const Icon(
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
              value: settings.autoBackup,
              onChanged: (value) {
                ref.read(settingsProvider.notifier).setAutoBackup(value);
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
              value: settings.cloudSync,
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
                _calculateNotesSize(),
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
                _calculateBackupSize(),
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

  String _calculateNotesSize() {
    try {
      final notesBox = Hive.box<NoteModel>('notes');
      final notes = notesBox.values.cast<NoteModel>().toList();
      
      // Calculate approximate size
      int totalSize = 0;
      for (final note in notes) {
        // Rough estimation: title + content + metadata
        totalSize += (note.title.length + note.content.length) * 2; // 2 bytes per character for UTF-16
        totalSize += note.tags.join(',').length * 2;
        totalSize += 200; // Metadata overhead per note
      }
      
      return _formatBytes(totalSize);
    } catch (e) {
      return 'Unknown';
    }
  }

  String _calculateBackupSize() {
    try {
      // For now, return a placeholder since we can't use async in build
      // In a real implementation, this would be calculated asynchronously
      return 'Calculating...';
    } catch (e) {
      return 'Unknown';
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }
}
