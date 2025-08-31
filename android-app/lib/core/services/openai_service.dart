import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:image/image.dart' as img;
import 'openai_config.dart';

class OpenAIService {
  static const String _baseUrl = 'https://api.openai.com/v1';
  late final Dio _dio;
  
  // API Key da file di configurazione separato (ignorato da git)
  static String get _apiKey => OpenAIConfig.apiKey;

  // Metodo per controllare se l'API key è configurata
  static bool isApiKeyMissing() {
    return _apiKey == 'your-openai-api-key-here' || _apiKey.isEmpty;
  }
  
  OpenAIService() {
    _dio = Dio();
    _dio.options.headers = {
      'Authorization': 'Bearer $_apiKey',
      'Content-Type': 'application/json',
    };
  }

  /// Analizza un'immagine di un notebook Rocketbook usando GPT-4 Vision
  Future<RocketbookAnalysis> analyzeRocketbookImage(File imageFile) async {
    try {
      // Comprimi l'immagine per ridurre i costi API
      final compressedImageBytes = await _compressImage(imageFile);
      final base64Image = base64Encode(compressedImageBytes);

      final response = await _dio.post(
        '$_baseUrl/chat/completions',
        data: {
          'model': OpenAIConfig.model, // Modello da configurazione
          'messages': [
            {
              'role': 'system',
              'content': _getRocketbookSystemPrompt(),
            },
            {
              'role': 'user',
              'content': [
                {
                  'type': 'text',
                  'text': 'Analizza questa pagina di notebook Rocketbook e estrai tutte le informazioni strutturate.'
                },
                {
                  'type': 'image_url',
                  'image_url': {
                    'url': 'data:image/jpeg;base64,$base64Image',
                    'detail': 'high'
                  }
                }
              ]
            }
          ],
          'max_tokens': OpenAIConfig.maxTokens,
          'temperature': OpenAIConfig.temperature, // Temperatura da configurazione
        },
      );

      final content = response.data['choices'][0]['message']['content'];
      return _parseRocketbookAnalysis(content);
    } catch (e) {
      throw Exception('Errore durante l\'analisi dell\'immagine: $e');
    }
  }

  /// Comprimi l'immagine per ridurre i costi API
  Future<List<int>> _compressImage(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final image = img.decodeImage(bytes);
    
    if (image == null) throw Exception('Impossibile decodificare l\'immagine');
    
    // Ridimensiona se troppo grande (usa config)
    final maxSize = OpenAIConfig.maxImageSize;
    final resized = image.width > maxSize || image.height > maxSize
        ? img.copyResize(image, width: maxSize)
        : image;
    
    // Comprimi come JPEG con qualità da configurazione
    return img.encodeJpg(resized, quality: OpenAIConfig.compressionQuality);
  }

  /// Prompt di sistema per l'analisi di Rocketbook
  String _getRocketbookSystemPrompt() {
    return '''
Sei un assistente AI specializzato nell'analisi di pagine di notebook Rocketbook.
Devi estrarre e strutturare tutte le informazioni dalla pagina.

IMPORTANTE: I notebook Rocketbook hanno questa struttura standard:
- Titolo in alto
- Corpo principale con note/testo
- Simboli in basso per le destinazioni (email, cloud, ecc.)
- Possibili elementi grafici (diagrammi, tabelle, liste)

Restituisci SEMPRE una risposta in formato JSON con questa struttura esatta:
{
  "title": "Titolo estratto o 'Senza titolo' se non presente",
  "content": "Testo principale completo",
  "sections": [
    {
      "type": "text|list|table|diagram",
      "content": "contenuto della sezione",
      "position": "top|middle|bottom"
    }
  ],
  "symbols": {
    "email": boolean,
    "google_drive": boolean,
    "dropbox": boolean,
    "evernote": boolean,
    "slack": boolean,
    "icloud": boolean,
    "onedrive": boolean
  },
  "metadata": {
    "page_quality": "good|fair|poor",
    "handwriting_legibility": "high|medium|low",
    "contains_diagrams": boolean,
    "language": "it|en|other"
  },
  "actions": [
    {
      "type": "reminder|task|meeting|note",
      "content": "contenuto specifico",
      "priority": "high|medium|low"
    }
  ]
}

Analizza attentamente l'immagine e estrai TUTTE le informazioni visibili.
''';
  }

