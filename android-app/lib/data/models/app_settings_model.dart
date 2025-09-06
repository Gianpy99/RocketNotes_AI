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

  @HiveField(12)
  String? ocrProvider; // Google ML Kit, TesseractOCR
  
  @HiveField(13)
  String? aiProvider; // openai, gemini

  @HiveField(14)
  String? textSummarizationModel; // AI model for text-to-text summarization
  
  @HiveField(15)
  String? imageAnalysisModel; // AI model for image-to-text analysis

  @HiveField(16)
  String? openAIServiceTier; // OpenAI service tier: flex, standard, priority

  @HiveField(17)
  String? audioTranscriptionModel; // AI model for audio transcription

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
    this.ocrProvider = 'google_ml_kit',
    this.aiProvider = 'openai',
    this.textSummarizationModel = 'gpt-5-mini',
    this.imageAnalysisModel = 'gpt-5-mini',
    this.openAIServiceTier = 'flex',
    this.audioTranscriptionModel = 'gpt-4o-mini-transcribe',
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
      ocrProvider: 'google_ml_kit',
      aiProvider: 'openai',
      textSummarizationModel: 'gpt-5-mini',
      imageAnalysisModel: 'gpt-5-mini',
      openAIServiceTier: 'flex',
      audioTranscriptionModel: 'gpt-4o-mini-transcribe',
    );
  }

  // Getters with default values for nullable fields
  String get effectiveOcrProvider => ocrProvider ?? 'google_ml_kit';
  String get effectiveAiProvider => aiProvider ?? 'openai';
  String get effectiveTextSummarizationModel => textSummarizationModel ?? 'gpt-5-mini';
  String get effectiveImageAnalysisModel => imageAnalysisModel ?? 'gpt-5-mini';
  String get effectiveOpenAIServiceTier => openAIServiceTier ?? 'flex';
  String get effectiveAudioTranscriptionModel => audioTranscriptionModel ?? 'gpt-4o-mini-transcribe';

  // Helper methods to get appropriate models for each provider
  String getDefaultTextModel(String provider) {
    switch (provider.toLowerCase()) {
      case 'gemini':
        return 'gemini-2.5-flash';
      case 'openai':
        return 'gpt-5-mini';
      case 'huggingface':
        return 'microsoft/DialoGPT-medium';
      default:
        return 'gpt-5-mini';
    }
  }

  String getDefaultImageModel(String provider) {
    switch (provider.toLowerCase()) {
      case 'gemini':
        return 'gemini-2.5-flash';
      case 'openai':
        return 'gpt-5-mini';
      case 'huggingface':
        return 'microsoft/DialoGPT-medium';
      default:
        return 'gpt-5-mini';
    }
  }

  // Get effective models with provider-specific defaults
  String getEffectiveTextModel() {
    final provider = effectiveAiProvider;
    final configuredModel = textSummarizationModel;
    
    // If no model configured or wrong provider model, use default for current provider
    if (configuredModel == null || !_isModelCompatibleWithProvider(configuredModel, provider)) {
      return getDefaultTextModel(provider);
    }
    return configuredModel;
  }

  String getEffectiveImageModel() {
    final provider = effectiveAiProvider;
    final configuredModel = imageAnalysisModel;
    
    // If no model configured or wrong provider model, use default for current provider
    if (configuredModel == null || !_isModelCompatibleWithProvider(configuredModel, provider)) {
      return getDefaultImageModel(provider);
    }
    return configuredModel;
  }

  // Check if a model is compatible with a provider
  bool _isModelCompatibleWithProvider(String model, String provider) {
    switch (provider.toLowerCase()) {
      case 'gemini':
        return model.startsWith('gemini');
      case 'openai':
        return model.startsWith('gpt') || model.startsWith('o1');
      case 'huggingface':
        return !model.startsWith('gemini') && !model.startsWith('gpt') && !model.startsWith('o1');
      default:
        return true;
    }
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
    String? ocrProvider,
    String? aiProvider,
    String? textSummarizationModel,
    String? imageAnalysisModel,
    String? openAIServiceTier,
    String? audioTranscriptionModel,
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
      ocrProvider: ocrProvider ?? this.ocrProvider,
      aiProvider: aiProvider ?? this.aiProvider,
      textSummarizationModel: textSummarizationModel ?? this.textSummarizationModel,
      imageAnalysisModel: imageAnalysisModel ?? this.imageAnalysisModel,
      openAIServiceTier: openAIServiceTier ?? this.openAIServiceTier,
      audioTranscriptionModel: audioTranscriptionModel ?? this.audioTranscriptionModel,
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
      'ocrProvider': ocrProvider,
      'aiProvider': aiProvider,
      'textSummarizationModel': textSummarizationModel,
      'imageAnalysisModel': imageAnalysisModel,
      'openAIServiceTier': openAIServiceTier,
      'audioTranscriptionModel': audioTranscriptionModel,
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
      ocrProvider: json['ocrProvider'] as String? ?? 'google_ml_kit',
      aiProvider: json['aiProvider'] as String? ?? 'openai',
      textSummarizationModel: json['textSummarizationModel'] as String? ?? 'gpt-5-mini',
      imageAnalysisModel: json['imageAnalysisModel'] as String? ?? 'gpt-5-mini',
      openAIServiceTier: json['openAIServiceTier'] as String? ?? 'flex',
      audioTranscriptionModel: json['audioTranscriptionModel'] as String? ?? 'gpt-4o-mini-transcribe',
    );
  }
}
