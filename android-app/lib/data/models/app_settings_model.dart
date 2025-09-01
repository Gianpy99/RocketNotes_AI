// ==========================================
// lib/data/models/app_settings_model.dart
// ==========================================
import 'package:hive/hive.dart';
import 'package:flutter/material.dart';

part 'app_settings_model.g.dart';

@HiveType(typeId: 1)
class AppSettingsModel extends HiveObject {
  @HiveField(0)
  String defaultMode;
  
  @HiveField(1)
  int themeMode; // 0 = system, 1 = light, 2 = dark
  
  @HiveField(2)
  bool enableNotifications;
  
  @HiveField(3)
  bool enableNfc;
  
  @HiveField(4)
  bool autoBackup;
  
  @HiveField(5)
  DateTime? lastBackupDate;
  
  @HiveField(6)
  String? backupLocation;
  
  @HiveField(7)
  bool enableAi;
  
  @HiveField(8)
  double fontSize;
  
  @HiveField(9)
  bool enableBiometric;
  
  @HiveField(10)
  List<String> pinnedTags;
  
  @HiveField(11)
  bool showStats;

  AppSettingsModel({
    this.defaultMode = 'work',
    this.themeMode = 0,
    this.enableNotifications = true,
    this.enableNfc = true,
    this.autoBackup = false,
    this.lastBackupDate,
    this.backupLocation,
    this.enableAi = true,
    this.fontSize = 14.0,
    this.enableBiometric = false,
    this.pinnedTags = const [],
    this.showStats = true,
  });

  // Factory constructor with defaults
  factory AppSettingsModel.defaults() {
    return AppSettingsModel(
      defaultMode: 'work',
      themeMode: 0, // System theme
      enableNotifications: true,
      enableNfc: true,
      autoBackup: false,
      enableAi: true,
      fontSize: 14.0,
      enableBiometric: false,
      pinnedTags: [],
      showStats: true,
    );
  }

  // Copy with method
  AppSettingsModel copyWith({
    String? defaultMode,
    int? themeMode,
    bool? enableNotifications,
    bool? enableNfc,
    bool? autoBackup,
    DateTime? lastBackupDate,
    String? backupLocation,
    bool? enableAi,
    double? fontSize,
    bool? enableBiometric,
    List<String>? pinnedTags,
    bool? showStats,
  }) {
    return AppSettingsModel(
      defaultMode: defaultMode ?? this.defaultMode,
      themeMode: themeMode ?? this.themeMode,
      enableNotifications: enableNotifications ?? this.enableNotifications,
      enableNfc: enableNfc ?? this.enableNfc,
      autoBackup: autoBackup ?? this.autoBackup,
      lastBackupDate: lastBackupDate ?? this.lastBackupDate,
      backupLocation: backupLocation ?? this.backupLocation,
      enableAi: enableAi ?? this.enableAi,
      fontSize: fontSize ?? this.fontSize,
      enableBiometric: enableBiometric ?? this.enableBiometric,
      pinnedTags: pinnedTags ?? this.pinnedTags,
      showStats: showStats ?? this.showStats,
    );
  }

  // Utility getters
  ThemeMode get flutterThemeMode {
    switch (themeMode) {
      case 1:
        return ThemeMode.light;
      case 2:
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  // Alias for compatibility
  bool get aiEnabled => enableAi;

  // JSON serialization
  Map<String, dynamic> toJson() {
    return {
      'defaultMode': defaultMode,
      'themeMode': themeMode,
      'enableNotifications': enableNotifications,
      'enableNfc': enableNfc,
      'autoBackup': autoBackup,
      'lastBackupDate': lastBackupDate?.toIso8601String(),
      'backupLocation': backupLocation,
      'enableAi': enableAi,
      'fontSize': fontSize,
      'enableBiometric': enableBiometric,
      'pinnedTags': pinnedTags,
      'showStats': showStats,
    };
  }

  factory AppSettingsModel.fromJson(Map<String, dynamic> json) {
    return AppSettingsModel(
      defaultMode: json['defaultMode'] as String? ?? 'work',
      themeMode: json['themeMode'] as int? ?? 0,
      enableNotifications: json['enableNotifications'] as bool? ?? true,
      enableNfc: json['enableNfc'] as bool? ?? true,
      autoBackup: json['autoBackup'] as bool? ?? false,
      lastBackupDate: json['lastBackupDate'] != null
          ? DateTime.parse(json['lastBackupDate'] as String)
          : null,
      backupLocation: json['backupLocation'] as String?,
      enableAi: json['enableAi'] as bool? ?? true,
      fontSize: (json['fontSize'] as num?)?.toDouble() ?? 14.0,
      enableBiometric: json['enableBiometric'] as bool? ?? false,
      pinnedTags: List<String>.from(json['pinnedTags'] as List? ?? []),
      showStats: json['showStats'] as bool? ?? true,
    );
  }
}
