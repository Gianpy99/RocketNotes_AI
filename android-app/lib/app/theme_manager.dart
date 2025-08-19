// ==========================================
// lib/app/theme_manager.dart
// ==========================================
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/themes/app_theme.dart';

class ThemeManager {
  // Update system UI overlay style based on theme
  static void updateSystemUIOverlay(ThemeMode themeMode, BuildContext context) {
    final brightness = _getEffectiveBrightness(themeMode, context);
    
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: brightness == Brightness.light 
            ? Brightness.dark 
            : Brightness.light,
        statusBarBrightness: brightness,
        systemNavigationBarColor: brightness == Brightness.light
            ? Colors.white
            : const Color(0xFF121212),
        systemNavigationBarIconBrightness: brightness == Brightness.light
            ? Brightness.dark
            : Brightness.light,
      ),
    );
  }

  static Brightness _getEffectiveBrightness(ThemeMode themeMode, BuildContext context) {
    switch (themeMode) {
      case ThemeMode.light:
        return Brightness.light;
      case ThemeMode.dark:
        return Brightness.dark;
      case ThemeMode.system:
        return MediaQuery.of(context).platformBrightness;
    }
  }

  // Get current theme data
  static ThemeData getCurrentTheme(ThemeMode themeMode, BuildContext context) {
    final brightness = _getEffectiveBrightness(themeMode, context);
    return brightness == Brightness.light 
        ? AppTheme.lightTheme 
        : AppTheme.darkTheme;
  }
}
