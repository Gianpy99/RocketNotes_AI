import 'package:flutter/material.dart';
import 'openai_service.dart';

/// Servizio per le funzionalità AI dell'editor di note
class NoteEditorAIService {
  static final OpenAIService _openAIService = OpenAIService();

  /// Verifica se l'API key è configurata
  static bool get isApiKeyConfigured => !OpenAIService.isApiKeyMissing();

  /// Migliora il testo fornendo suggerimenti di scrittura
  static Future<String> improveText(String text) async {
    if (!isApiKeyConfigured) {
      throw Exception('API key not configured');
    }

    if (text.trim().isEmpty) {
      throw Exception('Text cannot be empty');
    }

    final prompt = '''
Migliora il seguente testo rendendolo più chiaro, professionale e ben strutturato.
Mantieni il significato originale ma migliora la grammatica, la struttura e la leggibilità.
Se il testo è in italiano, rispondi in italiano. Se è in inglese, rispondi in inglese.

Testo originale:
$text

Testo migliorato:
''';

    return await _openAIService.generateText(prompt);
  }

  /// Genera un riassunto del testo
  static Future<String> summarizeText(String text) async {
    if (!isApiKeyConfigured) {
      throw Exception('API key not configured');
    }

    if (text.trim().isEmpty) {
      throw Exception('Text cannot be empty');
    }

    final prompt = '''
Crea un riassunto conciso ma completo del seguente testo.
Il riassunto dovrebbe catturare i punti principali e le idee chiave.
Mantieni un tono professionale e usa un linguaggio chiaro.

Testo da riassumere:
$text

Riassunto:
''';

    return await _openAIService.generateText(prompt);
  }

  /// Corregge la grammatica e gli errori ortografici
  static Future<String> correctGrammar(String text) async {
    if (!isApiKeyConfigured) {
      throw Exception('API key not configured');
    }

    if (text.trim().isEmpty) {
      throw Exception('Text cannot be empty');
    }

    final prompt = '''
Correggi la grammatica, l'ortografia e la punteggiatura del seguente testo.
Mantieni il significato originale e lo stile di scrittura.
Se il testo è in italiano, correggi secondo le regole grammaticali italiane.
Se è in inglese, correggi secondo le regole grammaticali inglesi.

Testo originale:
$text

Testo corretto:
''';

    return await _openAIService.generateText(prompt);
  }

  /// Genera suggerimenti per espandere il contenuto
  static Future<String> generateSuggestions(String text) async {
    if (!isApiKeyConfigured) {
      throw Exception('API key not configured');
    }

    if (text.trim().isEmpty) {
      throw Exception('Text cannot be empty');
    }

    final prompt = '''
Analizza il seguente testo e fornisci suggerimenti concreti per espanderlo e migliorarlo.
Suggerisci:
1. Argomenti aggiuntivi da coprire
2. Esempi o casi d'uso da aggiungere
3. Domande che il testo dovrebbe rispondere
4. Strutture o sezioni che potrebbero essere aggiunte

Testo da analizzare:
$text

Suggerimenti:
''';

    return await _openAIService.generateText(prompt);
  }

  /// Genera un titolo appropriato per il testo
  static Future<String> generateTitle(String text) async {
    if (!isApiKeyConfigured) {
      throw Exception('API key not configured');
    }

    if (text.trim().isEmpty) {
      throw Exception('Text cannot be empty');
    }

    final prompt = '''
Genera un titolo accattivante e descrittivo per il seguente testo.
Il titolo dovrebbe essere conciso (max 10 parole) ma informativo.
Se il testo è in italiano, genera un titolo in italiano.
Se è in inglese, genera un titolo in inglese.

Testo:
$text

Titolo:
''';

    final title = await _openAIService.generateText(prompt);
    return title.trim();
  }

  /// Genera tag automatici basati sul contenuto
  static Future<List<String>> generateTags(String text) async {
    if (!isApiKeyConfigured) {
      throw Exception('API key not configured');
    }

    if (text.trim().isEmpty) {
      return [];
    }

    final prompt = '''
Analizza il seguente testo e genera 3-5 tag rilevanti che descrivano il contenuto principale.
I tag dovrebbero essere parole chiave concise, separate da virgola.
Se il testo è in italiano, usa tag in italiano.
Se è in inglese, usa tag in inglese.

Testo:
$text

Tag (separati da virgola):
''';

    final tagsString = await _openAIService.generateText(prompt);
    return tagsString
        .split(',')
        .map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty)
        .toList();
  }
}

/// Enum per i tipi di funzionalità AI disponibili
enum AIFeatureType {
  improve,
  summarize,
  correctGrammar,
  generateSuggestions,
  generateTitle,
  generateTags,
}

extension AIFeatureTypeExtension on AIFeatureType {
  String get displayName {
    switch (this) {
      case AIFeatureType.improve:
        return 'Migliora Testo';
      case AIFeatureType.summarize:
        return 'Riassumi';
      case AIFeatureType.correctGrammar:
        return 'Correggi Grammatica';
      case AIFeatureType.generateSuggestions:
        return 'Suggerimenti';
      case AIFeatureType.generateTitle:
        return 'Genera Titolo';
      case AIFeatureType.generateTags:
        return 'Genera Tag';
    }
  }

  String get description {
    switch (this) {
      case AIFeatureType.improve:
        return 'Migliora la chiarezza e la struttura del testo';
      case AIFeatureType.summarize:
        return 'Crea un riassunto conciso del contenuto';
      case AIFeatureType.correctGrammar:
        return 'Correggi errori grammaticali e ortografici';
      case AIFeatureType.generateSuggestions:
        return 'Suggerisci modi per espandere il contenuto';
      case AIFeatureType.generateTitle:
        return 'Genera un titolo appropriato';
      case AIFeatureType.generateTags:
        return 'Crea tag automatici basati sul contenuto';
    }
  }

  IconData get icon {
    switch (this) {
      case AIFeatureType.improve:
        return Icons.auto_fix_high;
      case AIFeatureType.summarize:
        return Icons.summarize;
      case AIFeatureType.correctGrammar:
        return Icons.spellcheck;
      case AIFeatureType.generateSuggestions:
        return Icons.lightbulb;
      case AIFeatureType.generateTitle:
        return Icons.title;
      case AIFeatureType.generateTags:
        return Icons.tag;
    }
  }
}
