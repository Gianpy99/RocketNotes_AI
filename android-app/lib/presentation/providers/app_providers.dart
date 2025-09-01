// ==========================================
// lib/presentation/providers/app_providers.dart
// ==========================================
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/note_model.dart';
import '../../data/models/app_settings_model.dart';
import '../../data/repositories/note_repository.dart';
import '../../data/repositories/settings_repository.dart';
import '../../data/services/nfc_service.dart';
import '../../data/services/deep_link_service.dart';
import '../../data/services/notification_service.dart';
import '../../data/services/backup_service.dart';
import '../../data/services/ai_service.dart';
import '../../data/services/search_service.dart';
import '../../data/services/api_service.dart';
import '../../data/services/sync_service.dart';

// ==========================================
// Repository Providers
// ==========================================

final noteRepositoryProvider = Provider<NoteRepository>((ref) {
  return NoteRepository();
});

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository();
});

// ==========================================
// Mode Provider (Work/Personal)
// ==========================================
final appModeProvider = StateNotifierProvider<AppModeNotifier, String>((ref) {
  return AppModeNotifier();
});

class AppModeNotifier extends StateNotifier<String> {
  AppModeNotifier() : super('personal');

  void setMode(String mode) {
    state = mode;
  }

  void toggleMode() {
    state = state == 'work' ? 'personal' : 'work';
  }
}

// ==========================================
// Service Providers
// ==========================================
final nfcServiceProvider = Provider<NfcService>((ref) {
  return NfcService();
});

final deepLinkServiceProvider = Provider<DeepLinkService>((ref) {
  return DeepLinkService();
});

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

final backupServiceProvider = Provider<BackupService>((ref) {
  return BackupService(
    noteRepository: ref.read(noteRepositoryProvider),
    settingsRepository: ref.read(settingsRepositoryProvider),
  );
});

final aiServiceProvider = Provider<AiService>((ref) {
  return AiService();
});

final searchServiceProvider = Provider<SearchService>((ref) {
  return SearchService(
    noteRepository: ref.read(noteRepositoryProvider),
  );
});

// ==========================================
// App Settings Providers
// ==========================================
final appSettingsProvider = StateNotifierProvider<AppSettingsNotifier, AsyncValue<AppSettingsModel>>((ref) {
  return AppSettingsNotifier(ref.read(settingsRepositoryProvider));
});

class AppSettingsNotifier extends StateNotifier<AsyncValue<AppSettingsModel>> {
  AppSettingsNotifier(this._repository) : super(const AsyncValue.loading()) {
    _loadSettings();
  }

  final SettingsRepository _repository;

