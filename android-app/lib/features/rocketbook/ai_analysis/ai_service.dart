import 'dart:convert';
import 'dart:math' as math;
import 'package:dio/dio.dart';
import '../../../core/debug/debug_logger.dart';
import '../../../core/config/api_config.dart';
import '../../../data/repositories/settings_repository.dart';
import '../models/scanned_content.dart';

// Enum per provider AI e OCR
enum AIProvider {
  openAI,
  gemini,
  huggingFace,
  mockAI,
}

enum OCRProvider {
  trocrHandwritten, // microsoft/trocr-base-handwritten
  trocrPrinted,     // microsoft/trocr-base-printed
  tesseract,        // traditional OCR
  mockOCR,
}

// Configurazioni modelli avanzate
class AIModelConfig {
  // Modelli OpenAI per Flex tier (migliore rapporto qualità/prezzo)
  static const List<Map<String, dynamic>> openAIFlexModels = [
    {
      'id': 'gpt-5',
      'name': 'GPT-5 (Latest)',
      'description': 'Most advanced model',
      'inputPrice': 0.625,
      'outputPrice': 5.00,
      'cachedInputPrice': 0.0625,
      'supportsVision': true,
      'supportsAudio': false,
      'category': 'premium'
    },
    {
      'id': 'gpt-5-mini',
      'name': 'GPT-5 Mini',
      'description': 'Fast and efficient',
      'inputPrice': 0.125,
      'outputPrice': 1.00,
      'cachedInputPrice': 0.0125,
      'supportsVision': true,
      'supportsAudio': false,
      'category': 'balanced'
    },
    {
      'id': 'gpt-5-nano',
      'name': 'GPT-5 Nano',
      'description': 'Ultra cost-effective',
      'inputPrice': 0.025,
      'outputPrice': 0.20,
      'cachedInputPrice': 0.0025,
      'supportsVision': true,
      'supportsAudio': false,
      'category': 'economical'
    },
    {
      'id': 'o3',
      'name': 'O3',
      'description': 'Advanced reasoning',
      'inputPrice': 1.00,
      'outputPrice': 4.00,
      'cachedInputPrice': 0.25,
      'supportsVision': false,
      'supportsAudio': false,
      'category': 'reasoning'
    },
    {
      'id': 'o4-mini',
      'name': 'O4 Mini',
      'description': 'Efficient reasoning',
      'inputPrice': 0.55,
      'outputPrice': 2.20,
      'cachedInputPrice': 0.138,
      'supportsVision': false,
      'supportsAudio': false,
      'category': 'reasoning'
    },
  ];

  // Modelli OpenAI per Standard tier
  static const List<Map<String, dynamic>> openAIStandardModels = [
    {
      'id': 'gpt-5',
      'name': 'GPT-5 (Latest)',
      'description': 'Most advanced model',
      'inputPrice': 1.25,
      'outputPrice': 10.00,
      'supportsVision': true,
      'supportsAudio': false,
      'category': 'premium'
    },
    {
      'id': 'gpt-4o',
      'name': 'GPT-4o',
      'description': 'Vision and text',
      'inputPrice': 2.50,
      'outputPrice': 10.00,
      'supportsVision': true,
      'supportsAudio': false,
      'category': 'balanced'
    },
    {
      'id': 'gpt-4o-mini',
      'name': 'GPT-4o Mini',
      'description': 'Fast and efficient',
      'inputPrice': 0.15,
      'outputPrice': 0.60,
      'supportsVision': true,
      'supportsAudio': false,
      'category': 'economical'
    },
    {
      'id': 'o1',
      'name': 'O1',
      'description': 'Advanced reasoning',
      'inputPrice': 15.00,
      'outputPrice': 60.00,
      'supportsVision': false,
      'supportsAudio': false,
      'category': 'reasoning'
    },
  ];

  // Modelli per trascrizione audio OpenAI
  static const List<Map<String, dynamic>> openAIAudioModels = [
    {
      'id': 'gpt-4o-transcribe',
      'name': 'GPT-4o Transcribe',
      'description': 'High-quality transcription',
      'inputPrice': 2.50, // text tokens
      'outputPrice': 10.00,
      'audioInputPrice': 6.00, // audio tokens
      'estimatedCostPerMinute': 0.006,
      'category': 'premium'
    },
    {
      'id': 'gpt-4o-mini-transcribe',
      'name': 'GPT-4o Mini Transcribe',
      'description': 'Cost-effective transcription',
      'inputPrice': 1.25,
      'outputPrice': 5.00,
      'audioInputPrice': 3.00,
      'estimatedCostPerMinute': 0.003,
      'category': 'economical'
    },
    {
      'id': 'whisper',
      'name': 'Whisper',
      'description': 'Standard transcription',
      'costPerMinute': 0.006,
      'category': 'standard'
    },
  ];

