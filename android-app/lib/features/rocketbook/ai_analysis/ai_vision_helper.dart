/// Vision and Template Detection Helpers for AI Service
/// 
/// This file provides helper methods to:
/// - Detect if AI models support vision
/// - Determine when to use vision (cost optimization)
/// - Detect Rocketbook templates
/// - Build enhanced prompts with template-specific instructions

import 'dart:io';
import 'dart:convert';
import 'enhanced_prompts.dart';
import '../models/scanned_content.dart';
import '../../../core/debug/debug_logger.dart';

class AIVisionHelper {
  
  /// Check if a model supports vision/image input
  static bool modelSupportsVision(String modelName) {
    final lowerModel = modelName.toLowerCase();
    
    // OpenAI Vision models
    if (lowerModel.contains('gpt-4-vision') || 
        lowerModel.contains('gpt-4o') ||
        lowerModel.contains('gpt-4-turbo') ||
        lowerModel.contains('chatgpt-4o-latest') ||
        lowerModel.contains('gpt-5') ||  // GPT-5 supports vision
        lowerModel.startsWith('o1-')) {   // O1 series
      return true;
    }
    
    // Google Gemini Vision models
    if (lowerModel.contains('gemini-pro-vision') ||
        lowerModel.contains('gemini-1.5') ||
        lowerModel.contains('gemini-2.0') ||
        lowerModel.contains('gemini-2.5') ||  // ✅ Gemini 2.5 Flash
        lowerModel.contains('gemini-2-') ||   // ✅ Gemini 2.x variants
        lowerModel.contains('gemini-flash') ||
        lowerModel.contains('gemini-exp')) {
      return true;
    }
    
    // Anthropic Claude Vision models
    if (lowerModel.contains('claude-3') ||
        lowerModel.contains('claude-4')) {
      return true;
    }
    
    // OpenRouter vision models
    if (lowerModel.contains('vision') || 
        lowerModel.contains('llava') ||
        lowerModel.contains('cogvlm') ||
        lowerModel.contains('qwen-vl')) {
      return true;
    }
    
    // Ollama Cloud vision models
    if (lowerModel.contains('llama3.2-vision') ||
        lowerModel.contains('llava')) {
      return true;
    }
    
    return false;
  }
  
  /// Decide if we should use vision for this content
  /// (Optimize costs by using vision only when beneficial)
  static bool shouldUseVision(ScannedContent content, String model) {
    // Model must support vision
    final supportsVision = modelSupportsVision(model);
    DebugLogger().log('🔍 Vision check - Model: "$model", Supports vision: $supportsVision');
    
    if (!supportsVision) {
      DebugLogger().log('❌ Vision disabled: Model does not support vision');
      return false;
    }
    
    // Must have image
    if (content.imagePath.isEmpty) {
      DebugLogger().log('❌ Vision disabled: No image path');
      return false;
    }
    
    // Use vision if:
    final lowConfidence = content.ocrMetadata.overallConfidence < 0.7;
    final littleText = content.rawText.trim().length < 100;
    final hasSymbols = RegExp(r'[★☆🚀🍀💎☁✉📁☐□☑☒]').hasMatch(content.rawText);
    final isRocketbook = EnhancedPrompts.detectRocketbookPage(content.rawText);
    final hasTables = content.tables.isNotEmpty;
    final hasDiagrams = content.diagrams.isNotEmpty;
    
    // 🆕 ALWAYS use vision for handwritten text (OCR is never perfect for handwriting!)
    final isHandwritten = content.ocrMetadata.engine.contains('handwritten') ||
                          content.rawText.length < 200 ||  // Short text often = handwritten
                          lowConfidence;  // Low confidence = likely handwritten
    
    final useVision = isHandwritten || littleText || hasSymbols || isRocketbook || hasTables || hasDiagrams;
    
    DebugLogger().log('✅ Vision decision: $useVision (handwritten: $isHandwritten, textLen: ${content.rawText.length}, confidence: ${content.ocrMetadata.overallConfidence})');
    
    return useVision;
  }
  
  /// Build system prompt with template-specific enhancements
  static String buildSystemPrompt({
    required bool useVision,
    required RocketbookTemplate template,
  }) {
    String basePrompt = useVision
        ? EnhancedPrompts.getVisionSystemPrompt()
        : EnhancedPrompts.getTextOnlySystemPrompt();
    
    // Add template-specific instructions if recognized
    if (template != RocketbookTemplate.unknown && template != RocketbookTemplate.blank) {
      final templateInstructions = EnhancedPrompts.getTemplateSpecificInstructions(template);
      basePrompt += templateInstructions;
    }
    
    return basePrompt;
  }
  
