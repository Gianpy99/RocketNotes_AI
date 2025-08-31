/// Servizio per la gestione e riconoscimento dei template Rocketbook Fusion Plus
class RocketbookTemplateService {
  
  /// Definizione di tutti i template disponibili nel Rocketbook Fusion Plus
  static const Map<String, RocketbookTemplate> _templates = {
    'lined': RocketbookTemplate(
      id: 'lined',
      name: 'Pagina Rigata',
      description: 'Pagina con righe orizzontali per scrittura libera',
      quantity: 18,
      category: 'writing',
      chatGptPrompt: 'Questa è una pagina rigata standard del Rocketbook. Le righe orizzontali sono utilizzate per scrittura a mano libera, note generali, appunti di lezioni, o qualsiasi testo lineare.',
      analysisHints: [
        'Cerca testo scritto seguendo le righe orizzontali',
        'Identifica paragrafi e sezioni di testo',
        'Riconosci liste o elenchi puntati',
        'Analizza la struttura del contenuto scritto'
      ],
    ),
    'blank': RocketbookTemplate(
      id: 'blank',
      name: 'Pagina Bianca',
      description: 'Pagina completamente vuota per massima libertà creativa',
      quantity: 4,
      category: 'creative',
      chatGptPrompt: 'Questa è una pagina bianca del Rocketbook, utilizzata per disegni liberi, schizzi, diagrammi creativi, mind maps, o qualsiasi contenuto che non segue una struttura predefinita.',
      analysisHints: [
        'Cerca disegni, schizzi o diagrammi',
        'Identifica elementi grafici creativi',
        'Riconosci mind maps o mappe concettuali',
        'Analizza layout non strutturati'
      ],
    ),
    'dot-grid': RocketbookTemplate(
      id: 'dot-grid',
      name: 'Griglia a Punti',
      description: 'Griglia di punti per disegno tecnico e layout flessibili',
      quantity: 4,
      category: 'technical',
      chatGptPrompt: 'Questa è una pagina con griglia a punti del Rocketbook. I punti permettono di creare diagrammi precisi, grafici, layout strutturati, bullet journaling, o disegni tecnici con allineamento perfetto.',
      analysisHints: [
        'Cerca diagrammi o grafici allineati ai punti',
        'Identifica bullet points e strutture organizzate',
        'Riconosci layout geometrici o tecnici',
        'Analizza contenuti strutturati con precisione'
      ],
    ),
    'graph': RocketbookTemplate(
      id: 'graph',
      name: 'Griglia Quadrettata',
      description: 'Griglia quadrettata per grafici, diagrammi e calcoli matematici',
      quantity: 4,
      category: 'mathematical',
      chatGptPrompt: 'Questa è una pagina con griglia quadrettata del Rocketbook. Utilizzata per grafici matematici, diagrammi cartesiani, calcoli, disegni tecnici precisi, o qualsiasi contenuto che richiede misurazione e precisione.',
      analysisHints: [
        'Cerca grafici matematici o cartesiani',
        'Identifica calcoli o formule matematiche',
        'Riconosci diagrammi tecnici precisi',
        'Analizza contenuti scientifici o ingegneristici'
      ],
    ),
    'meeting-notes': RocketbookTemplate(
      id: 'meeting-notes',
      name: 'Note di Riunione',
      description: 'Template strutturato per prendere appunti durante le riunioni',
      quantity: 8,
      category: 'business',
      chatGptPrompt: 'Questa è una pagina per note di riunione del Rocketbook. Include sezioni per data, partecipanti, argomenti, azioni da intraprendere e follow-up. Struttura ottimizzata per meeting professionali e riunioni organizzate.',
      analysisHints: [
        'Cerca informazioni su data e partecipanti',
        'Identifica argomenti discussi',
        'Riconosci action items e compiti assegnati',
        'Analizza decisioni prese e follow-up'
      ],
    ),
    'project-management': RocketbookTemplate(
      id: 'project-management',
      name: 'Gestione Progetti',
      description: 'Template per pianificazione e tracking dei progetti',
      quantity: 4,
      category: 'planning',
      chatGptPrompt: 'Questa è una pagina di gestione progetti del Rocketbook. Include sezioni per obiettivi, timeline, milestone, risorse, team members e stato del progetto. Ottimizzata per project management e pianificazione strategica.',
      analysisHints: [
        'Cerca obiettivi e milestone del progetto',
        'Identifica timeline e scadenze',
        'Riconosci assegnazioni di risorse',
        'Analizza stato di avanzamento e metriche'
      ],
    ),
    'monthly-dashboard': RocketbookTemplate(
      id: 'monthly-dashboard',
      name: 'Dashboard Mensile',
      description: 'Vista d\'insieme mensile con obiettivi e metriche',
      quantity: 1,
      category: 'planning',
      chatGptPrompt: 'Questa è la pagina dashboard mensile del Rocketbook. Fornisce una vista d\'insieme del mese con obiettivi, habit tracker, priorità, bilancio del tempo e metriche chiave di performance.',
      analysisHints: [
        'Cerca obiettivi mensili e priorità',
        'Identifica habit tracking e routine',
        'Riconosci metriche e KPI',
        'Analizza bilancio tempo e produttività'
      ],
    ),
    'weekly': RocketbookTemplate(
      id: 'weekly',
      name: 'Pianificazione Settimanale',
      description: 'Layout settimanale con giorni della settimana strutturati',
      quantity: 12, // 6 spread da 2 pagine
      category: 'planning',
      chatGptPrompt: 'Questa è una pagina di pianificazione settimanale del Rocketbook. Include i 7 giorni della settimana con spazi per appuntamenti, compiti, priorità e note. Layout ottimizzato per organizzazione temporale.',
      analysisHints: [
        'Cerca pianificazioni giornaliere',
        'Identifica appuntamenti e scadenze',
        'Riconosci priorità e compiti',
        'Analizza organizzazione del tempo'
      ],
    ),
    'monthly': RocketbookTemplate(
      id: 'monthly',
      name: 'Vista Mensile',
      description: 'Calendario mensile completo per pianificazione a lungo termine',
      quantity: 2, // 1 spread da 2 pagine
      category: 'planning',
      chatGptPrompt: 'Questa è una pagina vista mensile del Rocketbook. Mostra il calendario completo del mese con spazi per eventi, scadenze, appuntamenti e note importanti. Ideale per pianificazione a lungo termine.',
      analysisHints: [
        'Cerca date ed eventi del calendario',
        'Identifica scadenze mensili',
        'Riconosci pattern ricorrenti',
        'Analizza pianificazione a lungo termine'
      ],
    ),
    'list': RocketbookTemplate(
      id: 'list',
      name: 'Pagina Liste',
      description: 'Template ottimizzato per todo lists e elenchi strutturati',
      quantity: 2,
      category: 'organization',
      chatGptPrompt: 'Questa è una pagina liste del Rocketbook. Strutturata per todo lists, checklist, elenchi di acquisti, priorità, o qualsiasi contenuto organizzato in forma di lista con checkbox e categorizzazione.',
      analysisHints: [
        'Cerca todo lists e checklist',
        'Identifica priorità e categorizzazioni',
        'Riconosci stati completamento (check/uncheck)',
        'Analizza organizzazione per importanza'
      ],
    ),
    'custom-table': RocketbookTemplate(
      id: 'custom-table',
      name: 'Tabella Personalizzata',
      description: 'Template con struttura tabellare personalizzabile',
      quantity: 1,
      category: 'data',
      chatGptPrompt: 'Questa è una pagina tabella personalizzata del Rocketbook. Include una struttura a griglia flessibile per organizzare dati, comparazioni, tracking abitudini, budget, o qualsiasi informazione che benefici di organizzazione tabellare.',
      analysisHints: [
        'Cerca dati organizzati in colonne/righe',
        'Identifica intestazioni e categorie',
        'Riconosci pattern numerici o metriche',
        'Analizza relazioni tra dati'
      ],
    ),
  };