  /// Parse della risposta AI in oggetto strutturato
  RocketbookAnalysis _parseRocketbookAnalysis(String content) {
    try {
      // Estrai il JSON dalla risposta (potrebbe essere avvolto in ```json```)
      final jsonStart = content.indexOf('{');
      final jsonEnd = content.lastIndexOf('}') + 1;
      final jsonString = content.substring(jsonStart, jsonEnd);
      
      final data = jsonDecode(jsonString);
      return RocketbookAnalysis.fromJson(data);
    } catch (e) {
      throw Exception('Errore nel parsing della risposta AI: $e');
    }
  }
}

/// Modello per l'analisi del Rocketbook
class RocketbookAnalysis {
  final String title;
  final String content;
  final List<RocketbookSection> sections;
  final RocketbookSymbols symbols;
  final RocketbookMetadata metadata;
  final List<RocketbookAction> actions;

  RocketbookAnalysis({
    required this.title,
    required this.content,
    required this.sections,
    required this.symbols,
    required this.metadata,
    required this.actions,
  });

  factory RocketbookAnalysis.fromJson(Map<String, dynamic> json) {
    return RocketbookAnalysis(
      title: json['title'] ?? 'Senza titolo',
      content: json['content'] ?? '',
      sections: (json['sections'] as List? ?? [])
          .map((s) => RocketbookSection.fromJson(s))
          .toList(),
      symbols: RocketbookSymbols.fromJson(json['symbols'] ?? {}),
      metadata: RocketbookMetadata.fromJson(json['metadata'] ?? {}),
      actions: (json['actions'] as List? ?? [])
          .map((a) => RocketbookAction.fromJson(a))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'content': content,
      'sections': sections.map((s) => s.toJson()).toList(),
      'symbols': symbols.toJson(),
      'metadata': metadata.toJson(),
      'actions': actions.map((a) => a.toJson()).toList(),
    };
  }
}

class RocketbookSection {
  final String type;
  final String content;
  final String position;

  RocketbookSection({
    required this.type,
    required this.content,
    required this.position,
  });

  factory RocketbookSection.fromJson(Map<String, dynamic> json) {
    return RocketbookSection(
      type: json['type'] ?? 'text',
      content: json['content'] ?? '',
      position: json['position'] ?? 'middle',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'content': content,
      'position': position,
    };
  }
}

class RocketbookSymbols {
  final bool email;
  final bool googleDrive;
  final bool dropbox;
  final bool evernote;
  final bool slack;
  final bool icloud;
  final bool onedrive;

  RocketbookSymbols({
    required this.email,
    required this.googleDrive,
    required this.dropbox,
    required this.evernote,
    required this.slack,
    required this.icloud,
    required this.onedrive,
  });

  factory RocketbookSymbols.fromJson(Map<String, dynamic> json) {
    return RocketbookSymbols(
      email: json['email'] ?? false,
      googleDrive: json['google_drive'] ?? false,
      dropbox: json['dropbox'] ?? false,
      evernote: json['evernote'] ?? false,
      slack: json['slack'] ?? false,
      icloud: json['icloud'] ?? false,
      onedrive: json['onedrive'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'google_drive': googleDrive,
      'dropbox': dropbox,
      'evernote': evernote,
      'slack': slack,
      'icloud': icloud,
      'onedrive': onedrive,
    };
  }
}

class RocketbookMetadata {
  final String pageQuality;
  final String handwritingLegibility;
  final bool containsDiagrams;
  final String language;

  RocketbookMetadata({
    required this.pageQuality,
    required this.handwritingLegibility,
    required this.containsDiagrams,
    required this.language,
  });

  factory RocketbookMetadata.fromJson(Map<String, dynamic> json) {
    return RocketbookMetadata(
      pageQuality: json['page_quality'] ?? 'fair',
      handwritingLegibility: json['handwriting_legibility'] ?? 'medium',
      containsDiagrams: json['contains_diagrams'] ?? false,
      language: json['language'] ?? 'it',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'page_quality': pageQuality,
      'handwriting_legibility': handwritingLegibility,
      'contains_diagrams': containsDiagrams,
      'language': language,
    };
  }
}

class RocketbookAction {
  final String type;
  final String content;
  final String priority;

  RocketbookAction({
    required this.type,
    required this.content,
    required this.priority,
  });

  factory RocketbookAction.fromJson(Map<String, dynamic> json) {
    return RocketbookAction(
      type: json['type'] ?? 'note',
      content: json['content'] ?? '',
      priority: json['priority'] ?? 'medium',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'content': content,
      'priority': priority,
    };
  }
}
