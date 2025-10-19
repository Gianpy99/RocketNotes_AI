/// INTEGRATION EXAMPLE: How to use EnhancedPrompts in ai_service.dart
/// 
/// This file shows the exact code modifications needed to enable
/// vision-powered AI analysis with rock solid prompts.
///
/// COPY-PASTE this code into your ai_service.dart file.

import 'dart:io';
import 'dart:convert';
import 'enhanced_prompts.dart';

// ============================================================================
// STEP 1: Add helper method to check vision support
// ============================================================================

class AIService {
  // ... existing code ...
  
  /// Check if a model supports vision/image input
  bool _modelSupportsVision(String modelName) {
    final lowerModel = modelName.toLowerCase();
    
    // OpenAI Vision models
    if (lowerModel.contains('gpt-4-vision') || 
        lowerModel.contains('gpt-4o') ||
        lowerModel.contains('gpt-4-turbo-2024') ||
        lowerModel.contains('chatgpt-4o-latest')) {
      return true;
    }
    
    // Google Gemini Vision models
    if (lowerModel.contains('gemini-pro-vision') ||
        lowerModel.contains('gemini-1.5') ||
        lowerModel.contains('gemini-2.0') ||
        lowerModel.contains('gemini-flash')) {
      return true;
    }
    
    // Anthropic Claude Vision models
    if (lowerModel.contains('claude-3')) {
      return true;
    }
    
    // OpenRouter vision models
    if (lowerModel.contains('vision') || 
        lowerModel.contains('llava') ||
        lowerModel.contains('cogvlm')) {
      return true;
    }
    
    return false;
  }
  
  /// Decide if we should use vision for this content
  /// (Optimize costs by using vision only when beneficial)
  bool _shouldUseVision(ScannedContent content, String model) {
    // Model must support vision
    if (!_modelSupportsVision(model)) return false;
    
    // Must have image
    if (content.imagePath.isEmpty) return false;
    
    // Use vision if:
    final lowConfidence = content.ocrMetadata.overallConfidence < 0.7;
    final littleText = content.rawText.trim().length < 100;
    final hasSymbols = RegExp(r'[★☆🚀🍀💎☁✉📁☐□☑☒]').hasMatch(content.rawText);
    final isRocketbook = EnhancedPrompts.detectRocketbookPage(content.rawText);
    
    return lowConfidence || littleText || hasSymbols || isRocketbook;
  }
  
  // ... existing code ...
}

// ============================================================================
// STEP 2: Modify _analyzeWithOpenAI() to send image
// ============================================================================