  /// Ottiene tutti i template disponibili
  static List<RocketbookTemplate> getAllTemplates() {
    return _templates.values.toList();
  }

  /// Ottiene template per categoria
  static List<RocketbookTemplate> getTemplatesByCategory(String category) {
    return _templates.values
        .where((template) => template.category == category)
        .toList();
  }

  /// Ottiene un template specifico per ID
  static RocketbookTemplate? getTemplate(String id) {
    return _templates[id];
  }

  /// Determina il template più probabile basato su caratteristiche visive
  static RocketbookTemplate detectTemplate({
    bool hasLines = false,
    bool hasGrid = false,
    bool hasDots = false,
    bool hasCalendarStructure = false,
    bool hasTableStructure = false,
    bool hasSections = false,
    bool isBlank = false,
    String? textContent,
  }) {
    
    // Analisi basata su caratteristiche strutturali
    if (isBlank) return _templates['blank']!;
    if (hasTableStructure) return _templates['custom-table']!;
    if (hasCalendarStructure) {
      if (textContent?.contains(RegExp(r'\b(lunedì|martedì|mercoledì|giovedì|venerdì|sabato|domenica|mon|tue|wed|thu|fri|sat|sun)\b', caseSensitive: false)) == true) {
        return _templates['weekly']!;
      }
      return _templates['monthly']!;
    }
    if (hasGrid) return _templates['graph']!;
    if (hasDots) return _templates['dot-grid']!;
    if (hasLines) return _templates['lined']!;

    // Analisi basata su contenuto testuale
    if (textContent != null) {
      final lowerContent = textContent.toLowerCase();
      
      // Keywords per meeting notes
      if (lowerContent.contains(RegExp(r'\b(meeting|riunione|partecipanti|agenda|action|follow.?up)\b'))) {
        return _templates['meeting-notes']!;
      }
      
      // Keywords per project management
      if (lowerContent.contains(RegExp(r'\b(progetto|milestone|deadline|obiettivo|timeline|team)\b'))) {
        return _templates['project-management']!;
      }
      
      // Keywords per liste
      if (lowerContent.contains(RegExp(r'\b(todo|checklist|elenco|lista)\b')) || 
          lowerContent.contains(RegExp(r'^\s*[-•\*]\s', multiLine: true))) {
        return _templates['list']!;
      }
      
      // Keywords per dashboard
      if (lowerContent.contains(RegExp(r'\b(obiettivi mensili|kpi|metriche|dashboard)\b'))) {
        return _templates['monthly-dashboard']!;
      }
    }

    // Default: pagina rigata per contenuto testuale generico
    return _templates['lined']!;
  }

