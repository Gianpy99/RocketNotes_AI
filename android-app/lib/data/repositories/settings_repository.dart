// ==========================================
// lib/data/repositories/settings_repository.dart
// ==========================================
import 'package:hive/hive.dart';
import '../models/app_settings_model.dart';
import '../../core/constants/app_constants.dart';

class SettingsRepository {
  Box<AppSettingsModel>? _settingsBox;
  static const String _settingsKey = 'app_settings';

  Box<AppSettingsModel> get settingsBox {
    if (_settingsBox == null || !_settingsBox!.isOpen) {
      try {
        _settingsBox = Hive.box<AppSettingsModel>(AppConstants.settingsBox);
      } catch (e) {
        throw Exception('Settings box not found. Make sure Hive is properly initialized: $e');
      }
    }
    return _settingsBox!;
  }

  // Get settings
  Future<AppSettingsModel> getSettings() async {
    try {
      final settings = settingsBox.get(_settingsKey);
      return settings ?? AppSettingsModel.defaults();
    } catch (e) {
      return AppSettingsModel.defaults();
    }
  }

  // Save settings
  Future<void> saveSettings(AppSettingsModel settings) async {
    try {
      await settingsBox.put(_settingsKey, settings);
    } catch (e) {
      throw Exception('Failed to save settings: $e');
    }
  }

  // Update specific setting
  Future<void> updateDefaultMode(String mode) async {
    try {
      final settings = await getSettings();
      final updatedSettings = settings.copyWith(defaultMode: mode);
      await saveSettings(updatedSettings);
    } catch (e) {
      throw Exception('Failed to update default mode: $e');
    }
  }

  Future<void> updateThemeMode(int themeMode) async {
    try {
      final settings = await getSettings();
      final updatedSettings = settings.copyWith(themeMode: themeMode);
      await saveSettings(updatedSettings);
    } catch (e) {
      throw Exception('Failed to update theme mode: $e');
    }
  }

  Future<void> updateNotifications(bool enabled) async {
    try {
      final settings = await getSettings();
      final updatedSettings = settings.copyWith(enableNotifications: enabled);
      await saveSettings(updatedSettings);
    } catch (e) {
      throw Exception('Failed to update notifications setting: $e');
    }
  }

  Future<void> updateNfcSetting(bool enabled) async {
    try {
      final settings = await getSettings();
      final updatedSettings = settings.copyWith(enableNfc: enabled);
      await saveSettings(updatedSettings);
    } catch (e) {
      throw Exception('Failed to update NFC setting: $e');
    }
  }

  Future<void> updateAutoBackup(bool enabled) async {
    try {
      final settings = await getSettings();
      final updatedSettings = settings.copyWith(autoBackup: enabled);
      await saveSettings(updatedSettings);
    } catch (e) {
      throw Exception('Failed to update auto backup setting: $e');
    }
  }

  Future<void> updateFontSize(double fontSize) async {
    try {
      final settings = await getSettings();
      final updatedSettings = settings.copyWith(fontSize: fontSize);
      await saveSettings(updatedSettings);
    } catch (e) {
      throw Exception('Failed to update font size: $e');
    }
  }

  Future<void> updateBiometric(bool enabled) async {
    try {
      final settings = await getSettings();
      final updatedSettings = settings.copyWith(enableBiometric: enabled);
      await saveSettings(updatedSettings);
    } catch (e) {
      throw Exception('Failed to update biometric setting: $e');
    }
  }

  Future<void> updateLastBackupDate(DateTime date) async {
    try {
      final settings = await getSettings();
      final updatedSettings = settings.copyWith(lastBackupDate: date);
      await saveSettings(updatedSettings);
    } catch (e) {
      throw Exception('Failed to update last backup date: $e');
    }
  }

  Future<void> updateOcrProvider(String provider) async {
    try {
      final settings = await getSettings();
      final updatedSettings = settings.copyWith(ocrProvider: provider);
      await saveSettings(updatedSettings);
    } catch (e) {
      throw Exception('Failed to update OCR provider: $e');
    }
  }

  Future<void> updateAiProvider(String provider) async {
    try {
      final settings = await getSettings();
      
      // Set appropriate default models for each provider
      String textModel, imageModel, audioModel;
      switch (provider) {
        case 'openai':
          textModel = 'gpt-5-mini';
          imageModel = 'gpt-5-mini';
          audioModel = 'gpt-4o-mini-transcribe';
          break;
        case 'gemini':
          textModel = 'gemini-2.5-flash';
          imageModel = 'gemini-2.5-flash';
          audioModel = 'gemini-2.5-flash-native-audio';
          break;
        default:
          textModel = settings.effectiveTextSummarizationModel;
          imageModel = settings.effectiveImageAnalysisModel;
          audioModel = settings.effectiveAudioTranscriptionModel;
      }
      
      final updatedSettings = settings.copyWith(
        aiProvider: provider,
        textSummarizationModel: textModel,
        imageAnalysisModel: imageModel,
        audioTranscriptionModel: audioModel,
      );
      await saveSettings(updatedSettings);
    } catch (e) {
      throw Exception('Failed to update AI provider: $e');
    }
  }