Future<AIAnalysis> _analyzeWithOpenAI(ScannedContent scannedContent) async {
  if (!ApiConfig.hasOpenAIKey) {
    DebugLogger().log('❌ AI Service: OpenAI API key not configured');
    return _fallbackAnalysis(scannedContent);
  }

  try {
    DebugLogger().log('🚀 AI Service: Starting OpenAI analysis...');
    
    // Get settings and determine model
    final settings = await _settingsRepository.getSettings();
    final bool hasImage = scannedContent.imagePath.isNotEmpty;
    
    // Select model based on image presence
    final String configuredModel = hasImage 
        ? settings.getEffectiveImageModel()
        : settings.getEffectiveTextModel();
    
    DebugLogger().log('⚙️ Using model: $configuredModel');
    
    // ═══════════════════════════════════════════════════════════════════════
    // NEW: Determine if we should use vision
    // ═══════════════════════════════════════════════════════════════════════
    final bool shouldSendImage = _shouldUseVision(scannedContent, configuredModel);
    DebugLogger().log('🖼️ Vision enabled: $shouldSendImage');
    
    // ═══════════════════════════════════════════════════════════════════════
    // NEW: Use EnhancedPrompts instead of old prompts
    // ═══════════════════════════════════════════════════════════════════════
    final systemPrompt = shouldSendImage
        ? EnhancedPrompts.getVisionSystemPrompt()
        : EnhancedPrompts.getTextOnlySystemPrompt();
    
    final isRocketbook = EnhancedPrompts.detectRocketbookPage(scannedContent.rawText);
    
    final userPrompt = shouldSendImage
        ? EnhancedPrompts.buildVisionUserPrompt(
            ocrText: scannedContent.rawText,
            ocrConfidence: scannedContent.ocrMetadata.overallConfidence,
            ocrEngine: scannedContent.ocrMetadata.engine,
            detectedLanguages: scannedContent.ocrMetadata.detectedLanguages,
            isRocketbookPage: isRocketbook,
            processingTimeMs: scannedContent.ocrMetadata.processingTimeMs,
          )
        : EnhancedPrompts.buildTextOnlyUserPrompt(
            ocrText: scannedContent.rawText,
            ocrConfidence: scannedContent.ocrMetadata.overallConfidence,
            ocrEngine: scannedContent.ocrMetadata.engine,
            detectedLanguages: scannedContent.ocrMetadata.detectedLanguages,
            isRocketbookPage: isRocketbook,
          );
    
    // ═══════════════════════════════════════════════════════════════════════
    // NEW: Build user message (with image if vision enabled)
    // ═══════════════════════════════════════════════════════════════════════
    dynamic userMessage;
    
    if (shouldSendImage) {
      DebugLogger().log('📷 Loading image for vision analysis...');
      try {
        final imageFile = File(scannedContent.imagePath);
        final imageBytes = await imageFile.readAsBytes();
        final base64Image = base64Encode(imageBytes);
        
        DebugLogger().log('✅ Image encoded: ${(imageBytes.length / 1024).toStringAsFixed(1)} KB');
        
        // OpenAI Vision API format
        userMessage = {
          'role': 'user',
          'content': [
            {
              'type': 'text',
              'text': userPrompt,
            },
            {
              'type': 'image_url',
              'image_url': {
                'url': 'data:image/jpeg;base64,$base64Image',
                'detail': 'high',  // Request detailed analysis
              },
            },
          ],
        };
      } catch (imageError) {
        DebugLogger().log('❌ Failed to load image: $imageError');
        DebugLogger().log('⚠️ Falling back to text-only analysis');
        userMessage = {
          'role': 'user',
          'content': userPrompt,
        };
      }
    } else {
      // Text-only message
      userMessage = {
        'role': 'user',
        'content': userPrompt,
      };
    }
    
    // ═══════════════════════════════════════════════════════════════════════
    // Send request to OpenAI
    // ═══════════════════════════════════════════════════════════════════════
    DebugLogger().log('📤 Sending request to OpenAI API');
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
        'service_tier': settings.openAIServiceTier,
        'messages': [
          {
            'role': 'system',
            'content': systemPrompt,
          },
          userMessage,  // ✅ Now includes image if vision-enabled!
        ],
        'temperature': 0.3,  // Lower for more consistent structured output
        'max_tokens': 3000,  // Increased for richer analysis
      },
    );

    DebugLogger().log('✅ Received response from OpenAI');
    final content = response.data['choices'][0]['message']['content'];
    
    // Log usage for cost tracking
    if (response.data.containsKey('usage')) {
      final usage = response.data['usage'];
      DebugLogger().log('💰 Token usage: ${usage['total_tokens']} (prompt: ${usage['prompt_tokens']}, completion: ${usage['completion_tokens']})');
    }
    
    // Parse enhanced response
    final analysis = _parseAIResponse(content);
    
    DebugLogger().log('🎯 Analysis completed - ${analysis.keyTopics.length} topics, ${analysis.actionItems.length} actions');
    return analysis;
    
  } catch (e, stackTrace) {
    DebugLogger().log('❌ AI Service: OpenAI error: $e');
    DebugLogger().log('Stack trace: $stackTrace');
    return _fallbackAnalysis(scannedContent);
  }
}

// ============================================================================
// STEP 3: Modify _analyzeWithGemini() to send image
// ============================================================================

