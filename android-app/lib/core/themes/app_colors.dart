import 'package:flutter/material.dart';

class AppColors {
  // Mode colors
  static const Color workBlue = Color(0xFF1976D2);
  static const Color personalGreen = Color(0xFF388E3C);
  
  // Primary colors
  static const Color primaryBlue = Color(0xFF2196F3);
  static const Color primaryGreen = Color(0xFF4CAF50);
  static const Color primary = primaryBlue; // Default primary
  
  // Background colors
  static const Color lightBackground = Color(0xFFF5F5F5);
  static const Color darkBackground = Color(0xFF121212);
  static const Color backgroundLight = lightBackground;
  static const Color backgroundDark = darkBackground;
  
  // Surface colors
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color darkCard = Color(0xFF1E1E1E);
  static const Color surfaceLight = lightCard;
  static const Color surfaceDark = darkCard;
  static const Color surface = lightCard; // Default surface
  
  // Text colors
  static const Color lightText = Color(0xFF212121);
  static const Color darkText = Color(0xFFFFFFFF);
  static const Color secondaryText = Color(0xFF757575);
  static const Color textPrimaryLight = lightText;
  static const Color textPrimaryDark = darkText;
  static const Color textSecondaryLight = secondaryText;
  static const Color textSecondaryDark = Color(0xFFB0B0B0);
  
  // Gradients
  static const List<Color> lightGradient = [
    Color(0xFFF5F7FA),
    Color(0xFFC3CFE2),
  ];
  
  static const List<Color> darkGradient = [
    Color(0xFF232526),
    Color(0xFF414345),
  ];
  
  // Accent colors
  static const Color accent = Color(0xFFFF5722);
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFC107);
  static const Color error = Color(0xFFF44336);
  
  // Tag colors
  static const List<Color> tagColors = [
    Color(0xFFE3F2FD), // Light Blue
    Color(0xFFE8F5E8), // Light Green
    Color(0xFFFFF3E0), // Light Orange
    Color(0xFFF3E5F5), // Light Purple
    Color(0xFFFFEBEE), // Light Red
    Color(0xFFE0F2F1), // Light Teal
    Color(0xFFFFF8E1), // Light Yellow
    Color(0xFFE1F5FE), // Light Cyan
  ];
  
  // Get mode color with opacity
  static Color getModeColor(String mode, [double opacity = 1.0]) {
    final color = mode == 'work' ? workBlue : personalGreen;
    return opacity == 1.0 ? color : color.withValues(alpha: opacity);
  }
  
  // Get tag color by index
  static Color getTagColor(int index) {
    return tagColors[index % tagColors.length];
  }
}
