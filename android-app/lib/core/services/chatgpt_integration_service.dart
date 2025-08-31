import '../services/rocketbook_template_service.dart';
import '../services/image_template_recognition.dart';
import '../services/openai_service.dart';

/// Servizio per integrazione ChatGPT con riconoscimento template
class ChatGptIntegrationService {
  
  /// Genera prompt ottimizzato per ChatGPT basato su template e contenuto
  static Future<ChatGptRequest> generateOptimizedRequest({
    required String imagePath,
    String? userPrompt,
    ChatGptMode mode = ChatGptMode.analyze,
  }) async {
    
    // Riconosci il template dalla immagine
    final detection = await ImageTemplateRecognition.analyzeImage(imagePath);
    
    // Costruisci il prompt base dal template
    final templatePrompt = detection.chatGptPrompt;
    
    // Personalizza il prompt basato sulla modalità richiesta
    final modePrompt = _getModePrompt(mode, detection.template);
    
    // Combina tutto in un prompt completo
    final fullPrompt = _buildFullPrompt(
      templatePrompt: templatePrompt,
      modePrompt: modePrompt,
      userPrompt: userPrompt,
      detection: detection,
    );

    return ChatGptRequest(
      prompt: fullPrompt,
      template: detection.template,
      mode: mode,
      confidence: detection.confidence,
      metadata: {
        'imagePath': imagePath,
        'detectedFeatures': detection.features.detectedFeatures,
        'templateCategory': detection.template.category,
        'generatedAt': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Invia prompt direttamente a ChatGPT via API OpenAI
  static Future<ChatGptResponse> sendToChatGPT({
    required String imagePath,
    String? userPrompt,
    ChatGptMode mode = ChatGptMode.analyze,
  }) async {
    try {
      // Genera il prompt ottimizzato
      final request = await generateOptimizedRequest(
        imagePath: imagePath,
        userPrompt: userPrompt,
        mode: mode,
      );
      
      // Verifica se API key è configurata
      if (OpenAIService.isApiKeyMissing()) {
        return ChatGptResponse(
          content: 'Errore: API Key OpenAI non configurata. Controlla openai_config.dart',
          request: request,
          processedAt: DateTime.now(),
          suggestions: ['Configura API Key OpenAI'],
          actionItems: ['Aggiorna openai_config.dart con la tua API key'],
          summary: 'Configurazione API richiesta',
        );
      }
      
      // Invia a OpenAI
      final openAI = OpenAIService();
      
      // Usa l'API per generare una risposta testuale al prompt
      final responseText = await openAI.generateText(request.prompt);
      
      // Analizza la risposta per estrarre suggestions e action items
      final suggestions = _extractSuggestions(responseText);
      final actionItems = _extractActionItems(responseText);
      final summary = _extractSummary(responseText);
      
      return ChatGptResponse(
        content: responseText,
        request: request,
        processedAt: DateTime.now(),
        suggestions: suggestions,
        actionItems: actionItems,
        summary: summary,
      );
      
    } catch (e) {
      // Crea una richiesta dummy per l'errore
      final dummyRequest = ChatGptRequest(
        prompt: userPrompt ?? 'Errore nella generazione prompt',
        template: RocketbookTemplateService.getTemplate('blank') ?? RocketbookTemplateService.getAllTemplates().first,
        mode: mode,
        confidence: 0.0,
        metadata: {},
      );
      
      return ChatGptResponse(
        content: 'Errore durante l\'invio a ChatGPT: $e',
        request: dummyRequest,
        processedAt: DateTime.now(),
        suggestions: ['Verifica connessione internet', 'Controlla API key'],
        actionItems: ['Riprova più tardi'],
        summary: 'Errore di comunicazione',
      );
    }
  }

  /// Estrae suggerimenti dalla risposta
  static List<String> _extractSuggestions(String response) {
    // Logica semplice per estrarre suggerimenti
    final suggestions = <String>[];
    final lines = response.split('\n');
    
    for (var line in lines) {
      if (line.toLowerCase().contains('suggerimento') || 
          line.toLowerCase().contains('consiglio') ||
          line.toLowerCase().contains('raccomandazione')) {
        suggestions.add(line.trim());
      }
    }
    
    return suggestions.isEmpty ? ['Contenuto analizzato con successo'] : suggestions;
  }

  /// Estrae action items dalla risposta  
  static List<String> _extractActionItems(String response) {
    final actionItems = <String>[];
    final lines = response.split('\n');
    
    for (var line in lines) {
      if (line.toLowerCase().contains('azione') || 
          line.toLowerCase().contains('compito') ||
          line.toLowerCase().contains('todo') ||
          line.startsWith('- ') ||
          line.startsWith('• ')) {
        actionItems.add(line.trim());
      }
    }
    
    return actionItems.isEmpty ? ['Rivedi il contenuto generato'] : actionItems;
  }

  /// Estrae riassunto dalla risposta
  static String _extractSummary(String response) {
    final lines = response.split('\n');
    
    // Prendi le prime 2-3 frasi come riassunto
    final summary = lines.take(3).join(' ').trim();
    return summary.isEmpty ? 'Contenuto processato da ChatGPT' : summary;
  }

  /// Ottiene prompt specifico per modalità
  static String _getModePrompt(ChatGptMode mode, RocketbookTemplate template) {
    switch (mode) {
      case ChatGptMode.analyze:
        return '''
MODALITÀ: ANALISI COMPLETA
Analizza il contenuto di questa pagina e fornisci:
1. 📋 Riassunto del contenuto principale
2. 🎯 Punti chiave identificati
3. 📊 Struttura e organizzazione
4. 💡 Insights e suggerimenti per migliorare l'utilizzo del template ${template.name}
''';
      
      case ChatGptMode.summarize:
        return '''
MODALITÀ: RIASSUNTO STRUTTURATO
Crea un riassunto conciso e ben strutturato che:
1. 📖 Catturi l'essenza del contenuto
2. 🏷️ Evidenzi i concetti principali
3. 📝 Mantenga la struttura logica originale
4. ⚡ Sia facilmente consultabile
''';
      
      case ChatGptMode.actionItems:
        return '''
MODALITÀ: ESTRAZIONE ACTION ITEMS
Identifica e organizza:
1. ✅ Compiti da svolgere
2. 📅 Scadenze e timeline
3. 👥 Responsabilità e assegnazioni
4. 🔄 Follow-up necessari
5. ⚠️ Priorità e urgenze
''';
      
      case ChatGptMode.enhance:
        return '''
MODALITÀ: MIGLIORAMENTO CONTENUTO
Suggerisci miglioramenti per:
1. 📈 Organizzazione più efficace
2. 🎨 Layout e struttura visiva
3. 📚 Aggiunta di informazioni utili
4. 🔗 Collegamenti tra concetti
5. 💡 Ottimizzazione per il template ${template.name}
''';
      
      case ChatGptMode.convert:
        return '''
MODALITÀ: CONVERSIONE FORMATO
Converti il contenuto in:
1. 📄 Formato digitale strutturato
2. 📊 Tabelle o liste organizzate
3. 🗂️ Categorizzazione logica
4. 🔄 Formato adatto per altri template Rocketbook
''';
      
      case ChatGptMode.insights:
        return '''
MODALITÀ: INSIGHTS AVANZATI
Fornisci analisi approfondita:
1. 🧠 Pattern e trend identificati
2. 🎯 Obiettivi sottintesi
3. 🔍 Aree di miglioramento
4. 💼 Applicazioni pratiche
5. 🚀 Raccomandazioni strategiche
''';
    }
  }

  /// Costruisce il prompt completo
  static String _buildFullPrompt({
    required String templatePrompt,
    required String modePrompt,
    String? userPrompt,
    required TemplateDetectionResult detection,
  }) {
    
    final confidence = (detection.confidence * 100).toStringAsFixed(1);
    final features = detection.features.detectedFeatures.join(', ');
    
    return '''
🚀 ROCKETBOOK FUSION PLUS - ANALISI INTELLIGENTE

${templatePrompt}

${modePrompt}

📊 INFORMAZIONI RILEVAMENTO:
• Template: ${detection.template.name}
• Categoria: ${detection.template.category}
• Confidenza: ${confidence}%
• Caratteristiche: $features

${userPrompt != null ? '''
👤 RICHIESTA UTENTE:
$userPrompt
''' : ''}

🎯 ISTRUZIONI FINALI:
• Mantieni il focus sul tipo di template identificato
• Usa emoji per rendere l'output più leggibile
• Fornisci consigli pratici e azionabili
• Se la confidenza è bassa (<70%), menziona possibili alternative
• Adatta la risposta al contesto italiano/europeo per date e formati

IMPORTANTE: Questo contenuto proviene da un Rocketbook Fusion Plus, quindi considera la natura riutilizzabile e digitale del supporto nelle tue raccomandazioni.
''';
  }

  /// Processa la risposta di ChatGPT e la struttura
  static ChatGptResponse processResponse(String rawResponse, ChatGptRequest request) {
    return ChatGptResponse(
      content: rawResponse,
      request: request,
      processedAt: DateTime.now(),
      suggestions: _extractSuggestions(rawResponse),
      actionItems: _extractActionItems(rawResponse),
      summary: _extractSummary(rawResponse),
    );
  }

  /// Estrae suggerimenti dalla risposta
  static List<String> _extractSuggestions(String response) {
    final suggestions = <String>[];
    final lines = response.split('\n');
    
    for (final line in lines) {
      if (line.contains('💡') || line.contains('suggerimento') || line.contains('consiglio')) {
        suggestions.add(line.trim());
      }
    }
    
    return suggestions;
  }

  /// Estrae action items dalla risposta
  static List<String> _extractActionItems(String response) {
    final actionItems = <String>[];
    final lines = response.split('\n');
    
    for (final line in lines) {
      if (line.contains('✅') || line.contains('🔄') || line.contains('action') || line.contains('da fare')) {
        actionItems.add(line.trim());
      }
    }
    
    return actionItems;
  }

  /// Estrae riassunto dalla risposta
  static String _extractSummary(String response) {
    final lines = response.split('\n');
    final summaryLines = <String>[];
    bool inSummary = false;
    
    for (final line in lines) {
      if (line.contains('📋') || line.contains('riassunto') || line.contains('summary')) {
        inSummary = true;
        continue;
      }
      if (inSummary && line.trim().isNotEmpty) {
        if (line.startsWith('##') || line.startsWith('🎯')) {
          break;
        }
        summaryLines.add(line.trim());
      }
    }
    
    return summaryLines.isNotEmpty ? summaryLines.join(' ') : 'Nessun riassunto disponibile';
  }

  /// Ottiene esempi di prompt per ogni template
  static Map<String, List<String>> getTemplateExamples() {
    return {
      'meeting-notes': [
        'Analizza questa riunione e crea un follow-up strutturato',
        'Identifica le decisioni prese e le azioni assegnate',
        'Riassumi i punti chiave per chi non ha partecipato',
      ],
      'project-management': [
        'Valuta lo stato del progetto e identifica i rischi',
        'Crea una timeline ottimizzata basata sui milestone',
        'Suggerisci miglioramenti nella gestione delle risorse',
      ],
      'weekly': [
        'Ottimizza la mia pianificazione settimanale',
        'Identifica sovrapposizioni e conflitti nel planning',
        'Suggerisci un miglior bilanciamento work-life',
      ],
      'lined': [
        'Trasforma questi appunti in una struttura più organizzata',
        'Identifica i concetti chiave e crea una mappa mentale',
        'Riassumi e categorizza il contenuto',
      ],
      'dot-grid': [
        'Analizza questo diagramma e suggerisci miglioramenti',
        'Converte questo schema in un formato digitale',
        'Identifica relazioni e pattern nel layout',
      ],
    };
  }
}

/// Modalità di analisi ChatGPT
enum ChatGptMode {
  analyze,      // Analisi completa
  summarize,    // Riassunto
  actionItems,  // Estrazione compiti
  enhance,      // Miglioramento
  convert,      // Conversione formato
  insights,     // Insights avanzati
}

/// Richiesta strutturata per ChatGPT
class ChatGptRequest {
  final String prompt;
  final RocketbookTemplate template;
  final ChatGptMode mode;
  final double confidence;
  final Map<String, dynamic> metadata;

  ChatGptRequest({
    required this.prompt,
    required this.template,
    required this.mode,
    required this.confidence,
    required this.metadata,
  });

  Map<String, dynamic> toJson() {
    return {
      'prompt': prompt,
      'template': template.toJson(),
      'mode': mode.toString(),
      'confidence': confidence,
      'metadata': metadata,
    };
  }
}

/// Risposta processata da ChatGPT
class ChatGptResponse {
  final String content;
  final ChatGptRequest request;
  final DateTime processedAt;
  final List<String> suggestions;
  final List<String> actionItems;
  final String summary;

  ChatGptResponse({
    required this.content,
    required this.request,
    required this.processedAt,
    required this.suggestions,
    required this.actionItems,
    required this.summary,
  });

  Map<String, dynamic> toJson() {
    return {
      'content': content,
      'request': request.toJson(),
      'processedAt': processedAt.toIso8601String(),
      'suggestions': suggestions,
      'actionItems': actionItems,
      'summary': summary,
    };
  }
}