Future<AIAnalysis> _analyzeWithGemini(ScannedContent scannedContent) async {
  if (!ApiConfig.hasGeminiKey) {
    DebugLogger().log('❌ AI Service: Gemini API key not configured');
    return _fallbackAnalysis(scannedContent);
  }

  try {
    DebugLogger().log('🚀 AI Service: Starting Gemini analysis...');
    
    // Get settings and model
    final settings = await _settingsRepository.getSettings();
    final bool hasImage = scannedContent.imagePath.isNotEmpty;
    
    final String configuredModel = hasImage 
        ? settings.getEffectiveImageModel()
        : settings.getEffectiveTextModel();
    
    DebugLogger().log('⚙️ Using model: $configuredModel');
    
    // ═══════════════════════════════════════════════════════════════════════
    // NEW: Vision support for Gemini
    // ═══════════════════════════════════════════════════════════════════════
    final bool shouldSendImage = _shouldUseVision(scannedContent, configuredModel);
    DebugLogger().log('🖼️ Vision enabled: $shouldSendImage');
    
    final systemPrompt = shouldSendImage
        ? EnhancedPrompts.getVisionSystemPrompt()
        : EnhancedPrompts.getTextOnlySystemPrompt();
    
    final isRocketbook = EnhancedPrompts.detectRocketbookPage(scannedContent.rawText);
    
    final userPrompt = shouldSendImage
        ? EnhancedPrompts.buildVisionUserPrompt(
            ocrText: scannedContent.rawText,
            ocrConfidence: scannedContent.ocrMetadata.overallConfidence,
            ocrEngine: scannedContent.ocrMetadata.engine,
            detectedLanguages: scannedContent.ocrMetadata.detectedLanguages,
            isRocketbookPage: isRocketbook,
            processingTimeMs: scannedContent.ocrMetadata.processingTimeMs,
          )
        : EnhancedPrompts.buildTextOnlyUserPrompt(
            ocrText: scannedContent.rawText,
            ocrConfidence: scannedContent.ocrMetadata.overallConfidence,
            ocrEngine: scannedContent.ocrMetadata.engine,
            detectedLanguages: scannedContent.ocrMetadata.detectedLanguages,
            isRocketbookPage: isRocketbook,
          );
    
    // ═══════════════════════════════════════════════════════════════════════
    // NEW: Build parts array (text + image for vision models)
    // ═══════════════════════════════════════════════════════════════════════
    final List<Map<String, dynamic>> parts = [];
    
    // Add text
    parts.add({
      'text': '$systemPrompt\n\n$userPrompt',
    });
    
    // Add image if vision enabled
    if (shouldSendImage) {
      DebugLogger().log('📷 Loading image for Gemini vision...');
      try {
        final imageFile = File(scannedContent.imagePath);
        final imageBytes = await imageFile.readAsBytes();
        final base64Image = base64Encode(imageBytes);
        
        DebugLogger().log('✅ Image encoded: ${(imageBytes.length / 1024).toStringAsFixed(1)} KB');
        
        // Gemini Vision API format
        parts.add({
          'inline_data': {
            'mime_type': 'image/jpeg',
            'data': base64Image,
          },
        });
      } catch (imageError) {
        DebugLogger().log('❌ Failed to load image: $imageError');
        DebugLogger().log('⚠️ Continuing with text-only');
      }
    }
    
    // ═══════════════════════════════════════════════════════════════════════
    // Send request to Gemini
    // ═══════════════════════════════════════════════════════════════════════
    DebugLogger().log('📤 Sending request to Gemini API');
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
            'parts': parts,  // ✅ Now includes image if vision-enabled!
          }
        ],
        'generationConfig': {
          'temperature': 0.3,
          'maxOutputTokens': 3000,
        },
      },
    );

    DebugLogger().log('✅ Received response from Gemini');
    
    // Extract content (with null safety)
    final responseData = response.data;
    if (responseData == null || responseData is! Map<String, dynamic>) {
      throw Exception('Invalid response from Gemini');
    }
    
    final candidates = responseData['candidates'];
    if (candidates == null || candidates is! List || candidates.isEmpty) {
      throw Exception('No candidates in Gemini response');
    }
    
    final content = candidates[0]['content']['parts'][0]['text'];
    
    // Parse response
    final analysis = _parseAIResponse(content);
    
    DebugLogger().log('🎯 Gemini analysis completed');
    return analysis;
    
  } catch (e, stackTrace) {
    DebugLogger().log('❌ AI Service: Gemini error: $e');
    DebugLogger().log('Stack trace: $stackTrace');
    return _fallbackAnalysis(scannedContent);
  }
}

// ============================================================================
// STEP 4: Update parser to handle new fields from EnhancedPrompts
// ============================================================================

