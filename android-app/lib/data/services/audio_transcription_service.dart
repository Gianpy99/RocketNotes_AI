// ==========================================
// lib/data/services/audio_transcription_service.dart
// ==========================================
import 'dart:io';
import 'dart:convert';
import 'dart:math' as math;
import 'package:dio/dio.dart';
import 'package:hive/hive.dart';
import '../../core/config/api_config.dart';
import '../../core/debug/debug_logger.dart';
import '../repositories/settings_repository.dart';
import '../models/usage_monitoring_model.dart';

/// Result of audio transcription
class AudioTranscriptionResult {
  final String transcription;
  final String detectedLanguage;
  final String? translation; // null se non necessaria
  final double confidence;
  final Duration processingTime;
  final String provider; // 'openai', 'gemini'
  final String model;
  final Map<String, dynamic> metadata;
  final double estimatedCost; // in USD

  AudioTranscriptionResult({
    required this.transcription,
    required this.detectedLanguage,
    this.translation,
    required this.confidence,
    required this.processingTime,
    required this.provider,
    required this.model,
    required this.metadata,
    required this.estimatedCost,
  });

  Map<String, dynamic> toJson() => {
    'transcription': transcription,
    'detectedLanguage': detectedLanguage,
    'translation': translation,
    'confidence': confidence,
    'processingTimeMs': processingTime.inMilliseconds,
    'provider': provider,
    'model': model,
    'metadata': metadata,
    'estimatedCost': estimatedCost,
  };
}

/// Service for AI-powered audio transcription with smart translation
class AudioTranscriptionService {
  static AudioTranscriptionService? _instance;
  static AudioTranscriptionService get instance => _instance ??= AudioTranscriptionService._();
  AudioTranscriptionService._();

  final Dio _dio = Dio();
  final SettingsRepository _settingsRepository = SettingsRepository();

  /// Main transcription method with smart translation
  Future<AudioTranscriptionResult> transcribeAudio({
    required String audioFilePath,
    String? targetLanguage, // lingua preferita utente, es. 'it', 'en'
    bool autoTranslate = true,
  }) async {
    final sw = Stopwatch()..start();
    
    try {
      final settings = await _settingsRepository.getSettings();
      final provider = settings.effectiveAiProvider;
      final model = settings.effectiveAudioTranscriptionModel;

      DebugLogger().log('🎤 Audio Transcription: Starting with $provider / $model');
      DebugLogger().log('🎤 File: $audioFilePath');

      AudioTranscriptionResult result;

      switch (provider.toLowerCase()) {
        case 'openai':
          result = await _transcribeWithOpenAI(audioFilePath, model, sw);
          break;
        case 'gemini':
          result = await _transcribeWithGemini(audioFilePath, model, sw);
          break;
        default:
          // Fallback: usa servizio locale (speech_to_text) se disponibile
          result = await _transcribeLocal(audioFilePath, sw);
      }

      // Smart translation: traduce solo se lingua rilevata != target
      if (autoTranslate && targetLanguage != null && targetLanguage.isNotEmpty) {
        final detected = result.detectedLanguage.toLowerCase();
        final target = targetLanguage.toLowerCase();
        
        if (!detected.startsWith(target) && !target.startsWith(detected)) {
          DebugLogger().log('🌍 Translation needed: $detected -> $target');
          final translation = await _translateText(
            text: result.transcription,
            detectedLanguage: detected,
            targetLanguage: target,
            provider: provider,
          );
          
          result = AudioTranscriptionResult(
            transcription: result.transcription,
            detectedLanguage: result.detectedLanguage,
            translation: translation,
            confidence: result.confidence,
            processingTime: result.processingTime,
            provider: result.provider,
            model: result.model,
            metadata: {...result.metadata, 'translated': true},
            estimatedCost: result.estimatedCost * 1.1, // +10% for translation
          );
        } else {
          DebugLogger().log('✅ No translation needed: language match');
        }
      }

      // Track usage
      await _trackUsage(result);

      DebugLogger().log('✅ Transcription completed in ${sw.elapsedMilliseconds}ms');
      return result;

    } catch (e) {
      sw.stop();
      DebugLogger().log('❌ Transcription failed: $e');
      rethrow;
    }
  }

