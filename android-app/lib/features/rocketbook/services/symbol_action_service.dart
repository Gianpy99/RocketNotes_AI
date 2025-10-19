// ==========================================
// lib/features/rocketbook/services/symbol_action_service.dart
// ==========================================

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/rocketbook_template.dart';
import '../../../data/models/note.dart';
import '../../../data/repositories/note_repository.dart';
import '../../../data/repositories/topic_repository.dart';

/// Service to execute actions based on marked Rocketbook symbols
class SymbolActionService {
  static final SymbolActionService _instance = SymbolActionService._();
  static SymbolActionService get instance => _instance;
  
  SymbolActionService._();

  late Box<Map> _configBox;
  final Map<String, SymbolAction> _symbolConfigs = {};

  /// Initialize service and load configurations
  Future<void> initialize() async {
    try {
      // Open config box
      if (!Hive.isBoxOpen('rocketbook_symbol_config')) {
        _configBox = await Hive.openBox<Map>('rocketbook_symbol_config');
      } else {
        _configBox = Hive.box<Map>('rocketbook_symbol_config');
      }

      // Load configurations or set defaults
      await _loadConfigurations();
      
      debugPrint('[SymbolAction] Service initialized with ${_symbolConfigs.length} configured symbols');
    } catch (e) {
      debugPrint('[SymbolAction] Error initializing: $e');
      // Load defaults even if box fails
      _loadDefaultConfigurations();
    }
  }

  /// Load configurations from storage
  Future<void> _loadConfigurations() async {
    try {
      final configs = _configBox.get('symbols');
      
      if (configs != null) {
        for (final entry in configs.entries) {
          final symbolName = entry.key as String;
          final configData = Map<String, dynamic>.from(entry.value as Map);
          _symbolConfigs[symbolName] = SymbolAction.fromJson(configData);
        }
        debugPrint('[SymbolAction] Loaded ${_symbolConfigs.length} configurations from storage');
      } else {
        // No saved configs, use defaults
        _loadDefaultConfigurations();
        await saveConfigurations(_symbolConfigs.values.toList());
      }
    } catch (e) {
      debugPrint('[SymbolAction] Error loading configs: $e');
      _loadDefaultConfigurations();
    }
  }

  /// Load default configurations
  void _loadDefaultConfigurations() {
    for (final action in DefaultSymbolConfigs.defaults) {
      _symbolConfigs[action.symbol.name] = action;
    }
    debugPrint('[SymbolAction] Loaded ${_symbolConfigs.length} default configurations');
  }

  /// Save configurations to storage
  Future<void> saveConfigurations(List<SymbolAction> actions) async {
    try {
      final configs = <String, dynamic>{};
      for (final action in actions) {
        configs[action.symbol.name] = action.toJson();
        _symbolConfigs[action.symbol.name] = action;
      }
      
      await _configBox.put('symbols', configs);
      debugPrint('[SymbolAction] Saved ${actions.length} configurations');
    } catch (e) {
      debugPrint('[SymbolAction] Error saving configurations: $e');
    }
  }

  /// Get configuration for a symbol
  SymbolAction? getConfiguration(RocketbookSymbol symbol) {
    return _symbolConfigs[symbol.name];
  }

  /// Get all configurations
  List<SymbolAction> getAllConfigurations() {
    return _symbolConfigs.values.toList();
  }

  /// Update single symbol configuration
  Future<void> updateConfiguration(SymbolAction action) async {
    _symbolConfigs[action.symbol.name] = action;
    await saveConfigurations(_symbolConfigs.values.toList());
  }

  /// Execute actions for marked symbols on a scanned note
  Future<SymbolActionResult> executeActions({
    required List<RocketbookSymbol> markedSymbols,
    required NoteModel note,
  }) async {
    final results = <String, bool>{};
    final errors = <String>[];

    debugPrint('[SymbolAction] Executing actions for ${markedSymbols.length} marked symbols');

    for (final symbol in markedSymbols) {
      final config = getConfiguration(symbol);
      
      if (config == null || !config.enabled) {
        debugPrint('[SymbolAction] Symbol ${symbol.displayName} not configured or disabled');
        continue;
      }

      try {
        final success = await _executeAction(config, note);
        results[symbol.name] = success;
        
        if (success) {
          debugPrint('[SymbolAction] ✅ ${symbol.displayName}: ${config.actionType.displayName}');
        } else {
          debugPrint('[SymbolAction] ⚠️ ${symbol.displayName}: Action failed');
        }
      } catch (e) {
        debugPrint('[SymbolAction] ❌ ${symbol.displayName}: Error - $e');
        results[symbol.name] = false;
        errors.add('${symbol.displayName}: $e');
      }
    }

    return SymbolActionResult(
      results: results,
      errors: errors,
      totalSymbols: markedSymbols.length,
      successCount: results.values.where((v) => v).length,
    );
  }

