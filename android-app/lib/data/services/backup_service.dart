// ==========================================
// lib/data/services/backup_service.dart
// ==========================================
import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import '../repositories/note_repository.dart';
import '../repositories/settings_repository.dart';

class BackupService {
  final NoteRepository _noteRepository;
  final SettingsRepository _settingsRepository;

  BackupService({
    required NoteRepository noteRepository,
    required SettingsRepository settingsRepository,
  }) : _noteRepository = noteRepository,
       _settingsRepository = settingsRepository;

  // Create backup data
  Future<BackupData> createBackup() async {
    try {
      final notes = await _noteRepository.exportAllNotes();
      final settings = await _settingsRepository.exportSettings();
      final timestamp = DateTime.now();

      return BackupData(
        version: '1.0',
        timestamp: timestamp,
        notes: notes,
        settings: settings,
        notesCount: notes.length,
      );
    } catch (e) {
      throw Exception('Failed to create backup: $e');
    }
  }

  // Export backup to JSON string
  Future<String> exportBackupToJson() async {
    try {
      final backup = await createBackup();
      return jsonEncode(backup.toJson());
    } catch (e) {
      throw Exception('Failed to export backup to JSON: $e');
    }
  }

  // Import backup from JSON string
  Future<void> importBackupFromJson(String jsonData) async {
    try {
      final Map<String, dynamic> data = jsonDecode(jsonData);
      final backup = BackupData.fromJson(data);

      // Validate backup version
      if (backup.version != '1.0') {
        throw Exception('Unsupported backup version: ${backup.version}');
      }

      // Import notes
      if (backup.notes.isNotEmpty) {
        await _noteRepository.importNotes(backup.notes);
      }

      // Import settings
      if (backup.settings.isNotEmpty) {
        await _settingsRepository.importSettings(backup.settings);
      }

      // Update last backup date
      await _settingsRepository.updateLastBackupDate(DateTime.now());
    } catch (e) {
      throw Exception('Failed to import backup: $e');
    }
  }

  // Save backup to file
  Future<String> saveBackupToFile(String directoryPath) async {
    try {
      final backupJson = await exportBackupToJson();
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final filename = 'rocketnotes_backup_$timestamp.json';
      final filePath = '$directoryPath/$filename';
      
      final file = File(filePath);
      await file.writeAsString(backupJson);
      
      return filePath;
    } catch (e) {
      throw Exception('Failed to save backup to file: $e');
    }
  }

  // Load backup from file
  Future<void> loadBackupFromFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('Backup file does not exist');
      }

      final jsonData = await file.readAsString();
      await importBackupFromJson(jsonData);
    } catch (e) {
      throw Exception('Failed to load backup from file: $e');
    }
  }

  // Validate backup data
  Future<BackupValidationResult> validateBackup(String jsonData) async {
    try {
      final Map<String, dynamic> data = jsonDecode(jsonData);
      final backup = BackupData.fromJson(data);

      final errors = <String>[];
      final warnings = <String>[];

      // Version check
      if (backup.version != '1.0') {
        errors.add('Unsupported backup version: ${backup.version}');
      }

      // Notes validation
      if (backup.notes.isEmpty) {
        warnings.add('Backup contains no notes');
      } else {
        // Validate note structure
        for (int i = 0; i < backup.notes.length; i++) {
          final note = backup.notes[i];
          if (note['id'] == null || note['id'].toString().isEmpty) {
            errors.add('Note at index $i has invalid ID');
          }
          if (note['mode'] == null || 
              !['work', 'personal'].contains(note['mode'])) {
            errors.add('Note at index $i has invalid mode');
          }
        }
      }

      // Settings validation
      if (backup.settings.isEmpty) {
        warnings.add('Backup contains no settings');
      }

      // Timestamp validation
      if (backup.timestamp.isAfter(DateTime.now())) {
        warnings.add('Backup timestamp is in the future');
      }

      return BackupValidationResult(
        isValid: errors.isEmpty,
        errors: errors,
        warnings: warnings,
        notesCount: backup.notesCount,
        backupDate: backup.timestamp,
      );
    } catch (e) {
      return BackupValidationResult(
        isValid: false,
        errors: ['Invalid backup format: $e'],
        warnings: [],
        notesCount: 0,
        backupDate: DateTime.now(),
      );
    }
  }

  // Get backup statistics
  Future<BackupStats> getBackupStats() async {
    try {
      final settings = await _settingsRepository.getSettings();
      final notesStats = await _noteRepository.getStatistics();
      
      return BackupStats(
        lastBackupDate: settings.lastBackupDate,
        autoBackupEnabled: settings.autoBackup,
        totalNotes: notesStats['totalNotes'] as int,
        totalTags: notesStats['totalTags'] as int,
      );
    } catch (e) {
      throw Exception('Failed to get backup stats: $e');
    }
  }
}

// Backup data model
class BackupData {
  final String version;
  final DateTime timestamp;
  final List<Map<String, dynamic>> notes;
  final Map<String, dynamic> settings;
  final int notesCount;

  BackupData({
    required this.version,
    required this.timestamp,
    required this.notes,
    required this.settings,
    required this.notesCount,
  });

  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'timestamp': timestamp.toIso8601String(),
      'notes': notes,
      'settings': settings,
      'notesCount': notesCount,
      'appName': 'RocketNotes AI',
    };
  }

  factory BackupData.fromJson(Map<String, dynamic> json) {
    return BackupData(
      version: json['version'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      notes: List<Map<String, dynamic>>.from(json['notes'] as List),
      settings: json['settings'] as Map<String, dynamic>,
      notesCount: json['notesCount'] as int,
    );
  }
}

// Backup validation result
class BackupValidationResult {
  final bool isValid;
  final List<String> errors;
  final List<String> warnings;
  final int notesCount;
  final DateTime backupDate;

  BackupValidationResult({
    required this.isValid,
    required this.errors,
    required this.warnings,
    required this.notesCount,
    required this.backupDate,
  });
}

// Backup statistics
class BackupStats {
  final DateTime? lastBackupDate;
  final bool autoBackupEnabled;
  final int totalNotes;
  final int totalTags;

  BackupStats({
    this.lastBackupDate,
    required this.autoBackupEnabled,
    required this.totalNotes,
    required this.totalTags,
  });
}