  Future<void> _loadSettings() async {
    try {
      final settings = await _repository.getSettings();
      state = AsyncValue.data(settings);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> updateSettings(AppSettingsModel settings) async {
    try {
      await _repository.saveSettings(settings);
      state = AsyncValue.data(settings);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> updateDefaultMode(String mode) async {
    final currentSettings = state.valueOrNull;
    if (currentSettings != null) {
      try {
        await _repository.updateDefaultMode(mode);
        final updatedSettings = currentSettings.copyWith(defaultMode: mode);
        state = AsyncValue.data(updatedSettings);
      } catch (error, stackTrace) {
        state = AsyncValue.error(error, stackTrace);
      }
    }
  }

  Future<void> updateThemeMode(int themeMode) async {
    final currentSettings = state.valueOrNull;
    if (currentSettings != null) {
      try {
        await _repository.updateThemeMode(themeMode);
        final updatedSettings = currentSettings.copyWith(themeMode: themeMode);
        state = AsyncValue.data(updatedSettings);
      } catch (error, stackTrace) {
        state = AsyncValue.error(error, stackTrace);
      }
    }
  }

  Future<void> toggleNotifications() async {
    final currentSettings = state.valueOrNull;
    if (currentSettings != null) {
      try {
        final newValue = !currentSettings.enableNotifications;
        await _repository.updateNotifications(newValue);
        final updatedSettings = currentSettings.copyWith(enableNotifications: newValue);
        state = AsyncValue.data(updatedSettings);
      } catch (error, stackTrace) {
        state = AsyncValue.error(error, stackTrace);
      }
    }
  }

  Future<void> toggleNfc() async {
    final currentSettings = state.valueOrNull;
    if (currentSettings != null) {
      try {
        final newValue = !currentSettings.enableNfc;
        await _repository.updateNfcSetting(newValue);
        final updatedSettings = currentSettings.copyWith(enableNfc: newValue);
        state = AsyncValue.data(updatedSettings);
      } catch (error, stackTrace) {
        state = AsyncValue.error(error, stackTrace);
      }
    }
  }

  Future<void> toggleAutoBackup() async {
    final currentSettings = state.valueOrNull;
    if (currentSettings != null) {
      try {
        final newValue = !currentSettings.autoBackup;
        await _repository.updateAutoBackup(newValue);
        final updatedSettings = currentSettings.copyWith(autoBackup: newValue);
        state = AsyncValue.data(updatedSettings);
      } catch (error, stackTrace) {
        state = AsyncValue.error(error, stackTrace);
      }
    }
  }

  Future<void> updateFontSize(double fontSize) async {
    final currentSettings = state.valueOrNull;
    if (currentSettings != null) {
      try {
        await _repository.updateFontSize(fontSize);
        final updatedSettings = currentSettings.copyWith(fontSize: fontSize);
        state = AsyncValue.data(updatedSettings);
      } catch (error, stackTrace) {
        state = AsyncValue.error(error, stackTrace);
      }
    }
  }
}

// Convenience providers for specific settings
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.system);

  void setThemeMode(ThemeMode mode) {
    state = mode;
  }

  void toggleTheme() {
    state = state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
  }
}

final currentModeProvider = Provider<String>((ref) {
  final settingsAsync = ref.watch(appSettingsProvider);
  return settingsAsync.when(
    data: (settings) => settings.defaultMode,
    loading: () => AppConstants.workMode,
    error: (_, __) => AppConstants.workMode,
  );
});

// ==========================================
// Notes Providers
// ==========================================
final notesProvider = StateNotifierProvider<NotesNotifier, AsyncValue<List<NoteModel>>>((ref) {
  return NotesNotifier(ref.read(noteRepositoryProvider));
});

class NotesNotifier extends StateNotifier<AsyncValue<List<NoteModel>>> {
  NotesNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadNotes();
  }

  final NoteRepository _repository;

  Future<void> loadNotes() async {
    state = const AsyncValue.loading();
    try {
      final notes = await _repository.getAllNotes();
      state = AsyncValue.data(notes);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> loadNotesByMode(String mode) async {
    state = const AsyncValue.loading();
    try {
      final notes = await _repository.getNotesByMode(mode);
      state = AsyncValue.data(notes);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> loadFavoriteNotes() async {
    state = const AsyncValue.loading();
    try {
      final allNotes = await _repository.getAllNotes();
      final notes = allNotes.where((note) => note.isFavorite).toList();
      state = AsyncValue.data(notes);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> loadArchivedNotes() async {
    state = const AsyncValue.loading();
    try {
      final allNotes = await _repository.getAllNotes();
      final notes = allNotes.where((note) => note.isArchived).toList();
      state = AsyncValue.data(notes);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> saveNote(NoteModel note) async {
    try {
      await _repository.saveNote(note);
      await loadNotes();
    } catch (error) {
      debugPrint('Error saving note: $error');
      rethrow;
    }
  }

  Future<void> deleteNote(String id) async {
    try {
      await _repository.deleteNote(id);
      await loadNotes();
    } catch (error) {
      debugPrint('Error deleting note: $error');
      rethrow;
    }
  }

  Future<NoteModel?> getNoteById(String id) async {
    try {
      return await _repository.getNoteById(id);
    } catch (error) {
      debugPrint('Error getting note: $error');
      return null;
    }
  }

  Future<void> archiveNote(String id) async {
    try {
      await _repository.archiveNote(id);
      await loadNotes();
    } catch (error) {
      debugPrint('Error archiving note: $error');
      rethrow;
    }
  }

  Future<void> toggleFavorite(String id) async {
    try {
      await _repository.toggleFavorite(id);
      await loadNotes();
    } catch (error) {
      debugPrint('Error toggling favorite: $error');
      rethrow;
    }
  }

  Future<void> searchNotes(String query, {String? mode}) async {
    state = const AsyncValue.loading();
    try {
      final notes = await _repository.searchNotes(query, mode: mode);
      state = AsyncValue.data(notes);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> loadNotesByTag(String tag) async {
    state = const AsyncValue.loading();
    try {
      final notes = await _repository.getNotesByTag(tag);
      state = AsyncValue.data(notes);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> deleteMultipleNotes(List<String> ids) async {
    try {
      await _repository.deleteMultipleNotes(ids);
      await loadNotes();
    } catch (error) {
      debugPrint('Error deleting multiple notes: $error');
      rethrow;
    }
  }

  Future<void> archiveMultipleNotes(List<String> ids) async {
    try {
      await _repository.archiveMultipleNotes(ids);
      await loadNotes();
    } catch (error) {
      debugPrint('Error archiving multiple notes: $error');
      rethrow;
    }
  }

  Future<void> clearAllNotes() async {
    try {
      await _repository.clearAllNotes();
      await loadNotes();
    } catch (error) {
      debugPrint('Error clearing all notes: $error');
      rethrow;
    }
  }
}

// Individual note provider
final noteProvider = FutureProviderFamily<NoteModel?, String>((ref, noteId) async {
  final repository = ref.read(noteRepositoryProvider);
  return await repository.getNoteById(noteId);
});

// Notes by mode provider
final notesByModeProvider = FutureProviderFamily<List<NoteModel>, String>((ref, mode) async {
  final repository = ref.read(noteRepositoryProvider);
  return await repository.getNotesByMode(mode);
});

// Recent notes provider
final recentNotesProvider = FutureProviderFamily<List<NoteModel>, int>((ref, days) async {
  final repository = ref.read(noteRepositoryProvider);
  return await repository.getRecentNotes(days: days);
});

// Tags provider
final tagsProvider = FutureProvider<List<String>>((ref) async {
  final repository = ref.read(noteRepositoryProvider);
  return await repository.getAllTags();
});

// Notes statistics provider
final notesStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final repository = ref.read(noteRepositoryProvider);
  return await repository.getStatistics();
});

// ==========================================
// Search Providers
// ==========================================
final searchQueryProvider = StateProvider<String>((ref) => '');

final searchResultsProvider = FutureProvider<SearchResult>((ref) async {
  final query = ref.watch(searchQueryProvider);
  final searchService = ref.read(searchServiceProvider);
  
  if (query.trim().isEmpty) {
    return SearchResult.empty();
  }
  
  return await searchService.searchNotes(query: query);
});

final searchSuggestionsProvider = FutureProviderFamily<List<String>, String>((ref, partialQuery) async {
  final searchService = ref.read(searchServiceProvider);
  return await searchService.getSearchSuggestions(partialQuery);
});

// ==========================================
// UI State Providers
// ==========================================
final selectedNotesProvider = StateNotifierProvider<SelectedNotesNotifier, Set<String>>((ref) {
  return SelectedNotesNotifier();
});

class SelectedNotesNotifier extends StateNotifier<Set<String>> {
  SelectedNotesNotifier() : super(<String>{});

  void toggleSelection(String noteId) {
    if (state.contains(noteId)) {
      state = Set.from(state)..remove(noteId);
    } else {
      state = Set.from(state)..add(noteId);
    }
  }

  void selectAll(List<String> noteIds) {
    state = Set.from(noteIds);
  }

  void clearSelection() {
    state = <String>{};
  }

  bool isSelected(String noteId) {
    return state.contains(noteId);
  }

  bool get hasSelection => state.isNotEmpty;
  int get selectionCount => state.length;
}

// Current view mode provider
final viewModeProvider = StateProvider<ViewMode>((ref) => ViewMode.list);

enum ViewMode { list, grid, card }

// Filter state provider
final filterStateProvider = StateNotifierProvider<FilterStateNotifier, FilterState>((ref) {
  return FilterStateNotifier();
});

class FilterStateNotifier extends StateNotifier<FilterState> {
  FilterStateNotifier() : super(FilterState.initial());

  void updateMode(String? mode) {
    state = state.copyWith(mode: mode);
  }

  void updateFavoriteOnly(bool favoriteOnly) {
    state = state.copyWith(favoriteOnly: favoriteOnly);
  }

  void updatePriority(int? priority) {
    state = state.copyWith(priority: priority);
  }

  void updateDateRange(DateTime? from, DateTime? to) {
    state = state.copyWith(dateFrom: from, dateTo: to);
  }

  void updateTags(List<String> tags) {
    state = state.copyWith(selectedTags: tags);
  }

  void clearFilters() {
    state = FilterState.initial();
  }

  bool get hasActiveFilters => state.hasActiveFilters;
}

class FilterState {
  final String? mode;
  final bool favoriteOnly;
  final int? priority;
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final List<String> selectedTags;

  FilterState({
    this.mode,
    this.favoriteOnly = false,
    this.priority,
    this.dateFrom,
    this.dateTo,
    this.selectedTags = const [],
  });

  factory FilterState.initial() {
    return FilterState();
  }

  FilterState copyWith({
    String? mode,
    bool? favoriteOnly,
    int? priority,
    DateTime? dateFrom,
    DateTime? dateTo,
    List<String>? selectedTags,
  }) {
    return FilterState(
      mode: mode ?? this.mode,
      favoriteOnly: favoriteOnly ?? this.favoriteOnly,
      priority: priority ?? this.priority,
      dateFrom: dateFrom ?? this.dateFrom,
      dateTo: dateTo ?? this.dateTo,
      selectedTags: selectedTags ?? this.selectedTags,
    );
  }

  bool get hasActiveFilters {
    return mode != null ||
           favoriteOnly ||
           priority != null ||
           dateFrom != null ||
           dateTo != null ||
           selectedTags.isNotEmpty;
  }
}

// ==========================================
// NFC & Deep Link Providers
// ==========================================
final nfcStateProvider = StateNotifierProvider<NfcStateNotifier, NfcState>((ref) {
  return NfcStateNotifier(ref.read(nfcServiceProvider));
});

class NfcStateNotifier extends StateNotifier<NfcState> {
  NfcStateNotifier(this._nfcService) : super(NfcState.initial()) {
    _checkNfcAvailability();
  }

  final NfcService _nfcService;

  Future<void> _checkNfcAvailability() async {
    try {
      final isEnabled = await _nfcService.isNfcEnabled();
      state = state.copyWith(isAvailable: isEnabled, isChecking: false);
    } catch (e) {
      state = state.copyWith(isAvailable: false, isChecking: false, error: e.toString());
    }
  }

  Future<void> readNfcTag() async {
    state = state.copyWith(isReading: true, error: null);
    try {
      final result = await _nfcService.readNfcTag();
      if (result.success) {
        final mode = _nfcService.extractModeFromUri(result.data!);
        state = state.copyWith(
          isReading: false,
          lastReadData: result.data,
          lastReadMode: mode,
        );
      } else {
        state = state.copyWith(isReading: false, error: result.error);
      }
    } catch (e) {
      state = state.copyWith(isReading: false, error: e.toString());
    }
  }

  Future<void> writeNfcTag(String uri) async {
    state = state.copyWith(isWriting: true, error: null);
    try {
      final result = await _nfcService.writeNfcTag(uri);
      if (result.success) {
        state = state.copyWith(isWriting: false, lastWriteSuccess: true);
      } else {
        state = state.copyWith(isWriting: false, error: result.error);
      }
    } catch (e) {
      state = state.copyWith(isWriting: false, error: e.toString());
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  void clearLastRead() {
    state = state.copyWith(lastReadData: null, lastReadMode: null);
  }
}

class NfcState {
  final bool isAvailable;
  final bool isChecking;
  final bool isReading;
  final bool isWriting;
  final String? lastReadData;
  final String? lastReadMode;
  final bool lastWriteSuccess;
  final String? error;

  NfcState({
    required this.isAvailable,
    required this.isChecking,
    required this.isReading,
    required this.isWriting,
    this.lastReadData,
    this.lastReadMode,
    this.lastWriteSuccess = false,
    this.error,
  });

  factory NfcState.initial() {
    return NfcState(
      isAvailable: false,
      isChecking: true,
      isReading: false,
      isWriting: false,
    );
  }

  NfcState copyWith({
    bool? isAvailable,
    bool? isChecking,
    bool? isReading,
    bool? isWriting,
    String? lastReadData,
    String? lastReadMode,
    bool? lastWriteSuccess,
    String? error,
  }) {
    return NfcState(
      isAvailable: isAvailable ?? this.isAvailable,
      isChecking: isChecking ?? this.isChecking,
      isReading: isReading ?? this.isReading,
      isWriting: isWriting ?? this.isWriting,
      lastReadData: lastReadData ?? this.lastReadData,
      lastReadMode: lastReadMode ?? this.lastReadMode,
      lastWriteSuccess: lastWriteSuccess ?? this.lastWriteSuccess,
      error: error ?? this.error,
    );
  }
}

// Deep link state provider
final deepLinkStateProvider = StateNotifierProvider<DeepLinkStateNotifier, DeepLinkState>((ref) {
  return DeepLinkStateNotifier(ref.read(deepLinkServiceProvider));
});

class DeepLinkStateNotifier extends StateNotifier<DeepLinkState> {
  DeepLinkStateNotifier(this._deepLinkService) : super(DeepLinkState.initial()) {
    _initializeDeepLinks();
  }

  final DeepLinkService _deepLinkService;

  void _initializeDeepLinks() {
    _deepLinkService.startListening((uri) {
      final linkData = _deepLinkService.parseDeepLink(uri);
      if (linkData != null) {
        state = state.copyWith(
          lastDeepLink: linkData,
          hasUnhandledLink: true,
        );
      }
    });

    // Check for initial link
    _deepLinkService.getInitialLink().then((uri) {
      if (uri != null) {
        final linkData = _deepLinkService.parseDeepLink(uri);
        if (linkData != null) {
          state = state.copyWith(
            lastDeepLink: linkData,
            hasUnhandledLink: true,
          );
        }
      }
    });
  }

  void markLinkAsHandled() {
    state = state.copyWith(hasUnhandledLink: false);
  }

  void clearLastLink() {
    state = state.copyWith(lastDeepLink: null, hasUnhandledLink: false);
  }

  @override
  void dispose() {
    _deepLinkService.stopListening();
    super.dispose();
  }
}

class DeepLinkState {
  final DeepLinkData? lastDeepLink;
  final bool hasUnhandledLink;

  DeepLinkState({
    this.lastDeepLink,
    this.hasUnhandledLink = false,
  });

  factory DeepLinkState.initial() {
    return DeepLinkState();
  }

  DeepLinkState copyWith({
    DeepLinkData? lastDeepLink,
    bool? hasUnhandledLink,
  }) {
    return DeepLinkState(
      lastDeepLink: lastDeepLink ?? this.lastDeepLink,
      hasUnhandledLink: hasUnhandledLink ?? this.hasUnhandledLink,
    );
  }
}

// ==========================================
// AI Providers
// ==========================================
final aiServiceStateProvider = StateNotifierProvider<AiServiceStateNotifier, AiServiceState>((ref) {
  return AiServiceStateNotifier(ref.read(aiServiceProvider));
});

class AiServiceStateNotifier extends StateNotifier<AiServiceState> {
  AiServiceStateNotifier(this._aiService) : super(AiServiceState.initial());

  final AiService _aiService;

  Future<void> generateSummary(String content) async {
    state = state.copyWith(isGeneratingSummary: true, summaryError: null);
    try {
      final summary = await _aiService.generateSummary(content);
      state = state.copyWith(
        isGeneratingSummary: false,
        lastGeneratedSummary: summary,
      );
    } catch (e) {
      state = state.copyWith(
        isGeneratingSummary: false,
        summaryError: e.toString(),
      );
    }
  }

  Future<void> suggestTags(String content) async {
    state = state.copyWith(isSuggestingTags: true, tagsError: null);
    try {
      final tags = await _aiService.suggestTags(content);
      state = state.copyWith(
        isSuggestingTags: false,
        suggestedTags: tags,
      );
    } catch (e) {
      state = state.copyWith(
        isSuggestingTags: false,
        tagsError: e.toString(),
      );
    }
  }

  Future<void> analyzeSentiment(String content) async {
    state = state.copyWith(isAnalyzingSentiment: true, sentimentError: null);
    try {
      final sentiment = await _aiService.analyzeSentiment(content);
      state = state.copyWith(
        isAnalyzingSentiment: false,
        lastSentiment: sentiment,
      );
    } catch (e) {
      state = state.copyWith(
        isAnalyzingSentiment: false,
        sentimentError: e.toString(),
      );
    }
  }

  void clearSummary() {
    state = state.copyWith(lastGeneratedSummary: null, summaryError: null);
  }

  void clearTags() {
    state = state.copyWith(suggestedTags: [], tagsError: null);
  }

  void clearSentiment() {
    state = state.copyWith(lastSentiment: null, sentimentError: null);
  }
}

class AiServiceState {
  final bool isGeneratingSummary;
  final bool isSuggestingTags;
  final bool isAnalyzingSentiment;
  final String? lastGeneratedSummary;
  final List<String> suggestedTags;
  final NoteSentiment? lastSentiment;
  final String? summaryError;
  final String? tagsError;
  final String? sentimentError;

  AiServiceState({
    required this.isGeneratingSummary,
    required this.isSuggestingTags,
    required this.isAnalyzingSentiment,
    this.lastGeneratedSummary,
    this.suggestedTags = const [],
    this.lastSentiment,
    this.summaryError,
    this.tagsError,
    this.sentimentError,
  });

  factory AiServiceState.initial() {
    return AiServiceState(
      isGeneratingSummary: false,
      isSuggestingTags: false,
      isAnalyzingSentiment: false,
    );
  }

  AiServiceState copyWith({
    bool? isGeneratingSummary,
    bool? isSuggestingTags,
    bool? isAnalyzingSentiment,
    String? lastGeneratedSummary,
    List<String>? suggestedTags,
    NoteSentiment? lastSentiment,
    String? summaryError,
    String? tagsError,
    String? sentimentError,
  }) {
    return AiServiceState(
      isGeneratingSummary: isGeneratingSummary ?? this.isGeneratingSummary,
      isSuggestingTags: isSuggestingTags ?? this.isSuggestingTags,
      isAnalyzingSentiment: isAnalyzingSentiment ?? this.isAnalyzingSentiment,
      lastGeneratedSummary: lastGeneratedSummary ?? this.lastGeneratedSummary,
      suggestedTags: suggestedTags ?? this.suggestedTags,
      lastSentiment: lastSentiment ?? this.lastSentiment,
      summaryError: summaryError ?? this.summaryError,
      tagsError: tagsError ?? this.tagsError,
      sentimentError: sentimentError ?? this.sentimentError,
    );
  }
}

// ==========================================
// Backup Providers
// ==========================================
final backupStatsProvider = FutureProvider<BackupStats>((ref) async {
  final backupService = ref.read(backupServiceProvider);
  return await backupService.getBackupStats();
});

// ==========================================
// Utility Providers
// ==========================================
// Loading state provider for global operations
final globalLoadingProvider = StateProvider<bool>((ref) => false);

// Error message provider for global error handling
final globalErrorProvider = StateProvider<String?>((ref) => null);

// App initialization provider
final appInitializationProvider = FutureProvider<bool>((ref) async {
  try {
    // Initialize services
    final notificationService = ref.read(notificationServiceProvider);
    await notificationService.initialize();
    
    // Load initial settings
    ref.read(appSettingsProvider);
    
    return true;
  } catch (e) {
    debugPrint('App initialization error: $e');
    return false;
  }
});

// Add sync providers
final userIdProvider = Provider<String>((ref) {
  // Generate or retrieve user ID
  final box = Hive.box(AppConstants.settingsBox);
  String? userId = box.get('user_id');
  if (userId == null) {
    userId = const Uuid().v4();
    box.put('user_id', userId);
  }
  return userId;
});

final apiServiceProvider = Provider<ApiService>((ref) {
  final userId = ref.watch(userIdProvider);
  return ApiService(userId: userId);
});

final syncServiceProvider = Provider<SyncService>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  final noteRepository = ref.watch(noteRepositoryProvider);
  return SyncService(
    apiService: apiService,
    noteRepository: noteRepository,
  );
});

// Add connectivity provider
final connectivityProvider = StreamProvider<ConnectivityResult>((ref) {
  final syncService = ref.watch(syncServiceProvider);
  return syncService.connectivityStream;
});

// Add sync status provider
final syncStatusProvider = StateNotifierProvider<SyncStatusNotifier, SyncStatus>((ref) {
  return SyncStatusNotifier(ref.watch(syncServiceProvider));
});
class SyncStatus {
  final bool isSyncing;
  final bool isOnline;
  final DateTime? lastSyncTime;
  final String? error;
  
  SyncStatus({
    this.isSyncing = false,
    this.isOnline = false,
    this.lastSyncTime,
    this.error,
  });
  SyncStatus copyWith({
    bool? isSyncing,
    bool? isOnline,
    DateTime? lastSyncTime,
    String? error,
  }) {
    return SyncStatus(
      isSyncing: isSyncing ?? this.isSyncing,
      isOnline: isOnline ?? this.isOnline,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      error: error ?? this.error,
    );
  }
}
class SyncStatusNotifier extends StateNotifier<SyncStatus> {
  final SyncService _syncService;
  Timer? _syncTimer;
  
  SyncStatusNotifier(this._syncService) : super(SyncStatus()) {
    _initSync();
  }
  
  void _initSync() {
    // Auto-sync every 30 seconds
    _syncTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      syncNotes();
    });
    
    // Initial sync
    syncNotes();
  }
  
  Future<void> syncNotes() async {
    state = state.copyWith(isSyncing: true, error: null);    
    try {
      final isOnline = await _syncService.isOnline;
      if (isOnline) {
        await _syncService.syncNotes();
        state = state.copyWith(
          isSyncing: false,
          isOnline: true,
          lastSyncTime: DateTime.now(),
          error: null,
        );
      } else {
        state = state.copyWith(isSyncing: false, isOnline: false);
      }
    } catch (e) {
      state = state.copyWith(
        isSyncing: false,
        isOnline: await _syncService.isOnline,
        error: e.toString(),
      );
    }
  }
  
  @override
  void dispose() {
    _syncTimer?.cancel();
    super.dispose();
  }
}