  /// Execute single action
  Future<bool> _executeAction(SymbolAction config, NoteModel note) async {
    switch (config.actionType) {
      case SymbolActionType.assignToTopic:
        return await _assignToTopic(note, config.destination);
      
      case SymbolActionType.markFavorite:
        return await _markFavorite(note);
      
      case SymbolActionType.archive:
        return await _archiveNote(note);
      
      case SymbolActionType.createReminder:
        return await _createReminder(note, config.destination);
      
      case SymbolActionType.email:
        return await _sendToEmail(note, config.destination);
      
      case SymbolActionType.googleDrive:
      case SymbolActionType.dropbox:
      case SymbolActionType.evernote:
      case SymbolActionType.slack:
      case SymbolActionType.icloud:
      case SymbolActionType.onedrive:
        return await _sendToCloudService(note, config.actionType, config.destination);
      
      case SymbolActionType.none:
      case SymbolActionType.custom:
        return true; // No action or custom handling
    }
  }

  Future<bool> _assignToTopic(NoteModel note, String? topicId) async {
    try {
      if (topicId == null) return false;
      
      // Update note with topicId
      final updatedNote = note.copyWith(topicId: topicId);
      final repo = NoteRepository();
      await repo.saveNote(updatedNote);
      
      // Update topic note count
      final topicRepo = TopicRepository();
      final topic = await topicRepo.getTopicById(topicId);
      if (topic != null) {
        await topicRepo.updateNoteCount(topicId, topic.noteCount + 1);
      }
      
      return true;
    } catch (e) {
      debugPrint('[SymbolAction] Error assigning to topic: $e');
      return false;
    }
  }

  Future<bool> _markFavorite(NoteModel note) async {
    try {
      final updatedNote = note.copyWith(isFavorite: true);
      final repo = NoteRepository();
      await repo.saveNote(updatedNote);
      return true;
    } catch (e) {
      debugPrint('[SymbolAction] Error marking favorite: $e');
      return false;
    }
  }

  Future<bool> _archiveNote(NoteModel note) async {
    try {
      final updatedNote = note.copyWith(isArchived: true);
      final repo = NoteRepository();
      await repo.saveNote(updatedNote);
      return true;
    } catch (e) {
      debugPrint('[SymbolAction] Error archiving note: $e');
      return false;
    }
  }

  Future<bool> _createReminder(NoteModel note, String? time) async {
    try {
      // Parse time or use default (tomorrow 9am)
      DateTime reminderDate = DateTime.now().add(const Duration(days: 1));
      reminderDate = DateTime(
        reminderDate.year,
        reminderDate.month,
        reminderDate.day,
        9, // 9am
      );
      
      final updatedNote = note.copyWith(reminderDate: reminderDate);
      final repo = NoteRepository();
      await repo.saveNote(updatedNote);
      return true;
    } catch (e) {
      debugPrint('[SymbolAction] Error creating reminder: $e');
      return false;
    }
  }

  Future<bool> _sendToEmail(NoteModel note, String? email) async {
    try {
      // TODO: Implement email sending
      debugPrint('[SymbolAction] Would send to email: $email');
      debugPrint('[SymbolAction] Note: ${note.title}');
      return true;
    } catch (e) {
      debugPrint('[SymbolAction] Error sending email: $e');
      return false;
    }
  }

  Future<bool> _sendToCloudService(
    NoteModel note,
    SymbolActionType service,
    String? destination,
  ) async {
    try {
      // TODO: Implement cloud service integrations
      debugPrint('[SymbolAction] Would send to ${service.displayName}: $destination');
      debugPrint('[SymbolAction] Note: ${note.title}');
      return true;
    } catch (e) {
      debugPrint('[SymbolAction] Error sending to cloud: $e');
      return false;
    }
  }
}

/// Result of executing symbol actions
class SymbolActionResult {
  final Map<String, bool> results;
  final List<String> errors;
  final int totalSymbols;
  final int successCount;

  SymbolActionResult({
    required this.results,
    required this.errors,
    required this.totalSymbols,
    required this.successCount,
  });

  bool get allSuccess => successCount == totalSymbols && errors.isEmpty;
  bool get hasErrors => errors.isNotEmpty;
  int get failedCount => totalSymbols - successCount;

  String get summary {
    if (allSuccess) {
      return '$successCount actions completed successfully';
    }
    return '$successCount/$totalSymbols actions succeeded, $failedCount failed';
  }
}
