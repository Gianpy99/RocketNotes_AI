import 'package:pensieve/data/models/app_settings_model.dart';
import 'package:pensieve/data/repositories/settings_repository.dart';

/// Mock settings repository for testing
class MockSettingsRepository extends SettingsRepository {
  AppSettingsModel _settings;

  MockSettingsRepository(this._settings);

  @override
  Future<AppSettingsModel> getSettings() async {
    return _settings;
  }

  @override
  Future<void> saveSettings(AppSettingsModel settings) async {
    _settings = settings;
  }

  @override
  Future<void> updateDefaultMode(String mode) async {
    _settings = _settings.copyWith(defaultMode: mode);
  }

  @override
  Future<void> updateThemeMode(int themeMode) async {
    _settings = _settings.copyWith(themeMode: themeMode);
  }

  @override
  Future<void> updateNotifications(bool enable) async {
    _settings = _settings.copyWith(enableNotifications: enable);
  }

  @override
  Future<void> updateNfcSetting(bool enable) async {
    _settings = _settings.copyWith(enableNfc: enable);
  }

  @override
  Future<void> updateAutoBackup(bool enable) async {
    _settings = _settings.copyWith(autoBackup: enable);
  }

  @override
  Future<void> updateFontSize(double size) async {
    _settings = _settings.copyWith(fontSize: size);
  }
}