  /// Genera prompt ottimizzato per ChatGPT basato sul template riconosciuto
  static String generateChatGptPrompt(RocketbookTemplate template, String? additionalContext) {
    final basePrompt = template.chatGptPrompt;
    final hints = template.analysisHints.join('. ');
    
    String prompt = '''
CONTESTO ROCKETBOOK FUSION PLUS:
${template.name}: $basePrompt

ANALISI RICHIESTA:
$hints

${additionalContext != null ? 'CONTESTO AGGIUNTIVO:\n$additionalContext\n' : ''}

Per favore analizza il contenuto di questa pagina tenendo conto della struttura e dello scopo specifico del template Rocketbook identificato. Fornisci insights pertinenti al tipo di pagina e suggerimenti per ottimizzare l'uso di questo formato.
''';

    return prompt;
  }

  /// Statistiche sui template per debugging
  static Map<String, dynamic> getTemplateStats() {
    final stats = <String, dynamic>{};
    final categories = <String, int>{};
    int totalPages = 0;

    for (final template in _templates.values) {
      categories[template.category] = (categories[template.category] ?? 0) + template.quantity;
      totalPages += template.quantity;
    }

    stats['totalTemplates'] = _templates.length;
    stats['totalPages'] = totalPages;
    stats['categoriesBreakdown'] = categories;
    stats['templates'] = _templates.keys.toList();

    return stats;
  }
}

/// Classe che rappresenta un template del Rocketbook
class RocketbookTemplate {
  final String id;
  final String name;
  final String description;
  final int quantity;
  final String category;
  final String chatGptPrompt;
  final List<String> analysisHints;

  const RocketbookTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.quantity,
    required this.category,
    required this.chatGptPrompt,
    required this.analysisHints,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'quantity': quantity,
      'category': category,
      'chatGptPrompt': chatGptPrompt,
      'analysisHints': analysisHints,
    };
  }

  @override
  String toString() => 'RocketbookTemplate(id: $id, name: $name, category: $category)';
}
