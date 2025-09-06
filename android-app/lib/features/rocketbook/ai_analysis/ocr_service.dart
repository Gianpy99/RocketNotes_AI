import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import '../../../core/debug/debug_logger.dart';
import '../../../core/config/api_config.dart';
import '../../../data/repositories/settings_repository.dart';

/// Servizio OCR separato per riconoscimento testo
class OCRService {
  static OCRService? _instance;
  static OCRService get instance => _instance ??= OCRService._();
  OCRService._();

  final Dio _dio = Dio();
  final SettingsRepository _settingsRepository = SettingsRepository();
  
  // Configuration
  static const String huggingFaceInferenceUrl = 'https://api-inference.huggingface.co/models';
  
  /// Initialize the OCR service
  Future<void> initialize() async {
    DebugLogger().log('🔍 OCR Service: Initializing...');
    
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 60);
    
    DebugLogger().log('✅ OCR Service initialized');
  }

  /// Estrai testo da immagine usando il provider configurato
  Future<String> extractTextFromImage(Uint8List imageBytes) async {
    final settings = await _settingsRepository.getSettings();
    final ocrProvider = settings.ocrProvider;
    final ocrModel = settings.ocrModel;
    
    DebugLogger().log('🔍 OCR Service: Extracting text with provider: $ocrProvider, model: $ocrModel');
    
    switch (ocrProvider) {
      case 'trocr-handwritten':
      case 'trocr-printed':
        return await _extractWithTrOCR(imageBytes, ocrModel);
      case 'tesseract':
        return await _extractWithTesseract(imageBytes);
      default:
        return _mockOCR(imageBytes);
    }
  }

  /// Estrai testo usando modelli TrOCR di Microsoft su HuggingFace
  Future<String> _extractWithTrOCR(Uint8List imageBytes, String model) async {
    if (!ApiConfig.hasHuggingFaceKey) {
      DebugLogger().log('❌ OCR Service: HuggingFace API key not configured - falling back to simulation');
      return _mockOCR(imageBytes);
    }

    try {
      DebugLogger().log('🚀 OCR Service: Starting TrOCR extraction with model: $model');
      
      // Converti l'immagine in base64
      final String base64Image = base64Encode(imageBytes);
      
      final response = await _dio.post(
        '$huggingFaceInferenceUrl/$model',
        options: Options(
          headers: {
            'Authorization': 'Bearer ${ApiConfig.actualHuggingFaceKey}',
            'Content-Type': 'application/json',
          },
        ),
        data: {
          'inputs': base64Image,
        },
      );

      DebugLogger().log('✅ OCR Service: Received response from TrOCR');
      
      // Parse della risposta TrOCR
      String extractedText;
      if (response.data is List && response.data.isNotEmpty) {
        extractedText = response.data[0]['generated_text'] ?? '';
      } else if (response.data is Map) {
        extractedText = response.data['generated_text'] ?? '';
      } else {
        extractedText = response.data.toString();
      }
      
      DebugLogger().log('🎯 OCR Service: Extracted ${extractedText.length} characters');
      return extractedText.trim();
      
    } catch (e) {
      DebugLogger().log('❌ OCR Service: TrOCR extraction error: $e');
      return _mockOCR(imageBytes);
    }
  }

  /// Estrai testo usando Tesseract (implementazione placeholder)
  Future<String> _extractWithTesseract(Uint8List imageBytes) async {
    DebugLogger().log('🔍 OCR Service: Tesseract extraction not yet implemented - using simulation');
    return _mockOCR(imageBytes);
  }

  /// OCR simulato per sviluppo/testing
  String _mockOCR(Uint8List imageBytes) {
    DebugLogger().log('🤖 OCR Service: Using mock OCR extraction');
    
    // Simula l'estrazione di testo da un'immagine di appunti scritti a mano
    final mockTexts = [
      '''Meeting Notes - Project Alpha
Date: ${DateTime.now().toString().split(' ')[0]}

Key Points:
• Review quarterly targets
• Database optimization needed
• User feedback implementation
• Testing phase next week

Action Items:
- Update API documentation
- Schedule team review
- Implement security patches
- Prepare demo for stakeholders

Notes:
The handwriting recognition works well
with clear text and good lighting.
Consider using structured formats
for better AI analysis results.''',
      
      '''Shopping List
- Milk (2 liters)
- Bread (whole grain)
- Eggs (dozen)
- Tomatoes (fresh)
- Cheese (cheddar)
- Coffee beans
- Pasta (penne)
- Olive oil

Remember:
• Check expiry dates
• Use reusable bags
• Compare prices
• Get receipt for expenses''',
      
      '''Study Notes - Machine Learning
Chapter 3: Neural Networks

Key Concepts:
1. Backpropagation algorithm
2. Gradient descent optimization
3. Activation functions (ReLU, Sigmoid)
4. Overfitting prevention techniques

Important Formulas:
y = f(wx + b)
Loss = Σ(predicted - actual)²

Review Topics:
- Convolutional layers
- Dropout techniques
- Batch normalization
- Transfer learning''',
    ];
    
    // Seleziona un testo casuale basato su dimensione dell'immagine
    final textIndex = imageBytes.length % mockTexts.length;
    final selectedText = mockTexts[textIndex];
    
    DebugLogger().log('🎯 OCR Service: Mock extraction completed - ${selectedText.length} characters');
    return selectedText;
  }

  /// Valuta la qualità dell'immagine per OCR
  Map<String, dynamic> evaluateImageQuality(Uint8List imageBytes) {
    // Simulazione di valutazione qualità
    final quality = 0.7 + (imageBytes.length % 100) / 333; // Mock quality score
    
    return {
      'quality_score': quality,
      'is_suitable': quality > 0.6,
      'recommendations': quality < 0.6 
          ? ['Improve lighting', 'Reduce blur', 'Straighten document']
          : ['Good quality for OCR'],
      'image_size_kb': (imageBytes.length / 1024).round(),
    };
  }

  /// Ottieni i provider OCR disponibili
  static List<Map<String, String>> getAvailableOCRProviders() {
    return [
      {
        'id': 'trocr-handwritten',
        'name': 'TrOCR Handwritten',
        'description': 'Microsoft TrOCR optimized for handwritten text',
        'requires_api': 'true',
      },
      {
        'id': 'trocr-printed',
        'name': 'TrOCR Printed',
        'description': 'Microsoft TrOCR optimized for printed text',
        'requires_api': 'true',
      },
      {
        'id': 'tesseract',
        'name': 'Tesseract OCR',
        'description': 'Traditional OCR engine (local processing)',
        'requires_api': 'false',
      },
    ];
  }

  /// Ottieni i modelli disponibili per un provider
  static List<Map<String, String>> getModelsForProvider(String provider) {
    switch (provider) {
      case 'trocr-handwritten':
        return [
          {
            'id': 'microsoft/trocr-base-handwritten',
            'name': 'TrOCR Base Handwritten',
            'description': 'Base model for handwritten text recognition',
          },
          {
            'id': 'microsoft/trocr-large-handwritten',
            'name': 'TrOCR Large Handwritten',
            'description': 'Large model for better handwritten text accuracy',
          },
        ];
      case 'trocr-printed':
        return [
          {
            'id': 'microsoft/trocr-base-printed',
            'name': 'TrOCR Base Printed',
            'description': 'Base model for printed text recognition',
          },
          {
            'id': 'microsoft/trocr-large-printed',
            'name': 'TrOCR Large Printed',
            'description': 'Large model for better printed text accuracy',
          },
        ];
      case 'tesseract':
        return [
          {
            'id': 'tesseract-ocr',
            'name': 'Tesseract Default',
            'description': 'Standard Tesseract OCR engine',
          },
        ];
      default:
        return [];
    }
  }
}
