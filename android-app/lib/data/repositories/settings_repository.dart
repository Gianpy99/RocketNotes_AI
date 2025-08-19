// ==========================================
// lib/data/repositories/settings_repository.dart
// ==========================================
import 'package:hive/hive.dart';
import '../models/app_settings_model.dart';
import '../../core/constants/app_constants.dart';

class SettingsRepository {
  final Box<AppSettingsModel> _settingsBox = Hive.box<AppSettingsModel>(AppConstants.settingsBox);
  static const String _settingsKey = 'app_settings';

  // Get settings
  Future<AppSettingsModel> getSettings() async {
    try {
      final settings = _settingsBox.get(_settingsKey);
      return settings ?? AppSettingsModel.defaults();
    } catch (e) {
      return AppSettingsModel.defaults();
    }
  }

  // Save settings
  Future<void> saveSettings(AppSettingsModel settings) async {
    try {
      await _settingsBox.put(_settingsKey, settings);
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