  // Modelli Gemini
  static const List<Map<String, dynamic>> geminiModels = [
    {
      'id': 'gemini-2.5-flash',
      'name': 'Gemini 2.5 Flash',
      'description': 'Latest fast multimodal model - FREE up to limits',
      'inputPrice': 0.0, // Free tier
      'outputPrice': 0.0, // Free tier
      'paidInputPrice': 0.30, // Paid tier per 1M tokens
      'paidOutputPrice': 2.50, // Paid tier per 1M tokens
      'cachingPrice': 0.075,
      'supportsVision': true,
      'supportsAudio': true,
      'isFree': true,
      'freeRateLimit': {'rpm': 5, 'rpd': 25},
      'category': 'premium'
    },
    {
      'id': 'gemini-2.5-flash-lite',
      'name': 'Gemini 2.5 Flash Lite',
      'description': 'Lightweight multimodal model - FREE up to limits',
      'inputPrice': 0.0, // Free tier
      'outputPrice': 0.0, // Free tier
      'paidInputPrice': 0.10, // Paid tier per 1M tokens
      'paidOutputPrice': 0.40, // Paid tier per 1M tokens
      'cachingPrice': 0.025,
      'supportsVision': true,
      'supportsAudio': true,
      'isFree': true,
      'freeRateLimit': {'rpm': 5, 'rpd': 25},
      'category': 'economical'
    },
    {
      'id': 'gemini-2.5-flash-batch',
      'name': 'Gemini 2.5 Flash Batch',
      'description': 'Batch processing model',
      'inputPrice': 0.15, // Per 1M tokens
      'outputPrice': 1.25, // Per 1M tokens
      'cachingPrice': 0.075,
      'supportsVision': true,
      'supportsAudio': true,
      'isFree': false,
      'category': 'batch'
    },
    {
      'id': 'gemini-2.5-flash-lite-batch',
      'name': 'Gemini 2.5 Flash Lite Batch',
      'description': 'Batch processing lite model',
      'inputPrice': 0.05, // Per 1M tokens
      'outputPrice': 0.20, // Per 1M tokens
      'cachingPrice': 0.025,
      'supportsVision': true,
      'supportsAudio': true,
      'isFree': false,
      'category': 'batch'
    },
    {
      'id': 'gemini-2.5-flash-native-audio',
      'name': 'Gemini 2.5 Flash Native Audio',
      'description': 'Native audio processing',
      'textInputPrice': 0.50, // Text per 1M tokens
      'textOutputPrice': 2.00, // Text per 1M tokens
      'audioInputPrice': 3.00, // Audio per 1M tokens
      'audioOutputPrice': 12.00, // Audio per 1M tokens
      'supportsVision': false,
      'supportsAudio': true,
      'isFree': false,
      'category': 'premium'
    },
    {
      'id': 'gemini-pro',
      'name': 'Gemini Pro',
      'description': 'FREE with grounding limits',
      'inputPrice': 0.0, // Free
      'outputPrice': 0.0, // Free
      'supportsVision': true,
      'supportsAudio': false,
      'isFree': true,
      'groundingLimit': 1500, // per day
      'category': 'balanced'
    },
    {
      'id': 'gemini-pro-long-context',
      'name': 'Gemini Pro (Long Context)',
      'description': 'Extended context model',
      'inputPrice': 2.50, // Per 1M tokens
      'outputPrice': 15.00, // Per 1M tokens
      'cachingPrice': 0.625,
      'supportsVision': true,
      'supportsAudio': false,
      'isFree': false,
      'category': 'premium'
    },
  ];

  /// Get models by provider and tier
  static List<Map<String, dynamic>> getModelsForProvider(String provider, {String tier = 'flex'}) {
    switch (provider.toLowerCase()) {
      case 'openai':
        switch (tier.toLowerCase()) {
          case 'flex':
            return openAIFlexModels;
          case 'standard':
            return openAIStandardModels;
          default:
            return openAIFlexModels;
        }
      case 'gemini':
        return geminiModels;
      default:
        return [];
    }
  }

  /// Get audio models by provider
  static List<Map<String, dynamic>> getAudioModelsForProvider(String provider) {
    switch (provider.toLowerCase()) {
      case 'openai':
        return openAIAudioModels;
      case 'gemini':
        return geminiModels.where((model) => model['supportsAudio'] == true).toList();
      default:
        return [];
    }
  }

  /// Get optimal model for the task
  static String getOptimalModel(String provider, {bool requiresVision = false, bool prioritizeCost = true, String tier = 'flex'}) {
    final models = getModelsForProvider(provider, tier: tier);
    
    if (models.isEmpty) return 'gpt-5-mini'; // fallback
    
    if (requiresVision) {
      final visionModels = models.where((m) => m['supportsVision'] == true).toList();
      if (visionModels.isNotEmpty) {
        return prioritizeCost ? 
          visionModels.where((m) => m['category'] == 'economical').first['id'] :
          visionModels.where((m) => m['category'] == 'premium').first['id'];
      }
    }
    
    return prioritizeCost ? 
      models.where((m) => m['category'] == 'economical').first['id'] :
      models.where((m) => m['category'] == 'premium').first['id'];
  }
}

class AIService {
  static AIService? _instance;
  static AIService get instance => _instance ??= AIService._();
  AIService._();

  final Dio _dio = Dio();
  final SettingsRepository _settingsRepository = SettingsRepository();
  
  // Configuration
  static const String openAIBaseUrl = 'https://api.openai.com/v1';
  static const String geminiBaseUrl = 'https://generativelanguage.googleapis.com/v1beta';
  static const String huggingFaceBaseUrl = 'https://api-inference.huggingface.co/models';
  
  // API Keys (these should be stored securely in production)
  String? _openAIKey;
  String? _geminiKey;
  String? _huggingFaceKey;
  
  // Current provider
  AIProvider _currentProvider = AIProvider.mockAI;

  /// Initialize the AI service
  Future<void> initialize({
    String? openAIKey,
    String? geminiKey,
    String? huggingFaceKey,
    AIProvider? provider,
  }) async {
    // Use provided keys or configuration
    _openAIKey = openAIKey ?? ApiConfig.actualOpenAIKey;
    _geminiKey = geminiKey ?? ApiConfig.actualGeminiKey;
    _huggingFaceKey = huggingFaceKey ?? ApiConfig.actualHuggingFaceKey;
    
    DebugLogger().log('🤖 AI Service: Initializing...');
    DebugLogger().log('🔧 Checking API configuration...');
    
    // Get AI provider from settings
    final settings = await _settingsRepository.getSettings();
    final configuredProvider = settings.aiProvider;
    
    DebugLogger().log('⚙️ Configured AI provider from settings: $configuredProvider');
    
    // Check if we have real API keys
    final hasOpenAI = ApiConfig.hasOpenAIKey;
    final hasGemini = ApiConfig.hasGeminiKey;
    final hasHuggingFace = ApiConfig.hasHuggingFaceKey;
    
    DebugLogger().log('🔑 OpenAI Key available: $hasOpenAI');
    DebugLogger().log('🔑 Gemini Key available: $hasGemini');
    DebugLogger().log('🔑 HuggingFace Key available: $hasHuggingFace');
    
    // Set provider based on configuration and available keys
    if (provider != null) {
      _currentProvider = provider;
    } else {
      switch (configuredProvider) {
        case 'openai':
          _currentProvider = hasOpenAI ? AIProvider.openAI : AIProvider.mockAI;
          break;
        case 'gemini':
          _currentProvider = hasGemini ? AIProvider.gemini : AIProvider.mockAI;
          break;
        case 'huggingface':
          _currentProvider = hasHuggingFace ? AIProvider.huggingFace : AIProvider.mockAI;
          break;
        default:
          _currentProvider = AIProvider.mockAI;
      }
    }
    
    // Log which provider we're actually using
    if (_currentProvider != AIProvider.mockAI) {
      DebugLogger().log('✅ Using real AI provider: $_currentProvider');
    } else {
      DebugLogger().log('🎭 Using mock AI (no valid API keys or configured as mock)');
    }
    
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 60);
    