  /// Build user prompt with all context
  static String buildUserPrompt({
    required ScannedContent content,
    required bool useVision,
    required RocketbookTemplate template,
  }) {
    final isRocketbook = EnhancedPrompts.detectRocketbookPage(content.rawText) ||
                         template != RocketbookTemplate.unknown;
    
    if (useVision) {
      return EnhancedPrompts.buildVisionUserPrompt(
        ocrText: content.rawText,
        ocrConfidence: content.ocrMetadata.overallConfidence,
        ocrEngine: content.ocrMetadata.engine,
        detectedLanguages: content.ocrMetadata.detectedLanguages,
        isRocketbookPage: isRocketbook,
        processingTimeMs: content.ocrMetadata.processingTimeMs,
      );
    } else {
      return EnhancedPrompts.buildTextOnlyUserPrompt(
        ocrText: content.rawText,
        ocrConfidence: content.ocrMetadata.overallConfidence,
        ocrEngine: content.ocrMetadata.engine,
        detectedLanguages: content.ocrMetadata.detectedLanguages,
        isRocketbookPage: isRocketbook,
      );
    }
  }
  
  /// Load and encode image as base64
  static Future<String?> encodeImageBase64(String imagePath) async {
    try {
      final imageFile = File(imagePath);
      if (!await imageFile.exists()) {
        return null;
      }
      
      final imageBytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(imageBytes);
      
      return base64Image;
    } catch (e) {
      return null;
    }
  }
  
  /// Build OpenAI-style message with vision support
  static Future<Map<String, dynamic>> buildOpenAIMessage({
    required String userPrompt,
    required ScannedContent content,
    required bool useVision,
  }) async {
    if (!useVision || content.imagePath.isEmpty) {
      // Text-only message
      return {
        'role': 'user',
        'content': userPrompt,
      };
    }
    
    // Vision message
    final base64Image = await encodeImageBase64(content.imagePath);
    if (base64Image == null) {
      // Fallback to text-only if image loading failed
      return {
        'role': 'user',
        'content': userPrompt,
      };
    }
    
    return {
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
  }
  
  /// Build Gemini-style parts with vision support
  static Future<List<Map<String, dynamic>>> buildGeminiParts({
    required String combinedPrompt,
    required ScannedContent content,
    required bool useVision,
  }) async {
    final List<Map<String, dynamic>> parts = [];
    
    // Add text
    parts.add({
      'text': combinedPrompt,
    });
    
    // Add image if vision enabled
    if (useVision && content.imagePath.isNotEmpty) {
      final base64Image = await encodeImageBase64(content.imagePath);
      if (base64Image != null) {
        // Gemini Vision API format
        parts.add({
          'inline_data': {
            'mime_type': 'image/jpeg',
            'data': base64Image,
          },
        });
      }
    }
    
    return parts;
  }
  
  /// Get template name for logging
  static String getTemplateName(RocketbookTemplate template) {
    switch (template) {
      case RocketbookTemplate.meeting:
        return 'Meeting Notes';
      case RocketbookTemplate.todo:
        return 'To-Do List';
      case RocketbookTemplate.weekly:
        return 'Weekly Planner';
      case RocketbookTemplate.goals:
        return 'Goal Setting';
      case RocketbookTemplate.brainstorm:
        return 'Brainstorm';
      case RocketbookTemplate.blank:
        return 'Blank Rocketbook';
      case RocketbookTemplate.unknown:
        return 'Generic Notes';
    }
  }
  
  /// Estimate token usage for vision request
  static int estimateVisionTokens({
    required String systemPrompt,
    required String userPrompt,
    required bool includesImage,
  }) {
    // Rough estimation: ~1.3 tokens per word
    final textTokens = ((systemPrompt.length + userPrompt.length) / 4 * 1.3).round();
    
    // Images typically use ~765 tokens (high detail) or ~255 tokens (low detail)
    final imageTokens = includesImage ? 765 : 0;
    
    return textTokens + imageTokens;
  }
  
  /// Calculate estimated cost for vision request
  static double estimateCost({
    required String model,
    required int inputTokens,
    required int estimatedOutputTokens,
  }) {
    // Simplified pricing (per 1K tokens)
    final lowerModel = model.toLowerCase();
    
    double inputPrice = 0.0;
    double outputPrice = 0.0;
    
    if (lowerModel.contains('gpt-4o')) {
      inputPrice = 2.50;
      outputPrice = 10.00;
    } else if (lowerModel.contains('gpt-4')) {
      inputPrice = 10.00;
      outputPrice = 30.00;
    } else if (lowerModel.contains('gemini-1.5-flash')) {
      inputPrice = 0.075;
      outputPrice = 0.30;
    } else if (lowerModel.contains('gemini-1.5-pro')) {
      inputPrice = 1.25;
      outputPrice = 5.00;
    } else if (lowerModel.contains('gpt-3.5')) {
      inputPrice = 0.50;
      outputPrice = 1.50;
    }
    
    final inputCost = (inputTokens / 1000.0) * inputPrice;
    final outputCost = (estimatedOutputTokens / 1000.0) * outputPrice;
    
    return inputCost + outputCost;
  }
}
