// ==========================================
// lib/features/security/providers/biometric_lock_provider.dart
// ==========================================
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../data/models/app_settings_model.dart';
import '../../../presentation/providers/app_providers.dart';
import '../../family/services/biometric_auth_service.dart';

/// Provider per lo stato di blocco dell'app
final appLockedProvider = StateProvider<bool>((ref) {
  // L'app è bloccata all'avvio se la biometria è abilitata
  final settings = ref.watch(appSettingsProvider);
  return settings.value?.enableBiometric ?? false;
});

/// Provider per verificare se il blocco biometrico è abilitato
final biometricLockEnabledProvider = Provider<bool>((ref) {
  final settings = ref.watch(appSettingsProvider);
  return settings.value?.enableBiometric ?? false;
});

/// Provider per gestire le impostazioni del blocco biometrico
class BiometricLockNotifier extends StateNotifier<bool> {
  final Ref _ref;
  
  BiometricLockNotifier(this._ref) : super(false) {
    _loadState();
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool('biometric_lock_enabled') ?? false;
  }

  Future<void> enable() async {
    final service = _ref.read(biometricAuthServiceProvider);
    
    // Verifica disponibilità
    final isAvailable = await service.isBiometricAvailable();
    if (!isAvailable) {
      throw Exception('Autenticazione biometrica non disponibile');
    }

    // Test autenticazione
    final authenticated = await service.authenticate(
      reason: 'Conferma per abilitare il blocco biometrico',
    );

    if (!authenticated) {
      throw Exception('Autenticazione fallita');
    }

    // Salva preferenza
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('biometric_lock_enabled', true);
    state = true;

    // Aggiorna le impostazioni dell'app
    final settings = _ref.read(appSettingsProvider).value;
    if (settings != null) {
      final updatedSettings = AppSettingsModel(
        defaultMode: settings.defaultMode,
        themeMode: settings.themeMode,
        enableNotifications: settings.enableNotifications,
        enableNfc: settings.enableNfc,
        autoBackup: settings.autoBackup,
        lastBackupDate: settings.lastBackupDate,
        backupLocation: settings.backupLocation,
        enableAi: settings.enableAi,
        fontSize: settings.fontSize,
        enableBiometric: true, // Abilita biometria
        pinnedTags: settings.pinnedTags,
        showStats: settings.showStats,
        ocrProvider: settings.ocrProvider,
        aiProvider: settings.aiProvider,
        textSummarizationModel: settings.textSummarizationModel,
        imageAnalysisModel: settings.imageAnalysisModel,
        openAIServiceTier: settings.openAIServiceTier,
        audioTranscriptionModel: settings.audioTranscriptionModel,
        autoQuickCaptureAI: settings.autoQuickCaptureAI,
      );
      await _ref.read(appSettingsProvider.notifier).updateSettings(updatedSettings);
    }
  }

  Future<void> disable() async {
    final service = _ref.read(biometricAuthServiceProvider);
    
    // Richiedi autenticazione per disabilitare
    final authenticated = await service.authenticate(
      reason: 'Conferma per disabilitare il blocco biometrico',
    );

    if (!authenticated) {
      throw Exception('Autenticazione fallita');
    }

    // Rimuovi preferenza
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('biometric_lock_enabled', false);
    state = false;

    // Aggiorna le impostazioni dell'app
    final settings = _ref.read(appSettingsProvider).value;
    if (settings != null) {
      final updatedSettings = AppSettingsModel(
        defaultMode: settings.defaultMode,
        themeMode: settings.themeMode,
        enableNotifications: settings.enableNotifications,
        enableNfc: settings.enableNfc,
        autoBackup: settings.autoBackup,
        lastBackupDate: settings.lastBackupDate,
        backupLocation: settings.backupLocation,
        enableAi: settings.enableAi,
        fontSize: settings.fontSize,
        enableBiometric: false, // Disabilita biometria
        pinnedTags: settings.pinnedTags,
        showStats: settings.showStats,
        ocrProvider: settings.ocrProvider,
        aiProvider: settings.aiProvider,
        textSummarizationModel: settings.textSummarizationModel,
        imageAnalysisModel: settings.imageAnalysisModel,
        openAIServiceTier: settings.openAIServiceTier,
        audioTranscriptionModel: settings.audioTranscriptionModel,
        autoQuickCaptureAI: settings.autoQuickCaptureAI,
      );
      await _ref.read(appSettingsProvider.notifier).updateSettings(updatedSettings);
    }
  }

  Future<void> toggle() async {
    if (state) {
      await disable();
    } else {
      await enable();
    }
  }
}

final biometricLockNotifierProvider = StateNotifierProvider<BiometricLockNotifier, bool>((ref) {
  return BiometricLockNotifier(ref);
});