AIAnalysis _parseStructuredResponse(String response) {
  final Map<String, String> sections = {};
  
  // Extract sections using regex
  final sectionPattern = RegExp(
    r'(\w+(?:_\w+)*):\s*(.+?)(?=\n\w+(?:_\w+)*:|$)', 
    dotAll: true
  );
  
  for (final match in sectionPattern.allMatches(response)) {
    final key = match.group(1)!;
    final value = match.group(2)!.trim();
    sections[key] = value;
  }
  
  // ═══════════════════════════════════════════════════════════════════════
  // Extract all fields (including new ones from EnhancedPrompts)
  // ═══════════════════════════════════════════════════════════════════════
  
  return AIAnalysis(
    // Core fields
    title: sections['TITLE'] ?? 'Untitled Note',
    summary: sections['SUMMARY'] ?? '',
    pageType: sections['PAGE_TYPE'] ?? 'mixed',
    
    // NEW: Corrected text (OCR errors fixed by AI)
    correctedText: sections['CORRECTED_TEXT'] ?? sections['SUMMARY'] ?? '',
    
    // Action items
    actionItems: _parseListField(sections['TASKS']),
    
    // Deadlines
    deadlines: _parseListField(sections['DEADLINES']),
    
    // People and entities
    peopleMentioned: _parseCommaSeparated(sections['PEOPLE_MENTIONED']),
    organizations: _parseCommaSeparated(sections['ORGANIZATIONS']),
    locations: _parseCommaSeparated(sections['LOCATIONS']),
    
    // Topics and keywords
    keyTopics: _parseCommaSeparated(sections['KEY_TOPICS']),
    technicalTerms: _parseCommaSeparated(sections['TECHNICAL_TERMS']),
    searchKeywords: _parseCommaSeparated(sections['SEARCH_KEYWORDS']),
    
    // NEW: Visual analysis
    visualElements: sections['VISUAL_ELEMENTS'] ?? 'None',
    rocketbookSymbols: _parseCommaSeparated(sections['ROCKETBOOK_SYMBOLS']),
    
    // Quality indicators
    handwritingQuality: sections['HANDWRITING_QUALITY'] ?? 'good',
    confidenceScore: int.tryParse(sections['CONFIDENCE_SCORE'] ?? '80') ?? 80,
    
    // Priority and sentiment
    priorityLevel: sections['PRIORITY_LEVEL'] ?? 'medium',
    sentiment: sections['SENTIMENT'] ?? 'neutral',
    
    // Next actions
    nextActions: _parseListField(sections['NEXT_ACTIONS']),
    
    // Additional notes
    notes: sections['NOTES'] ?? '',
  );
}

// ═══════════════════════════════════════════════════════════════════════
// Helper methods for parsing
// ═══════════════════════════════════════════════════════════════════════

List<String> _parseListField(String? text) {
  if (text == null || text.trim().isEmpty || text.toLowerCase() == 'none') {
    return [];
  }
  
  return text
      .split('\n')
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .map((line) => line.replaceFirst(RegExp(r'^[-•*]\s*'), ''))
      .where((line) => line.isNotEmpty && line.toLowerCase() != 'none')
      .toList();
}

List<String> _parseCommaSeparated(String? text) {
  if (text == null || text.trim().isEmpty || text.toLowerCase() == 'none' || text.toLowerCase() == 'n/a') {
    return [];
  }
  
  return text
      .split(',')
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty && item.toLowerCase() != 'none')
      .toList();
}

// ============================================================================
// STEP 5: Update AIAnalysis model to include new fields
// ============================================================================

class AIAnalysis {
  final String title;
  final String summary;
  final String pageType;
  final String correctedText;  // NEW
  
  final List<String> actionItems;
  final List<String> deadlines;
  
  final List<String> peopleMentioned;
  final List<String> organizations;  // NEW
  final List<String> locations;  // NEW
  
  final List<String> keyTopics;
  final List<String> technicalTerms;  // NEW
  final List<String> searchKeywords;  // NEW
  
  final String visualElements;  // NEW
  final List<String> rocketbookSymbols;  // NEW
  
  final String handwritingQuality;  // NEW
  final int confidenceScore;  // NEW (0-100)
  
  final String priorityLevel;
  final String sentiment;
  
  final List<String> nextActions;
  final String notes;

  AIAnalysis({
    required this.title,
    required this.summary,
    required this.pageType,
    this.correctedText = '',
    this.actionItems = const [],
    this.deadlines = const [],
    this.peopleMentioned = const [],
    this.organizations = const [],
    this.locations = const [],
    this.keyTopics = const [],
    this.technicalTerms = const [],
    this.searchKeywords = const [],
    this.visualElements = 'None',
    this.rocketbookSymbols = const [],
    this.handwritingQuality = 'good',
    this.confidenceScore = 80,
    this.priorityLevel = 'medium',
    this.sentiment = 'neutral',
    this.nextActions = const [],
    this.notes = '',
  });
}
