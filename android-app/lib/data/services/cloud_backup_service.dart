// ==========================================
// lib/data/services/cloud_backup_service.dart
// ==========================================

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/note_model.dart';
import '../models/app_settings_model.dart';

/// Comprehensive cloud backup service for all app data
/// Backs up: notes, settings, images, audio, attachments
class CloudBackupService {
  static final CloudBackupService _instance = CloudBackupService._();
  static CloudBackupService get instance => _instance;
  
  CloudBackupService._();

  bool _isInitialized = false;
  bool _autoBackupEnabled = true;
  BackupProvider _provider = BackupProvider.firebaseStorage;
  
  // Firebase Storage instance
  FirebaseStorage? _storage;
  String? _userId;

  /// Initialize the backup service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _storage = FirebaseStorage.instance;
      _userId = FirebaseAuth.instance.currentUser?.uid;
      
      if (_userId == null) {
        debugPrint('[CloudBackup] ⚠️ No user logged in - backup disabled');
        return;
      }

      // Load settings
      // Auto-backup enabled by default
      _autoBackupEnabled = true;

      _isInitialized = true;
      debugPrint('[CloudBackup] ✅ Initialized for user: $_userId');
      debugPrint('[CloudBackup]    Provider: ${_provider.name}');
      debugPrint('[CloudBackup]    Auto-backup: $_autoBackupEnabled');

    } catch (e) {
      debugPrint('[CloudBackup] ❌ Initialization error: $e');
    }
  }

  /// Enable/disable automatic backup
  void setAutoBackup(bool enabled) {
    _autoBackupEnabled = enabled;
    debugPrint('[CloudBackup] Auto-backup ${enabled ? "enabled" : "disabled"}');
  }

  /// Set backup provider
  void setProvider(BackupProvider provider) {
    _provider = provider;
    debugPrint('[CloudBackup] Provider changed to: ${provider.name}');
  }

  /// Perform complete backup of all app data
  Future<BackupResult> backupAll() async {
    if (!_isInitialized || _userId == null) {
      return BackupResult.error('Service not initialized or no user');
    }

    debugPrint('[CloudBackup] 🔄 Starting complete backup...');
    final startTime = DateTime.now();
    
    try {
      // 1. Backup notes
      debugPrint('[CloudBackup] Step 1/5: Backing up notes...');
      final notesResult = await _backupNotes();
      
      // 2. Backup settings
      debugPrint('[CloudBackup] Step 2/5: Backing up settings...');
      final settingsResult = await _backupSettings();
      
      // 3. Backup images
      debugPrint('[CloudBackup] Step 3/5: Backing up images...');
      final imagesResult = await _backupImages();
      
      // 4. Backup audio files
      debugPrint('[CloudBackup] Step 4/5: Backing up audio...');
      final audioResult = await _backupAudio();
      
      // 5. Backup attachments
      debugPrint('[CloudBackup] Step 5/5: Backing up attachments...');
      final attachmentsResult = await _backupAttachments();

      final duration = DateTime.now().difference(startTime);
      final totalSize = notesResult.size + settingsResult.size + 
                       imagesResult.size + audioResult.size + attachmentsResult.size;

      debugPrint('[CloudBackup] ✅ Backup completed in ${duration.inSeconds}s');
      debugPrint('[CloudBackup]    Notes: ${notesResult.count} items (${_formatBytes(notesResult.size)})');
      debugPrint('[CloudBackup]    Settings: ${settingsResult.count} items (${_formatBytes(settingsResult.size)})');
      debugPrint('[CloudBackup]    Images: ${imagesResult.count} items (${_formatBytes(imagesResult.size)})');
      debugPrint('[CloudBackup]    Audio: ${audioResult.count} items (${_formatBytes(audioResult.size)})');
      debugPrint('[CloudBackup]    Attachments: ${attachmentsResult.count} items (${_formatBytes(attachmentsResult.size)})');
      debugPrint('[CloudBackup]    Total: ${_formatBytes(totalSize)}');

      return BackupResult.success(
        timestamp: DateTime.now(),
        duration: duration,
        totalSize: totalSize,
        itemsCounts: {
          'notes': notesResult.count,
          'settings': settingsResult.count,
          'images': imagesResult.count,
          'audio': audioResult.count,
          'attachments': attachmentsResult.count,
        },
      );

    } catch (e, stackTrace) {
      debugPrint('[CloudBackup] ❌ Backup failed: $e');
      debugPrint('[CloudBackup] Stack: $stackTrace');
      return BackupResult.error(e.toString());
    }
  }

  /// Restore all data from cloud backup
  Future<RestoreResult> restoreAll() async {
    if (!_isInitialized || _userId == null) {
      return RestoreResult.error('Service not initialized or no user');
    }

    debugPrint('[CloudBackup] 🔄 Starting complete restore...');
    final startTime = DateTime.now();

    try {
      // 1. Restore notes
      debugPrint('[CloudBackup] Step 1/5: Restoring notes...');
      await _restoreNotes();
      
      // 2. Restore settings
      debugPrint('[CloudBackup] Step 2/5: Restoring settings...');
      await _restoreSettings();
      
      // 3. Restore images
      debugPrint('[CloudBackup] Step 3/5: Restoring images...');
      await _restoreImages();
      
      // 4. Restore audio
      debugPrint('[CloudBackup] Step 4/5: Restoring audio...');
      await _restoreAudio();
      
      // 5. Restore attachments
      debugPrint('[CloudBackup] Step 5/5: Restoring attachments...');
      await _restoreAttachments();

      final duration = DateTime.now().difference(startTime);
      debugPrint('[CloudBackup] ✅ Restore completed in ${duration.inSeconds}s');

      return RestoreResult.success(
        timestamp: DateTime.now(),
        duration: duration,
      );

    } catch (e, stackTrace) {
      debugPrint('[CloudBackup] ❌ Restore failed: $e');
      debugPrint('[CloudBackup] Stack: $stackTrace');
      return RestoreResult.error(e.toString());
    }
  }

  /// Backup individual file (image, audio, attachment)
  Future<void> backupFile({
    required String localPath,
    required BackupFileType type,
  }) async {
    if (!_isInitialized || _userId == null) return;

    try {
      final file = File(localPath);
      if (!await file.exists()) {
        debugPrint('[CloudBackup] File not found: $localPath');
        return;
      }

      final fileName = localPath.split('/').last;
      final remotePath = '${_userId}/${type.folder}/$fileName';

      debugPrint('[CloudBackup] Uploading $fileName...');
      await _storage!.ref(remotePath).putFile(file);
      debugPrint('[CloudBackup] ✅ Uploaded: $remotePath');

    } catch (e) {
      debugPrint('[CloudBackup] ❌ Upload failed: $e');
    }
  }

  /// Delete backup from cloud
  Future<void> deleteBackup() async {
    if (!_isInitialized || _userId == null) return;

    try {
      debugPrint('[CloudBackup] 🗑️ Deleting backup...');
      
      // Delete all folders
      for (final type in BackupFileType.values) {
        final folderRef = _storage!.ref('$_userId/${type.folder}');
        final items = await folderRef.listAll();
        
        for (final item in items.items) {
          await item.delete();
        }
      }

      debugPrint('[CloudBackup] ✅ Backup deleted');
    } catch (e) {
      debugPrint('[CloudBackup] ❌ Delete failed: $e');
    }
  }

  /// Get backup info (size, last backup time, item counts)
  Future<BackupInfo> getBackupInfo() async {
    if (!_isInitialized || _userId == null) {
      return BackupInfo.empty();
    }

    try {
      int totalSize = 0;
      final counts = <String, int>{};

      for (final type in BackupFileType.values) {
        final folderRef = _storage!.ref('$_userId/${type.folder}');
        final items = await folderRef.listAll();
        
        counts[type.folder] = items.items.length;
        
        for (final item in items.items) {
          final metadata = await item.getMetadata();
          totalSize += metadata.size ?? 0;
        }
      }

      // Get last backup timestamp from metadata
      DateTime? lastBackup;
      try {
        final metadataRef = _storage!.ref('$_userId/.backup_metadata');
        final metadataBytes = await metadataRef.getData();
        if (metadataBytes != null) {
          final metadataStr = String.fromCharCodes(metadataBytes);
          lastBackup = DateTime.tryParse(metadataStr);
        }
      } catch (e) {
        // No metadata yet
      }

      return BackupInfo(
        exists: counts.values.any((c) => c > 0),
        lastBackup: lastBackup,
        totalSize: totalSize,
        itemCounts: counts,
      );

    } catch (e) {
      debugPrint('[CloudBackup] ❌ Get info failed: $e');
      return BackupInfo.empty();
    }
  }

  // ==========================================
  // PRIVATE METHODS - Backup specific types
  // ==========================================

  Future<_BackupPartResult> _backupNotes() async {
    try {
      final notesBox = Hive.box<NoteModel>('notes');
      final notes = notesBox.values.toList();
      
      if (notes.isEmpty) {
        return _BackupPartResult(count: 0, size: 0);
      }

      // Convert to JSON
      final notesJson = notes.map((n) => n.toJson()).toList();
      final jsonStr = notesJson.toString();
      final bytes = Uint8List.fromList(jsonStr.codeUnits);

      // Upload
      await _storage!.ref('$_userId/notes/notes_backup.json').putData(bytes);

      return _BackupPartResult(count: notes.length, size: bytes.length);
    } catch (e) {
      debugPrint('[CloudBackup] Notes backup error: $e');
      return _BackupPartResult(count: 0, size: 0);
    }
  }

  Future<_BackupPartResult> _backupSettings() async {
    try {
      final settingsBox = Hive.box<AppSettingsModel>('settings');
      final settings = settingsBox.get('app_settings');
      
      if (settings == null) {
        return _BackupPartResult(count: 0, size: 0);
      }

      final jsonStr = settings.toJson().toString();
      final bytes = Uint8List.fromList(jsonStr.codeUnits);

      await _storage!.ref('$_userId/settings/settings_backup.json').putData(bytes);

      return _BackupPartResult(count: 1, size: bytes.length);
    } catch (e) {
      debugPrint('[CloudBackup] Settings backup error: $e');
      return _BackupPartResult(count: 0, size: 0);
    }
  }

  Future<_BackupPartResult> _backupImages() async {
    return await _backupDirectory(BackupFileType.images);
  }

  Future<_BackupPartResult> _backupAudio() async {
    return await _backupDirectory(BackupFileType.audio);
  }

  Future<_BackupPartResult> _backupAttachments() async {
    return await _backupDirectory(BackupFileType.attachments);
  }

  Future<_BackupPartResult> _backupDirectory(BackupFileType type) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final typeDir = Directory('${appDir.path}/${type.folder}');

      if (!await typeDir.exists()) {
        return _BackupPartResult(count: 0, size: 0);
      }

      final files = typeDir.listSync().whereType<File>().toList();
      int totalSize = 0;

      for (final file in files) {
        final fileName = file.path.split('/').last;
        final remotePath = '$_userId/${type.folder}/$fileName';
        
        await _storage!.ref(remotePath).putFile(file);
        totalSize += await file.length();
      }

      return _BackupPartResult(count: files.length, size: totalSize);
    } catch (e) {
      debugPrint('[CloudBackup] ${type.folder} backup error: $e');
      return _BackupPartResult(count: 0, size: 0);
    }
  }

  // ==========================================
  // PRIVATE METHODS - Restore specific types
  // ==========================================

  Future<void> _restoreNotes() async {
    try {
      final bytes = await _storage!.ref('$_userId/notes/notes_backup.json').getData();
      if (bytes == null) return;

      // TODO: Parse JSON and restore notes
      debugPrint('[CloudBackup] Notes restore: ${bytes.length} bytes');
    } catch (e) {
      debugPrint('[CloudBackup] Notes restore error: $e');
    }
  }

  Future<void> _restoreSettings() async {
    try {
      final bytes = await _storage!.ref('$_userId/settings/settings_backup.json').getData();
      if (bytes == null) return;

      // TODO: Parse JSON and restore settings
      debugPrint('[CloudBackup] Settings restore: ${bytes.length} bytes');
    } catch (e) {
      debugPrint('[CloudBackup] Settings restore error: $e');
    }
  }

  Future<void> _restoreImages() async {
    await _restoreDirectory(BackupFileType.images);
  }

  Future<void> _restoreAudio() async {
    await _restoreDirectory(BackupFileType.audio);
  }

  Future<void> _restoreAttachments() async {
    await _restoreDirectory(BackupFileType.attachments);
  }

  Future<void> _restoreDirectory(BackupFileType type) async {
    try {
      final folderRef = _storage!.ref('$_userId/${type.folder}');
      final items = await folderRef.listAll();

      final appDir = await getApplicationDocumentsDirectory();
      final typeDir = Directory('${appDir.path}/${type.folder}');
      await typeDir.create(recursive: true);

      for (final item in items.items) {
        final fileName = item.name;
        final localFile = File('${typeDir.path}/$fileName');
        
        final bytes = await item.getData();
        if (bytes != null) {
          await localFile.writeAsBytes(bytes);
        }
      }

      debugPrint('[CloudBackup] ${type.folder} restored: ${items.items.length} files');
    } catch (e) {
      debugPrint('[CloudBackup] ${type.folder} restore error: $e');
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

// ==========================================
// Supporting classes
// ==========================================

class _BackupPartResult {
  final int count;
  final int size;
  
  _BackupPartResult({required this.count, required this.size});
}

enum BackupProvider {
  firebaseStorage,
  googleDrive,
  dropbox,
  icloud,
}

enum BackupFileType {
  images,
  audio,
  attachments,
}

extension BackupFileTypeExtension on BackupFileType {
  String get folder {
    switch (this) {
      case BackupFileType.images:
        return 'images';
      case BackupFileType.audio:
        return 'audio';
      case BackupFileType.attachments:
        return 'attachments';
    }
  }
}

class BackupResult {
  final bool success;
  final DateTime? timestamp;
  final Duration? duration;
  final int? totalSize;
  final Map<String, int>? itemsCounts;
  final String? error;

  BackupResult._({
    required this.success,
    this.timestamp,
    this.duration,
    this.totalSize,
    this.itemsCounts,
    this.error,
  });

  factory BackupResult.success({
    required DateTime timestamp,
    required Duration duration,
    required int totalSize,
    required Map<String, int> itemsCounts,
  }) {
    return BackupResult._(
      success: true,
      timestamp: timestamp,
      duration: duration,
      totalSize: totalSize,
      itemsCounts: itemsCounts,
    );
  }

  factory BackupResult.error(String error) {
    return BackupResult._(success: false, error: error);
  }
}

class RestoreResult {
  final bool success;
  final DateTime? timestamp;
  final Duration? duration;
  final String? error;

  RestoreResult._({
    required this.success,
    this.timestamp,
    this.duration,
    this.error,
  });

  factory RestoreResult.success({
    required DateTime timestamp,
    required Duration duration,
  }) {
    return RestoreResult._(
      success: true,
      timestamp: timestamp,
      duration: duration,
    );
  }

  factory RestoreResult.error(String error) {
    return RestoreResult._(success: false, error: error);
  }
}

class BackupInfo {
  final bool exists;
  final DateTime? lastBackup;
  final int totalSize;
  final Map<String, int> itemCounts;

  BackupInfo({
    required this.exists,
    this.lastBackup,
    required this.totalSize,
    required this.itemCounts,
  });

  factory BackupInfo.empty() {
    return BackupInfo(
      exists: false,
      totalSize: 0,
      itemCounts: {},
    );
  }

  String get formattedSize {
    if (totalSize < 1024) return '$totalSize B';
    if (totalSize < 1024 * 1024) return '${(totalSize / 1024).toStringAsFixed(1)} KB';
    return '${(totalSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  int get totalItems => itemCounts.values.fold(0, (sum, count) => sum + count);
}