  Future<void> updateTextSummarizationModel(String model) async {
    try {
      final settings = await getSettings();
      final updatedSettings = settings.copyWith(textSummarizationModel: model);
      await saveSettings(updatedSettings);
    } catch (e) {
      throw Exception('Failed to update text summarization model: $e');
    }
  }

  Future<void> updateImageAnalysisModel(String model) async {
    try {
      final settings = await getSettings();
      final updatedSettings = settings.copyWith(imageAnalysisModel: model);
      await saveSettings(updatedSettings);
    } catch (e) {
      throw Exception('Failed to update image analysis model: $e');
    }
  }

  // Generic setting update method
  Future<void> updateSetting(String key, dynamic value) async {
    try {
      final settings = await getSettings();
      AppSettingsModel updatedSettings;
      
      switch (key) {
        case 'defaultMode':
          updatedSettings = settings.copyWith(defaultMode: value as String);
          break;
        case 'themeMode':
          updatedSettings = settings.copyWith(themeMode: value as int);
          break;
        case 'enableNotifications':
          updatedSettings = settings.copyWith(enableNotifications: value as bool);
          break;
        case 'enableNfc':
          updatedSettings = settings.copyWith(enableNfc: value as bool);
          break;
        case 'autoBackup':
          updatedSettings = settings.copyWith(autoBackup: value as bool);
          break;
        case 'enableAi':
          updatedSettings = settings.copyWith(enableAi: value as bool);
          break;
        case 'fontSize':
          updatedSettings = settings.copyWith(fontSize: value as double);
          break;
        case 'enableBiometric':
          updatedSettings = settings.copyWith(enableBiometric: value as bool);
          break;
        case 'showStats':
          updatedSettings = settings.copyWith(showStats: value as bool);
          break;
        case 'ocrProvider':
          updatedSettings = settings.copyWith(ocrProvider: value as String);
          break;
        case 'aiProvider':
          updatedSettings = settings.copyWith(aiProvider: value as String);
          break;
        case 'textSummarizationModel':
          updatedSettings = settings.copyWith(textSummarizationModel: value as String);
          break;
        case 'imageAnalysisModel':
          updatedSettings = settings.copyWith(imageAnalysisModel: value as String);
          break;
        default:
          throw Exception('Unknown setting key: $key');
      }
      
      await saveSettings(updatedSettings);
    } catch (e) {
      throw Exception('Failed to update setting $key: $e');
    }
  }

  // General update method
  Future<void> updateSettings(AppSettingsModel settings) async {
    try {
      await saveSettings(settings);
    } catch (e) {
      throw Exception('Failed to update settings: $e');
    }
  }

  // Update OpenAI Service Tier
  Future<void> updateOpenAIServiceTier(String serviceTier) async {
    try {
      final settings = await getSettings();
      final updatedSettings = settings.copyWith(openAIServiceTier: serviceTier);
      await saveSettings(updatedSettings);
    } catch (e) {
      throw Exception('Failed to update OpenAI service tier: $e');
    }
  }

  // Update Audio Transcription Model
  Future<void> updateAudioTranscriptionModel(String model) async {
    try {
      final settings = await getSettings();
      final updatedSettings = settings.copyWith(audioTranscriptionModel: model);
      await saveSettings(updatedSettings);
    } catch (e) {
      throw Exception('Failed to update audio transcription model: $e');
    }
  }

  // Reset to defaults
  Future<void> resetToDefaults() async {
    try {
      await saveSettings(AppSettingsModel.defaults());
    } catch (e) {
      throw Exception('Failed to reset settings: $e');
    }
  }

  // Export settings
  Future<Map<String, dynamic>> exportSettings() async {
    try {
      final settings = await getSettings();
      return settings.toJson();
    } catch (e) {
      throw Exception('Failed to export settings: $e');
    }
  }

  // Import settings
  Future<void> importSettings(Map<String, dynamic> settingsData) async {
    try {
      final settings = AppSettingsModel.fromJson(settingsData);
      await saveSettings(settings);
    } catch (e) {
      throw Exception('Failed to import settings: $e');
    }
  }
}