    DebugLogger().log('✅ AI Service initialized with provider: $_currentProvider');
  }

  /// Analyze scanned content with AI
  Future<AIAnalysis> analyzeContent(ScannedContent scannedContent) async {
    switch (_currentProvider) {
      case AIProvider.openAI:
        return await _analyzeWithOpenAI(scannedContent);
      case AIProvider.gemini:
        return await _analyzeWithGemini(scannedContent);
      case AIProvider.huggingFace:
        return await _analyzeWithHuggingFace(scannedContent);
      case AIProvider.mockAI:
        return _mockAnalysis(scannedContent);
    }
  }

  /// Analyze content with OpenAI GPT-4
  Future<AIAnalysis> _analyzeWithOpenAI(ScannedContent scannedContent) async {
    // Use ApiConfig to check if we have a valid key
    if (!ApiConfig.hasOpenAIKey) {
      DebugLogger().log('❌ AI Service: OpenAI API key not configured - falling back to simulation');
      return _fallbackAnalysis(scannedContent);
    }

    try {
      DebugLogger().log('🚀 AI Service: Starting real OpenAI analysis...');
      
      // Get the configured model from settings
      final settings = await _settingsRepository.getSettings();
      final bool hasImages = scannedContent.imagePath.isNotEmpty;
      
      // Use effective models that auto-select correct models for the provider
      final String configuredModel = hasImages 
          ? settings.getEffectiveImageModel()
          : settings.getEffectiveTextModel();
      
      DebugLogger().log('⚙️ Using configured model: $configuredModel');
      
      final prompt = _buildAnalysisPrompt(scannedContent);
      
      DebugLogger().log('📤 AI Service: Sending request to OpenAI API');
      final response = await _dio.post(
        '$openAIBaseUrl/chat/completions',
        options: Options(
          headers: {
            'Authorization': 'Bearer $_openAIKey',
            'Content-Type': 'application/json',
          },
        ),
        data: {
          'model': configuredModel,
          'service_tier': settings.openAIServiceTier, // Add service tier configuration
          'messages': [
            {
              'role': 'system',
              'content': _getSystemPrompt(),
            },
            {
              'role': 'user',
              'content': prompt,
            },
          ],
          'temperature': 0.3,
          'max_tokens': 2000,  // Increased for structured response
        },
      );

      DebugLogger().log('✅ AI Service: Received response from OpenAI');
      final content = response.data['choices'][0]['message']['content'];
      
      // Log the raw response for debugging
      DebugLogger().log('🔍 Raw OpenAI response: ${content.toString().substring(0, math.min(200, content.toString().length))}...');
      
      final analysis = _parseAIResponse(content);
      
      DebugLogger().log('🎯 AI Service: Analysis completed - ${analysis.keyTopics.length} topics, ${analysis.actionItems.length} actions');
      return analysis;
      
    } catch (e) {
      DebugLogger().log('❌ AI Service: OpenAI analysis error: $e');
      return _fallbackAnalysis(scannedContent);
    }
  }

  /// Analyze content with Google Gemini
  Future<AIAnalysis> _analyzeWithGemini(ScannedContent scannedContent) async {
    // Use ApiConfig to check if we have a valid key
    if (!ApiConfig.hasGeminiKey) {
      DebugLogger().log('❌ AI Service: Gemini API key not configured - falling back to simulation');
      DebugLogger().log('🔑 Current key: ${_geminiKey?.substring(0, 10)}...');
      return _fallbackAnalysis(scannedContent);
    }

    try {
      DebugLogger().log('🚀 AI Service: Starting real Gemini analysis...');
      
      // Get the configured model from settings
      final settings = await _settingsRepository.getSettings();
      final bool hasImages = scannedContent.imagePath.isNotEmpty;
      
      // Use effective models that auto-select correct models for the provider
      final String configuredModel = hasImages 
          ? settings.getEffectiveImageModel()
          : settings.getEffectiveTextModel();
      
      DebugLogger().log('⚙️ Using configured model: $configuredModel');
      
      final prompt = _buildAnalysisPrompt(scannedContent);
      
      DebugLogger().log('📤 AI Service: Sending request to Gemini API');
      final response = await _dio.post(
        '$geminiBaseUrl/models/$configuredModel:generateContent?key=$_geminiKey',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
        data: {
          'contents': [
            {
              'parts': [
                {
                  'text': '${_getSystemPrompt()}\n\n$prompt',
                }
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.7,
            'maxOutputTokens': 1500,
          },
        },
      );

      DebugLogger().log('✅ AI Service: Received response from Gemini');
      DebugLogger().log('🔍 Raw response type: ${response.data.runtimeType}');
      DebugLogger().log('🔍 Raw response preview: ${response.data.toString().substring(0, math.min(500, response.data.toString().length))}...');
      
      // Safely extract content with comprehensive null checks
      final responseData = response.data;
      DebugLogger().log('🔍 Response data null check: ${responseData == null}');
      
      if (responseData == null) {
        DebugLogger().log('❌ Response data is completely null');
        throw Exception('Gemini API returned null response');
      }
      
      DebugLogger().log('🔍 Response data keys: ${responseData is Map ? (responseData).keys.toList() : 'Not a Map'}');
      
      if (responseData is! Map<String, dynamic>) {
        DebugLogger().log('❌ Response data is not a Map: ${responseData.runtimeType}');
        throw Exception('Invalid response format from Gemini API');
      }
      
      final responseMap = responseData;
      
      if (!responseMap.containsKey('candidates') || responseMap['candidates'] == null) {
        DebugLogger().log('❌ No candidates key or null candidates: ${responseMap.keys.toList()}');
        throw Exception('Empty or invalid response structure from Gemini API');
      }
      
      final candidates = responseMap['candidates'];
      DebugLogger().log('🔍 Candidates type: ${candidates.runtimeType}, length: ${candidates is List ? candidates.length : 'Not a List'}');
      
      if (candidates is! List || candidates.isEmpty) {
        DebugLogger().log('❌ Candidates is not a List or is empty');
        throw Exception('Invalid candidates in Gemini response');
      }
      
      final candidatesList = candidates;
      final candidate = candidatesList[0];
      DebugLogger().log('🔍 First candidate type: ${candidate.runtimeType}');
      DebugLogger().log('🔍 First candidate keys: ${candidate is Map ? (candidate).keys.toList() : 'Not a Map'}');
      
      if (candidate is! Map<String, dynamic>) {
        DebugLogger().log('❌ Candidate is not a Map: ${candidate.runtimeType}');
        throw Exception('Invalid candidate structure from Gemini API');
      }
      
      final candidateMap = candidate;
      
      if (!candidateMap.containsKey('content') || candidateMap['content'] == null) {
        DebugLogger().log('❌ No content in candidate: ${candidateMap.keys.toList()}');
        throw Exception('No content in Gemini candidate');
      }
      
      final content = candidateMap['content'];
      DebugLogger().log('🔍 Content type: ${content.runtimeType}');
      DebugLogger().log('🔍 Content keys: ${content is Map ? (content).keys.toList() : 'Not a Map'}');
      
      if (content is! Map<String, dynamic>) {
        DebugLogger().log('❌ Content is not a Map: ${content.runtimeType}');
        throw Exception('Invalid content structure from Gemini API');
      }
      
      final contentMap = content;
      
      if (!contentMap.containsKey('parts') || contentMap['parts'] == null) {
        DebugLogger().log('❌ No parts in content: ${contentMap.keys.toList()}');
        throw Exception('No parts in Gemini content');
      }
      
      final parts = contentMap['parts'];
      DebugLogger().log('🔍 Parts type: ${parts.runtimeType}, length: ${parts is List ? parts.length : 'Not a List'}');
      
      if (parts is! List || parts.isEmpty) {
        DebugLogger().log('❌ Parts is not a List or is empty');
        throw Exception('Invalid parts in Gemini content');
      }
      
      final partsList = parts;
      final firstPart = partsList[0];
      DebugLogger().log('🔍 First part type: ${firstPart.runtimeType}');
      DebugLogger().log('🔍 First part keys: ${firstPart is Map ? (firstPart).keys.toList() : 'Not a Map'}');
      
      if (firstPart is! Map<String, dynamic>) {
        DebugLogger().log('❌ First part is not a Map: ${firstPart.runtimeType}');
        throw Exception('Invalid part structure from Gemini API');
      }
      
      final partMap = firstPart;
      
      if (!partMap.containsKey('text') || partMap['text'] == null) {
        DebugLogger().log('❌ No text in part: ${partMap.keys.toList()}');
        throw Exception('No text content in Gemini part');
      }
      
      final textContent = partMap['text'];
      DebugLogger().log('🔍 Text content type: ${textContent.runtimeType}, length: ${textContent is String ? textContent.length : 'Not a String'}');
      
      if (textContent is! String) {
        DebugLogger().log('❌ Text content is not a String: ${textContent.runtimeType}');
        throw Exception('Invalid text content from Gemini API');
      }
      
      final analysis = _parseAIResponse(textContent);
      
      DebugLogger().log('🎯 AI Service: Analysis completed - ${analysis.keyTopics.length} topics, ${analysis.actionItems.length} actions');
      return analysis;
      
    } catch (e) {
      DebugLogger().log('❌ AI Service: Gemini analysis error: $e');
      return _fallbackAnalysis(scannedContent);
    }
  }

  /// Analyze content with HuggingFace models
  Future<AIAnalysis> _analyzeWithHuggingFace(ScannedContent scannedContent) async {
    // Use ApiConfig to check if we have a valid key
    if (!ApiConfig.hasHuggingFaceKey) {
      DebugLogger().log('❌ AI Service: HuggingFace API key not configured - falling back to simulation');
      return _fallbackAnalysis(scannedContent);
    }

    try {
      DebugLogger().log('🚀 AI Service: Starting real HuggingFace analysis...');
      
      // Get the configured model from settings
      final settings = await _settingsRepository.getSettings();
      final bool hasImages = scannedContent.imagePath.isNotEmpty;
      
      // Use effective models that auto-select correct models for the provider
      final String configuredModel = hasImages 
          ? settings.getEffectiveImageModel()
          : settings.getEffectiveTextModel();
      
      DebugLogger().log('⚙️ Using configured model: $configuredModel');
      
      final prompt = _buildAnalysisPrompt(scannedContent);
      
      DebugLogger().log('📤 AI Service: Sending request to HuggingFace API with model: $configuredModel');
      final response = await _dio.post(
        '$huggingFaceBaseUrl/$configuredModel',
        options: Options(
          headers: {
            'Authorization': 'Bearer $_huggingFaceKey',
            'Content-Type': 'application/json',
          },
        ),
        data: {
          'inputs': '${_getSystemPrompt()}\n\n$prompt',
          'parameters': {
            'max_length': 1500,
            'temperature': 0.7,
            'return_full_text': false,
          },
        },
      );

      DebugLogger().log('✅ AI Service: Received response from HuggingFace');
      
      // HuggingFace inference API returns different format
      String content;
      if (response.data is List && response.data.isNotEmpty) {
        content = response.data[0]['generated_text'] ?? '';
      } else if (response.data is Map) {
        content = response.data['generated_text'] ?? '';
      } else {
        content = response.data.toString();
      }
      
      final analysis = _parseAIResponse(content);
      
      DebugLogger().log('🎯 AI Service: Analysis completed - ${analysis.keyTopics.length} topics, ${analysis.actionItems.length} actions');
      return analysis;
      
    } catch (e) {
      DebugLogger().log('❌ AI Service: HuggingFace analysis error: $e');
      return _fallbackAnalysis(scannedContent);
    }
  }

  /// Mock AI analysis for development/testing
  AIAnalysis _mockAnalysis(ScannedContent scannedContent) {
    final text = scannedContent.rawText;
    
    DebugLogger().log('🤖 AI Service: Starting enhanced simulation analysis...');
    DebugLogger().log('🤖 Input text length: ${text.length} characters');
    
    // Check if this is a direct AI analysis (no OCR)
    final isDirectAnalysis = text.contains('[Image sent directly to AI for analysis]');
    
    if (isDirectAnalysis) {
      DebugLogger().log('🤖 AI Service: Processing direct image analysis simulation');
      
      // Enhanced analysis for direct image processing with realistic variations
      final imageAnalysisVariations = [
        {
          'scenario': 'Technical Diagram',
          'summary': 'This image contains a technical diagram with architectural components. The AI has identified system flow patterns, data relationships, and technical annotations. This visual analysis provides better context understanding than pure OCR would.',
          'topics': ['System Architecture', 'Technical Design', 'Data Flow', 'Visual Analysis'],
          'tags': ['architecture', 'technical-diagram', 'system-design', 'ai-analyzed'],
          'title': 'Technical Architecture Diagram Analysis',
          'insights': {
            'visual_complexity': 'high',
            'diagram_type': 'system_architecture',
            'technical_depth': 'advanced',
          }
        },
        {
          'scenario': 'Meeting Whiteboard',
          'summary': 'This image shows a whiteboard from a meeting with hand-drawn diagrams, bullet points, and action items. The AI has analyzed the visual layout to understand the meeting flow and decision points better than text-only analysis.',
          'topics': ['Meeting Notes', 'Action Items', 'Visual Brainstorming', 'Team Discussion'],
          'tags': ['meeting', 'whiteboard', 'brainstorming', 'visual-notes'],
          'title': 'Meeting Whiteboard Visual Analysis',
          'insights': {
            'meeting_type': 'brainstorming',
            'participant_count': 'estimated_3-5',
            'visual_elements': 'diagrams_and_text',
          }
        },
        {
          'scenario': 'Document Page',
          'summary': 'This image contains a formatted document page with structured content. The AI has analyzed the layout, hierarchy, and visual formatting to better understand the document structure and importance of different sections.',
          'topics': ['Document Analysis', 'Structured Content', 'Information Hierarchy'],
          'tags': ['document', 'structured-content', 'formal-text', 'layout-aware'],
          'title': 'Structured Document Analysis',
          'insights': {
            'document_type': 'formal_report',
            'layout_complexity': 'medium',
            'formatting_preserved': true,
          }
        }
      ];
      
      // Randomly select a realistic scenario
      final selectedAnalysis = imageAnalysisVariations[DateTime.now().millisecond % imageAnalysisVariations.length];
      
      DebugLogger().log('🤖 AI Service: Selected scenario: ${selectedAnalysis['scenario']}');
      
      return AIAnalysis(
        summary: selectedAnalysis['summary'] as String,
        keyTopics: (selectedAnalysis['topics'] as List<String>),
        suggestedTags: (selectedAnalysis['tags'] as List<String>),
        suggestedTitle: selectedAnalysis['title'] as String,
        contentType: ContentType.mixed,
        sentiment: 0.1, // slightly positive
        actionItems: [
          ActionItem(
            text: 'Review visual analysis results for accuracy',
            priority: Priority.medium,
          ),
          ActionItem(
            text: 'Extract specific details from identified elements',
            priority: Priority.medium,
          ),
          ActionItem(
            text: 'Consider follow-up based on content insights',
            priority: Priority.low,
          ),
        ],
        insights: {
          'processing_mode': 'direct_ai_analysis',
          'ocr_skipped': true,
          'faster_processing': true,
          'better_context_understanding': true,
          'visual_elements_analyzed': true,
          'simulation_scenario': selectedAnalysis['scenario'],
          ...(selectedAnalysis['insights'] as Map<String, dynamic>),
        },
      );
    } else {
      DebugLogger().log('🤖 AI Service: Processing OCR-based content analysis simulation');
      
      // Standard analysis for OCR-processed content with enhanced realism
      final keyTopics = _extractKeyTopics(text);
      final suggestedTags = _generateTags(text);
      final contentType = _detectContentType(text);
      final actionItems = _extractActionItems(text);
      final sentiment = _analyzeSentiment(text);
      
      DebugLogger().log('🤖 AI Service: Extracted ${keyTopics.length} key topics');
      DebugLogger().log('🤖 AI Service: Generated ${suggestedTags.length} tags');
      DebugLogger().log('🤖 AI Service: Detected content type: $contentType');
      DebugLogger().log('🤖 AI Service: Found ${actionItems.length} action items');
      DebugLogger().log('🤖 AI Service: Sentiment score: ${sentiment.toStringAsFixed(2)}');
      
      return AIAnalysis(
        summary: _generateSummary(text),
        keyTopics: keyTopics,
        suggestedTags: suggestedTags,
        suggestedTitle: _generateTitle(text),
        contentType: contentType,
        sentiment: sentiment,
        actionItems: actionItems,
        insights: {
          'word_count': text.split(' ').length,
          'estimated_reading_time': '${(text.split(' ').length / 200).ceil()} min',
          'complexity_score': _calculateComplexity(text),
          'has_tables': scannedContent.tables.isNotEmpty,
          'has_diagrams': scannedContent.diagrams.isNotEmpty,
          'processing_mode': 'ocr_then_ai',
          'ocr_confidence': scannedContent.ocrMetadata.overallConfidence,
          'simulation_quality': 'enhanced',
        },
      );
    }
  }

  /// Build analysis prompt for AI - RocketBook focused
  String _buildAnalysisPrompt(ScannedContent scannedContent) {
    final buffer = StringBuffer();
    
    buffer.writeln('ROCKETBOOK PAGE ANALYSIS REQUEST:');
    buffer.writeln('');
    
    // Check if it looks like a RocketBook page
    bool hasRocketBookIndicators = _detectRocketBookPage(scannedContent.rawText);
    if (hasRocketBookIndicators) {
      buffer.writeln('📓 DETECTED: RocketBook page with symbols/structure');
    } else {
      buffer.writeln('📝 DETECTED: General handwritten/printed notes');
    }
    buffer.writeln('');
    
    buffer.writeln('=== SCANNED TEXT CONTENT ===');
    if (scannedContent.rawText.isNotEmpty) {
      buffer.writeln(scannedContent.rawText);
    } else {
      buffer.writeln('[No text detected - analyze visual elements if present]');
    }
    
    // Add tables if present
    if (scannedContent.tables.isNotEmpty) {
      buffer.writeln('');
      buffer.writeln('=== STRUCTURED DATA ===');
      for (int i = 0; i < scannedContent.tables.length; i++) {
        final table = scannedContent.tables[i];
        buffer.writeln('Table ${i + 1}:');
        for (final row in table.rows) {
          buffer.writeln('  ${row.join(' | ')}');
        }
      }
    }
    
    // Add technical context
    buffer.writeln('');
    buffer.writeln('=== SCAN QUALITY ===');
    buffer.writeln('OCR Confidence: ${(scannedContent.ocrMetadata.overallConfidence * 100).toStringAsFixed(1)}%');
    buffer.writeln('');
    
    buffer.writeln('Please analyze this content and provide a structured response following the exact format specified in the system prompt.');
    
    return buffer.toString();
  }

  /// Detect if this looks like a RocketBook page
  bool _detectRocketBookPage(String text) {
    final rocketBookIndicators = [
      '□', '○', '△', '◇', '♠', '♦', '♣', '♥', // Common RocketBook symbols
      'rocketbook', 'rocket book',
      'reusable', 'erasable',
      'scan to', 'send to',
    ];
    
    final lowerText = text.toLowerCase();
    return rocketBookIndicators.any((indicator) => lowerText.contains(indicator));
  }

  /// System prompt for AI analysis - Unified structured response
  String _getSystemPrompt() {
    return '''
You are an AI assistant specialized in analyzing RocketBook scanned pages and handwritten/printed notes. 

Your task is to provide a STRUCTURED analysis that follows this EXACT format for consistent parsing:

RESPONSE FORMAT (ALWAYS use this structure):
```
TITLE: [Create a descriptive title based on content]

SHORT_DESCRIPTION: [2-3 sentence summary of the main content and purpose]

ROCKETBOOK_PAGE_TYPE: [meeting|notes|todo|brainstorm|technical|planning|personal|mixed|research]

SUMMARY: [Comprehensive summary of all content, including key points, ideas, and observations]

TASKS: [List each actionable item found, one per line with format "- Task description"]

DEADLINES: [List any dates, deadlines, or time-sensitive items found, format "- Date/deadline: description"]

PEOPLE_MENTIONED: [List names of people referenced in the content]

KEY_TOPICS: [Main subjects and themes covered, separated by commas]

PRIORITY_LEVEL: [low|medium|high|urgent]

NEXT_ACTIONS: [Suggested follow-up steps based on content analysis]
```

ANALYSIS GUIDELINES:
- Be thorough and accurate in text extraction
- Identify RocketBook page symbols and their meanings if present
- Extract ALL actionable items and deadlines
- Suggest practical next steps
- Maintain consistency in response structure
- Focus on practical utility for note organization

IMPORTANT: Always follow the exact format above. Do not deviate from this structure as it enables automatic parsing.
''';
  }

  /// Parse AI response - supports both structured format and JSON fallback
  AIAnalysis _parseAIResponse(String response) {
    try {
      DebugLogger().log('🔍 Parsing AI response of length: ${response.length}');
      
      // First try structured format parsing
      if (response.contains('TITLE:') && response.contains('SUMMARY:')) {
        DebugLogger().log('📋 Detected structured format response');
        return _parseStructuredResponse(response);
      }
      
      // Fallback to JSON parsing
      final jsonMatch = RegExp(r'\{.*\}', dotAll: true).firstMatch(response);
      if (jsonMatch != null) {
        DebugLogger().log('📄 Detected JSON format response');
        return _parseJsonResponse(jsonMatch.group(0)!);
      }
      
      // Last resort: text parsing
      DebugLogger().log('⚠️ No structured format found, attempting text parsing...');
      return _parseTextResponse(response);
      
    } catch (e) {
      DebugLogger().log('❌ Error parsing AI response: $e');
      return _parseTextResponse(response);
    }
  }

  /// Parse the new structured format
  AIAnalysis _parseStructuredResponse(String response) {
    final Map<String, String> sections = {};
    
    // Extract sections using regex
    final sectionPattern = RegExp(r'(\w+(?:_\w+)*):\s*(.+?)(?=\n\w+(?:_\w+)*:|$)', dotAll: true);
    final matches = sectionPattern.allMatches(response);
    
    for (final match in matches) {
      final key = match.group(1)?.toLowerCase() ?? '';
      final value = match.group(2)?.trim() ?? '';
      sections[key] = value;
    }
    
    // Parse tasks
    final tasks = <ActionItem>[];
    final tasksText = sections['tasks'] ?? '';
    if (tasksText.isNotEmpty) {
      final taskLines = tasksText.split('\n')
          .where((line) => line.trim().startsWith('-'))
          .map((line) => line.trim().substring(1).trim());
      
      for (final task in taskLines) {
        if (task.isNotEmpty) {
          tasks.add(ActionItem(
            text: task,
            priority: _inferPriority(task, sections['priority_level'] ?? 'medium'),
            dueDate: null,
          ));
        }
      }
    }
    
    // Parse deadlines
    final deadlines = <String>[];
    final deadlinesText = sections['deadlines'] ?? '';
    if (deadlinesText.isNotEmpty) {
      deadlines.addAll(deadlinesText.split('\n')
          .where((line) => line.trim().startsWith('-'))
          .map((line) => line.trim().substring(1).trim()));
    }
    
    // Parse key topics
    final keyTopics = (sections['key_topics'] ?? '')
        .split(',')
        .map((topic) => topic.trim())
        .where((topic) => topic.isNotEmpty)
        .take(10)
        .toList();
    
    // Parse people mentioned
    final peopleMentioned = (sections['people_mentioned'] ?? '')
        .split(',')
        .map((person) => person.trim())
        .where((person) => person.isNotEmpty)
        .toList();
    
    DebugLogger().log('✅ Successfully parsed structured response: ${tasks.length} tasks, ${keyTopics.length} topics');
    
    return AIAnalysis(
      summary: sections['summary'] ?? 'RocketBook page analysis',
      keyTopics: keyTopics,
      suggestedTags: _generateTagsFromStructured(sections),
      suggestedTitle: sections['title'] ?? 'RocketBook Note',
      contentType: _parseContentTypeFromString(sections['rocketbook_page_type'] ?? 'notes'),
      sentiment: _inferSentimentFromPriority(sections['priority_level'] ?? 'medium'),
      actionItems: tasks,
      insights: {
        'page_type': sections['rocketbook_page_type'] ?? 'unknown',
        'priority_level': sections['priority_level'] ?? 'medium',
        'next_actions': sections['next_actions'] ?? '',
        'deadlines': deadlines,
        'people_mentioned': peopleMentioned,
        'short_description': sections['short_description'] ?? '',
      },
    );
  }

  /// Parse non-JSON text response as fallback
  AIAnalysis _parseTextResponse(String response) {
    try {
      // Extract basic information from text response
      final lines = response.split('\n').where((line) => line.trim().isNotEmpty).toList();
      
      // Try to extract a title (first meaningful line)
      String title = 'AI Analysis';
      if (lines.isNotEmpty) {
        title = lines.first.trim().replaceAll(RegExp(r'^[#*\-\s]*'), '');
        if (title.length > 50) title = '${title.substring(0, 50)}...';
      }
      
      // Create a summary from the response
      String summary = response.length > 200 
          ? '${response.substring(0, 200)}...'
          : response;
      
      // Extract any obvious action items (lines starting with action words)
      final actionWords = ['do', 'complete', 'finish', 'send', 'call', 'email', 'review', 'update'];
      final actionItems = <ActionItem>[];
      
      for (final line in lines) {
        final lowerLine = line.toLowerCase();
        if (actionWords.any((word) => lowerLine.contains(word))) {
          actionItems.add(ActionItem(
            text: line.trim(),
            priority: Priority.medium,
            dueDate: null,
          ));
        }
      }
      
      DebugLogger().log('✅ Successfully parsed text response');
      return AIAnalysis(
        summary: summary,
        keyTopics: _extractKeyTopicsFromText(response),
        suggestedTags: ['ai-analysis', 'text-parsed'],
        suggestedTitle: title,
        contentType: ContentType.notes,
        sentiment: 0.0,
        actionItems: actionItems,
        insights: {
          'parse_method': 'text_fallback',
          'response_length': response.length,
          'lines_count': lines.length,
        },
      );
      
    } catch (e) {
      DebugLogger().log('❌ Error in text parsing: $e');
      // Final fallback - basic analysis
      return AIAnalysis(
        summary: 'Analysis completed - content processed',
        keyTopics: [],
        suggestedTags: ['ai-analysis'],
        suggestedTitle: 'AI Analysis',
        contentType: ContentType.notes,
        sentiment: 0.0,
        actionItems: [],
        insights: {'parse_error': e.toString()},
      );
    }
  }

  /// Extract key topics from text
  List<String> _extractKeyTopicsFromText(String text) {
    final words = text.toLowerCase().split(RegExp(r'\W+'));
    final commonWords = {'the', 'and', 'is', 'in', 'to', 'of', 'a', 'for', 'on', 'with', 'as', 'by', 'at', 'or', 'an', 'are', 'was', 'but', 'not', 'from', 'had', 'has', 'have', 'he', 'she', 'it', 'they', 'we', 'you', 'i', 'me', 'my', 'your', 'his', 'her', 'its', 'our', 'their'};
    
    final wordFreq = <String, int>{};
    for (final word in words) {
      if (word.length > 3 && !commonWords.contains(word)) {
        wordFreq[word] = (wordFreq[word] ?? 0) + 1;
      }
    }
    
    return wordFreq.entries
        .where((entry) => entry.value > 1)
        .map((entry) => entry.key)
        .take(5)
        .toList();
  }

  /// Fallback analysis when AI service fails
  AIAnalysis _fallbackAnalysis(ScannedContent scannedContent) {
    return _mockAnalysis(scannedContent);
  }

  // Mock analysis helper methods
  
  List<String> _extractKeyTopics(String text) {
    final words = text.toLowerCase().split(RegExp(r'\W+'));
    final commonWords = {'the', 'and', 'is', 'in', 'to', 'of', 'a', 'for', 'on', 'with', 'as', 'by', 'at', 'or', 'an', 'are', 'was', 'but', 'not', 'from', 'had', 'has', 'have', 'he', 'she', 'it', 'they', 'we', 'you', 'i', 'me', 'my', 'your', 'his', 'her', 'its', 'our', 'their'};
    
    final wordFreq = <String, int>{};
    for (final word in words) {
      if (word.length > 3 && !commonWords.contains(word)) {
        wordFreq[word] = (wordFreq[word] ?? 0) + 1;
      }
    }
    
    final sortedWords = wordFreq.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sortedWords.take(3).map((e) => e.key).toList();
  }

  List<String> _generateTags(String text) {
    final lowerText = text.toLowerCase();
    final tags = <String>[];
    
    if (lowerText.contains(RegExp(r'\b(meeting|discussion|call)\b'))) tags.add('meeting');
    if (lowerText.contains(RegExp(r'\b(todo|task|action|complete)\b'))) tags.add('todo');
    if (lowerText.contains(RegExp(r'\b(idea|brainstorm|concept)\b'))) tags.add('ideas');
    if (lowerText.contains(RegExp(r'\b(project|plan|strategy)\b'))) tags.add('project');
    if (lowerText.contains(RegExp(r'\b(important|urgent|priority)\b'))) tags.add('important');
    
    return tags.take(3).toList();
  }

  ContentType _detectContentType(String text) {
    final lowerText = text.toLowerCase();
    
    if (lowerText.contains(RegExp(r'\b(meeting|discussion|call|agenda)\b'))) {
      return ContentType.meeting;
    }
    if (lowerText.contains(RegExp(r'\b(todo|task|action|complete|deadline)\b'))) {
      return ContentType.todo;
    }
    if (lowerText.contains(RegExp(r'\b(idea|brainstorm|concept|think)\b'))) {
      return ContentType.brainstorm;
    }
    if (lowerText.contains(RegExp(r'\b(code|technical|api|system|server)\b'))) {
      return ContentType.technical;
    }
    if (lowerText.contains(RegExp(r'\b(personal|family|home|private)\b'))) {
      return ContentType.personal;
    }
    
    return ContentType.notes;
  }

  List<ActionItem> _extractActionItems(String text) {
    final actionItems = <ActionItem>[];
    final lines = text.split('\n');
    
    for (final line in lines) {
      final trimmedLine = line.trim();
      if (trimmedLine.startsWith('- ') || 
          trimmedLine.startsWith('* ') ||
          trimmedLine.startsWith('• ') ||
          trimmedLine.toLowerCase().contains('todo') ||
          trimmedLine.toLowerCase().contains('action')) {
        
        Priority priority = Priority.medium;
        if (trimmedLine.toLowerCase().contains('urgent') || trimmedLine.contains('!!!')) {
          priority = Priority.urgent;
        } else if (trimmedLine.toLowerCase().contains('important') || trimmedLine.contains('!!')) {
          priority = Priority.high;
        } else if (trimmedLine.toLowerCase().contains('later') || trimmedLine.contains('maybe')) {
          priority = Priority.low;
        }
        
        actionItems.add(ActionItem(
          text: trimmedLine,
          priority: priority,
        ));
      }
    }
    
    return actionItems.take(5).toList();
  }

  String _generateSummary(String text) {
    if (text.length <= 200) return text;
    
    final sentences = text.split(RegExp(r'[.!?]+'));
    final firstSentence = sentences.isNotEmpty ? sentences.first.trim() : '';
    
    if (firstSentence.length <= 200) {
      return firstSentence;
    }
    
    return '${text.substring(0, 197)}...';
  }

  String _generateTitle(String text) {
    final lines = text.split('\n');
    final firstLine = lines.isNotEmpty ? lines.first.trim() : '';
    
    if (firstLine.length <= 50 && firstLine.isNotEmpty) {
      return firstLine;
    }
    
    final words = text.split(' ').take(8).join(' ');
    return words.length > 50 ? '${words.substring(0, 47)}...' : words;
  }

  double _analyzeSentiment(String text) {
    final positiveWords = ['good', 'great', 'excellent', 'amazing', 'wonderful', 'fantastic', 'positive', 'success', 'achievement'];
    final negativeWords = ['bad', 'terrible', 'awful', 'horrible', 'negative', 'problem', 'issue', 'failure', 'error'];
    
    final lowerText = text.toLowerCase();
    int positiveCount = 0;
    int negativeCount = 0;
    
    for (final word in positiveWords) {
      positiveCount += RegExp(r'\b' + word + r'\b').allMatches(lowerText).length;
    }
    
    for (final word in negativeWords) {
      negativeCount += RegExp(r'\b' + word + r'\b').allMatches(lowerText).length;
    }
    
    final totalWords = text.split(' ').length;
    if (totalWords == 0) return 0.0;
    
    final sentimentScore = (positiveCount - negativeCount) / totalWords;
    return sentimentScore.clamp(-1.0, 1.0);
  }

  double _calculateComplexity(String text) {
    final sentences = text.split(RegExp(r'[.!?]+')).where((s) => s.trim().isNotEmpty).length;
    final words = text.split(' ').length;
    
    if (sentences == 0) return 0.0;
    
    final avgWordsPerSentence = words / sentences;
    return (avgWordsPerSentence / 20).clamp(0.0, 1.0);
  }

  Priority _parsePriority(String? priority) {
    switch (priority?.toLowerCase()) {
      case 'low': return Priority.low;
      case 'medium': return Priority.medium;
      case 'high': return Priority.high;
      case 'urgent': return Priority.urgent;
      default: return Priority.medium;
    }
  }

  ContentType _parseContentType(String? type) {
    switch (type?.toLowerCase()) {
      case 'notes': return ContentType.notes;
      case 'meeting': return ContentType.meeting;
      case 'todo': return ContentType.todo;
      case 'brainstorm': return ContentType.brainstorm;
      case 'technical': return ContentType.technical;
      case 'personal': return ContentType.personal;
      case 'mixed': return ContentType.mixed;
      default: return ContentType.notes;
    }
  }

  // =============================================
  // STRUCTURED RESPONSE PARSING HELPERS
  // =============================================

  /// Parse JSON response (fallback)
  AIAnalysis _parseJsonResponse(String jsonString) {
    final jsonData = json.decode(jsonString);
    
    final actionItems = (jsonData['actionItems'] as List?)
        ?.map((item) => ActionItem(
              text: item['text'] ?? '',
              priority: _parsePriority(item['priority']),
              dueDate: item['dueDate'] != null ? DateTime.tryParse(item['dueDate']) : null,
            ))
        .toList() ?? [];
    
    return AIAnalysis(
      summary: jsonData['summary'] ?? '',
      keyTopics: List<String>.from(jsonData['keyTopics'] ?? []),
      suggestedTags: List<String>.from(jsonData['suggestedTags'] ?? []),
      suggestedTitle: jsonData['suggestedTitle'] ?? 'Untitled Note',
      contentType: _parseContentType(jsonData['contentType']),
      sentiment: (jsonData['sentiment'] as num?)?.toDouble() ?? 0.0,
      actionItems: actionItems,
      insights: Map<String, dynamic>.from(jsonData['insights'] ?? {}),
    );
  }

  /// Infer priority from task text and overall priority level
  Priority _inferPriority(String taskText, String overallPriority) {
    final lowerTask = taskText.toLowerCase();
    
    // Check for urgent keywords
    if (lowerTask.contains('urgent') || lowerTask.contains('asap') || 
        lowerTask.contains('immediately') || lowerTask.contains('critical')) {
      return Priority.urgent;
    }
    
    // Check for high priority keywords
    if (lowerTask.contains('important') || lowerTask.contains('deadline') || 
        lowerTask.contains('due') || overallPriority == 'high') {
      return Priority.high;
    }
    
    // Check for low priority keywords
    if (lowerTask.contains('when time') || lowerTask.contains('optional') || 
        lowerTask.contains('later') || overallPriority == 'low') {
      return Priority.low;
    }
    
    return Priority.medium; // Default
  }

  /// Parse content type from string
  ContentType _parseContentTypeFromString(String typeString) {
    switch (typeString.toLowerCase()) {
      case 'meeting': return ContentType.meeting;
      case 'todo': return ContentType.todo;
      case 'brainstorm': return ContentType.brainstorm;
      case 'technical': return ContentType.technical;
      case 'planning': return ContentType.brainstorm; // Map planning to brainstorm
      case 'personal': return ContentType.personal;
      case 'research': return ContentType.technical; // Map research to technical
      case 'mixed': return ContentType.mixed;
      default: return ContentType.notes;
    }
  }

  /// Generate tags from structured sections
  List<String> _generateTagsFromStructured(Map<String, String> sections) {
    final tags = <String>[];
    
    // Add page type tag
    final pageType = sections['rocketbook_page_type'] ?? '';
    if (pageType.isNotEmpty) {
      tags.add(pageType);
    }
    
    // Add priority tag
    final priority = sections['priority_level'] ?? '';
    if (priority.isNotEmpty && priority != 'medium') {
      tags.add('priority-$priority');
    }
    
    // Add RocketBook tag
    tags.add('rocketbook');
    
    // Add AI analysis tag
    tags.add('ai-analyzed');
    
    // Extract key topic tags
    final keyTopics = sections['key_topics'] ?? '';
    if (keyTopics.isNotEmpty) {
      final topics = keyTopics.split(',').take(3);
      for (final topic in topics) {
        final cleanTopic = topic.trim().toLowerCase().replaceAll(RegExp(r'[^\w]'), '-');
        if (cleanTopic.isNotEmpty && cleanTopic.length <= 20) {
          tags.add(cleanTopic);
        }
      }
    }
    
    return tags.take(8).toList(); // Limit to 8 tags
  }

  /// Infer sentiment from priority level
  double _inferSentimentFromPriority(String priorityLevel) {
    switch (priorityLevel.toLowerCase()) {
      case 'urgent': return -0.3; // Slightly negative (stressful)
      case 'high': return 0.1;    // Slightly positive (important)
      case 'low': return 0.5;     // Positive (relaxed)
      default: return 0.0;        // Neutral
    }
  }
}