  /// Transcribe with OpenAI Whisper
  Future<AudioTranscriptionResult> _transcribeWithOpenAI(
    String audioFilePath,
    String model,
    Stopwatch sw,
  ) async {
    if (!ApiConfig.hasOpenAIKey) {
      throw Exception('OpenAI API key not configured');
    }

    try {
      final file = File(audioFilePath);
      if (!await file.exists()) {
        throw Exception('Audio file not found: $audioFilePath');
      }

      final fileSize = await file.length();
      DebugLogger().log('📦 Audio file size: ${(fileSize / 1024).toStringAsFixed(2)} KB');

      // OpenAI Whisper API endpoint
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          audioFilePath,
          filename: audioFilePath.split('/').last,
        ),
        'model': _getWhisperModel(model),
        'response_format': 'verbose_json', // include language detection
        'temperature': 0.0, // più deterministico
      });

      final response = await _dio.post(
        'https://api.openai.com/v1/audio/transcriptions',
        data: formData,
        options: Options(
          headers: {
            'Authorization': 'Bearer ${ApiConfig.actualOpenAIKey}',
          },
          sendTimeout: const Duration(seconds: 60),
          receiveTimeout: const Duration(seconds: 120),
        ),
      );

      sw.stop();

      final data = response.data as Map<String, dynamic>;
      final transcription = data['text'] as String;
      final language = data['language'] as String? ?? 'unknown';
      
      // OpenAI Whisper pricing: ~$0.006 per minute
      final durationMinutes = (data['duration'] as num?)?.toDouble() ?? 1.0;
      final cost = durationMinutes * 0.006;

      DebugLogger().log('✅ OpenAI Whisper: ${transcription.length} chars, language: $language');

      return AudioTranscriptionResult(
        transcription: transcription,
        detectedLanguage: language,
        translation: null,
        confidence: 0.95, // Whisper is highly accurate
        processingTime: sw.elapsed,
        provider: 'openai',
        model: _getWhisperModel(model),
        metadata: {
          'duration_seconds': data['duration'],
          'segments': (data['segments'] as List?)?.length ?? 0,
        },
        estimatedCost: cost,
      );

    } catch (e) {
      DebugLogger().log('❌ OpenAI Whisper error: $e');
      rethrow;
    }
  }

  /// Transcribe with Google Gemini Native Audio
  Future<AudioTranscriptionResult> _transcribeWithGemini(
    String audioFilePath,
    String model,
    Stopwatch sw,
  ) async {
    if (!ApiConfig.hasGeminiKey) {
      throw Exception('Gemini API key not configured');
    }

    try {
      final file = File(audioFilePath);
      if (!await file.exists()) {
        throw Exception('Audio file not found: $audioFilePath');
      }

      // Leggi il file audio come base64
      final audioBytes = await file.readAsBytes();
      final audioBase64 = base64Encode(audioBytes);
      final fileSize = audioBytes.length;

      DebugLogger().log('📦 Audio file size: ${(fileSize / 1024).toStringAsFixed(2)} KB');

      // Gemini API con Native Audio
      final geminiModel = _getGeminiAudioModel(model);
      final response = await _dio.post(
        'https://generativelanguage.googleapis.com/v1beta/models/$geminiModel:generateContent?key=${ApiConfig.actualGeminiKey}',
        data: {
          'contents': [
            {
              'parts': [
                {
                  'text': 'Transcribe this audio. Return only the transcription text and detected language code (ISO 639-1) in this exact JSON format: {"transcription": "...", "language": "en"}',
                },
                {
                  'inline_data': {
                    'mime_type': 'audio/mpeg', // m4a/aac
                    'data': audioBase64,
                  }
                }
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.1,
            'maxOutputTokens': 2000,
          },
        },
        options: Options(
          headers: {'Content-Type': 'application/json'},
          sendTimeout: const Duration(seconds: 60),
          receiveTimeout: const Duration(seconds: 120),
        ),
      );

      sw.stop();

      final responseData = response.data as Map<String, dynamic>;
      final candidates = responseData['candidates'] as List;
      final content = candidates[0]['content'] as Map<String, dynamic>;
      final parts = content['parts'] as List;
      final textContent = parts[0]['text'] as String;

      DebugLogger().log('🔍 Raw Gemini response: ${textContent.substring(0, math.min(200, textContent.length))}');

      // Parse JSON response - handle markdown code blocks
      String jsonText = textContent.trim();
      
      // Remove markdown code block if present
      if (jsonText.startsWith('```json') || jsonText.startsWith('```')) {
        // Remove opening ```json or ```
        jsonText = jsonText.replaceFirst(RegExp(r'^```(?:json)?\s*'), '');
        // Remove closing ```
        jsonText = jsonText.replaceFirst(RegExp(r'\s*```\s*$'), '');
        jsonText = jsonText.trim();
      }
      
      DebugLogger().log('🔍 Cleaned JSON: ${jsonText.substring(0, math.min(100, jsonText.length))}');

      final parsed = jsonDecode(jsonText) as Map<String, dynamic>;
      final transcription = parsed['transcription'] as String;
      final language = parsed['language'] as String? ?? 'unknown';

      // Gemini Native Audio pricing: $3.00 per 1M audio input tokens
      // Stima: 1 secondo audio ≈ 100 tokens
      final estimatedTokens = (fileSize / 1024) * 10; // rough estimate
      final cost = (estimatedTokens / 1000000) * 3.0;

      DebugLogger().log('✅ Gemini Audio: ${transcription.length} chars, language: $language');

      return AudioTranscriptionResult(
        transcription: transcription,
        detectedLanguage: language,
        translation: null,
        confidence: 0.90,
        processingTime: sw.elapsed,
        provider: 'gemini',
        model: geminiModel,
        metadata: {
          'file_size_kb': (fileSize / 1024).round(),
          'estimated_tokens': estimatedTokens.round(),
        },
        estimatedCost: cost,
      );

    } catch (e) {
      DebugLogger().log('❌ Gemini Audio error: $e');
      rethrow;
    }
  }

  /// Fallback: local speech-to-text (no AI cost, lower accuracy)
  Future<AudioTranscriptionResult> _transcribeLocal(
    String audioFilePath,
    Stopwatch sw,
  ) async {
    sw.stop();
    
    // Questo è un placeholder: implementazione reale richiederebbe speech_to_text
    // con playback dell'audio mentre si registra
    DebugLogger().log('⚠️ Local transcription not fully implemented');
    
    return AudioTranscriptionResult(
      transcription: '[Local transcription placeholder - configure AI provider]',
      detectedLanguage: 'unknown',
      translation: null,
      confidence: 0.5,
      processingTime: sw.elapsed,
      provider: 'local',
      model: 'speech_to_text',
      metadata: {'note': 'fallback_mode'},
      estimatedCost: 0.0,
    );
  }

  /// Smart translation using configured AI provider
  Future<String> _translateText({
    required String text,
    required String detectedLanguage,
    required String targetLanguage,
    required String provider,
  }) async {
    try {
      final prompt = '''Translate the following text from $detectedLanguage to $targetLanguage. 
Return ONLY the translated text, no explanations or formatting:

$text''';

      if (provider == 'openai') {
        return await _translateWithOpenAI(prompt);
      } else if (provider == 'gemini') {
        return await _translateWithGemini(prompt);
      } else {
        // No translation available
        return text;
      }
    } catch (e) {
      DebugLogger().log('⚠️ Translation failed: $e');
      return text; // fallback to original
    }
  }

  Future<String> _translateWithOpenAI(String prompt) async {
    final response = await _dio.post(
      'https://api.openai.com/v1/chat/completions',
      data: {
        'model': 'gpt-5-mini', // fast and cheap for translation
        'messages': [
          {'role': 'system', 'content': 'You are a professional translator.'},
          {'role': 'user', 'content': prompt},
        ],
        'temperature': 0.3,
        'max_tokens': 1000,
      },
      options: Options(
        headers: {'Authorization': 'Bearer ${ApiConfig.actualOpenAIKey}'},
      ),
    );

    return response.data['choices'][0]['message']['content'] as String;
  }

  Future<String> _translateWithGemini(String prompt) async {
    final response = await _dio.post(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=${ApiConfig.actualGeminiKey}',
      data: {
        'contents': [
          {
            'parts': [{'text': prompt}]
          }
        ],
        'generationConfig': {'temperature': 0.3, 'maxOutputTokens': 1000},
      },
    );

    final candidates = response.data['candidates'] as List;
    final content = candidates[0]['content'] as Map<String, dynamic>;
    final parts = content['parts'] as List;
    return parts[0]['text'] as String;
  }

  /// Track usage for cost monitoring
  Future<void> _trackUsage(AudioTranscriptionResult result) async {
    try {
      final box = Hive.box<UsageMonitoringModel>('usage_monitoring');
      final now = DateTime.now();
      final today = now.toIso8601String().split('T')[0];
      final monthKey = '${result.provider}_${now.year}_${now.month}';
      final dayKey = '${result.provider}_$today';
      
      final existing = box.get('default') ?? UsageMonitoringModel.defaults();

      // Update daily usage
      final currentDailyUsage = Map<String, DailyUsage>.from(existing.dailyUsage);
      final existingDaily = currentDailyUsage[dayKey];
      
      currentDailyUsage[dayKey] = DailyUsage(
        provider: result.provider,
        date: today,
        requestCount: (existingDaily?.requestCount ?? 0) + 1,
        tokenUsage: (existingDaily?.tokenUsage ?? 0) + 1000, // estimate
        estimatedCost: (existingDaily?.estimatedCost ?? 0) + result.estimatedCost,
        groundingRequests: existingDaily?.groundingRequests ?? 0,
        modelUsage: existingDaily?.modelUsage ?? {},
      );

      // Update monthly spending
      final currentMonthlySpending = Map<String, MonthlySpending>.from(existing.monthlySpending);
      final existingMonthly = currentMonthlySpending[monthKey];
      
      final updatedModelCosts = Map<String, double>.from(existingMonthly?.modelCosts ?? {});
      updatedModelCosts[result.model] = (updatedModelCosts[result.model] ?? 0) + result.estimatedCost;
      
      currentMonthlySpending[monthKey] = MonthlySpending(
        provider: result.provider,
        year: now.year,
        month: now.month,
        totalCost: (existingMonthly?.totalCost ?? 0) + result.estimatedCost,
        modelCosts: updatedModelCosts,
        totalRequests: (existingMonthly?.totalRequests ?? 0) + 1,
      );

      final updated = existing.copyWith(
        dailyUsage: currentDailyUsage,
        monthlySpending: currentMonthlySpending,
      );

      await box.put('default', updated);

      DebugLogger().log('💰 Usage tracked: \$${result.estimatedCost.toStringAsFixed(4)} (${ result.provider})');
    } catch (e) {
      DebugLogger().log('⚠️ Failed to track usage: $e');
    }
  }

  String _getWhisperModel(String configuredModel) {
    // OpenAI Whisper models
    if (configuredModel.contains('whisper')) return configuredModel;
    // Default to standard Whisper
    return 'whisper-1';
  }

  String _getGeminiAudioModel(String configuredModel) {
    // Gemini models with audio support
    // Map any legacy audio model names to the correct multimodal models
    if (configuredModel.contains('native-audio')) {
      return 'gemini-2.5-flash'; // Fallback for legacy audio-specific model
    }
    
    // Valid Gemini models with audio support
    const validAudioModels = [
      'gemini-2.5-flash',
      'gemini-2.5-flash-lite',
      'gemini-2.5-flash-8b',
      'gemini-pro',
    ];
    
    if (validAudioModels.contains(configuredModel)) {
      return configuredModel;
    }
    
    // Default to flash (FREE tier + audio support)
    return 'gemini-2.5-flash';
  }

  /// Get file duration estimate (rough)
  Future<double> estimateAudioDuration(String filePath) async {
    try {
      final file = File(filePath);
      final bytes = await file.length();
      // Rough estimate: 128kbps AAC ≈ 16KB/sec
      return bytes / (16 * 1024);
    } catch (e) {
      return 0;
    }
  }
}
