import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../models/scanned_content.dart';

class AIService {
  static AIService? _instance;
  static AIService get instance => _instance ??= AIService._();
  AIService._();

  final Dio _dio = Dio();
  
  // Configuration
  static const String openAIBaseUrl = 'https://api.openai.com/v1';
  static const String geminiBaseUrl = 'https://generativelanguage.googleapis.com/v1beta';
  
  // API Keys (these should be stored securely in production)
  String? _openAIKey;
  String? _geminiKey;
  
  // Current provider
  AIProvider _currentProvider = AIProvider.mockAI;

  /// Initialize the AI service
  Future<void> initialize({
    String? openAIKey,
    String? geminiKey,
    AIProvider provider = AIProvider.mockAI,
  }) async {
    _openAIKey = openAIKey;
    _geminiKey = geminiKey;
    _currentProvider = provider;
    
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 60);
  }

  /// Analyze scanned content with AI
  Future<AIAnalysis> analyzeContent(ScannedContent scannedContent) async {
    switch (_currentProvider) {
      case AIProvider.openAI:
        return await _analyzeWithOpenAI(scannedContent);
      case AIProvider.gemini:
        return await _analyzeWithGemini(scannedContent);
      case AIProvider.mockAI:
        return _mockAnalysis(scannedContent);
    }
  }

  /// Analyze content with OpenAI GPT-4
  Future<AIAnalysis> _analyzeWithOpenAI(ScannedContent scannedContent) async {
    if (_openAIKey == null) {
      throw Exception('OpenAI API key not configured');
    }

    try {
      final prompt = _buildAnalysisPrompt(scannedContent);
      
      final response = await _dio.post(
        '$openAIBaseUrl/chat/completions',
        options: Options(
          headers: {
            'Authorization': 'Bearer $_openAIKey',
            'Content-Type': 'application/json',
          },
        ),
        data: {
          'model': 'gpt-4-turbo-preview',
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
          'temperature': 0.7,
          'max_tokens': 1500,
        },
      );

      final content = response.data['choices'][0]['message']['content'];
      return _parseAIResponse(content);
      
    } catch (e) {
      debugPrint('OpenAI analysis error: $e');
      return _fallbackAnalysis(scannedContent);
    }
  }

  /// Analyze content with Google Gemini
  Future<AIAnalysis> _analyzeWithGemini(ScannedContent scannedContent) async {
    if (_geminiKey == null) {
      throw Exception('Gemini API key not configured');
    }

    try {
      final prompt = _buildAnalysisPrompt(scannedContent);
      
      final response = await _dio.post(
        '$geminiBaseUrl/models/gemini-pro:generateContent?key=$_geminiKey',
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

      final content = response.data['candidates'][0]['content']['parts'][0]['text'];
      return _parseAIResponse(content);
      
    } catch (e) {
      debugPrint('Gemini analysis error: $e');
      return _fallbackAnalysis(scannedContent);
    }
  }

  /// Mock AI analysis for development/testing
  AIAnalysis _mockAnalysis(ScannedContent scannedContent) {
    final text = scannedContent.rawText;
    
    // Simple analysis based on keywords
    final keyTopics = _extractKeyTopics(text);
    final suggestedTags = _generateTags(text);
    final contentType = _detectContentType(text);
    final actionItems = _extractActionItems(text);
    
    return AIAnalysis(
      summary: _generateSummary(text),
      keyTopics: keyTopics,
      suggestedTags: suggestedTags,
      suggestedTitle: _generateTitle(text),
      contentType: contentType,
      sentiment: _analyzeSentiment(text),
      actionItems: actionItems,
      insights: {
        'word_count': text.split(' ').length,
        'estimated_reading_time': '${(text.split(' ').length / 200).ceil()} min',
        'complexity_score': _calculateComplexity(text),
        'has_tables': scannedContent.tables.isNotEmpty,
        'has_diagrams': scannedContent.diagrams.isNotEmpty,
      },
    );
  }

  /// Build analysis prompt for AI
  String _buildAnalysisPrompt(ScannedContent scannedContent) {
    final buffer = StringBuffer();
    
    buffer.writeln('Please analyze the following scanned content:');
    buffer.writeln('');
    buffer.writeln('TEXT CONTENT:');
    buffer.writeln(scannedContent.rawText);
    
    if (scannedContent.tables.isNotEmpty) {
      buffer.writeln('');
      buffer.writeln('TABLES FOUND:');
      for (int i = 0; i < scannedContent.tables.length; i++) {
        final table = scannedContent.tables[i];
        buffer.writeln('Table ${i + 1}:');
        for (final row in table.rows) {
          buffer.writeln('  ${row.join(' | ')}');
        }
      }
    }
    
    if (scannedContent.diagrams.isNotEmpty) {
      buffer.writeln('');
      buffer.writeln('DIAGRAMS FOUND:');
      for (int i = 0; i < scannedContent.diagrams.length; i++) {
        final diagram = scannedContent.diagrams[i];
        buffer.writeln('Diagram ${i + 1}: ${diagram.type} - ${diagram.description}');
      }
    }
    
    return buffer.toString();
  }

  /// System prompt for AI analysis
  String _getSystemPrompt() {
    return '''
You are an AI assistant specialized in analyzing scanned notes and documents. 
Your task is to provide structured analysis in JSON format with the following fields:

{
  "summary": "Brief summary of the content (max 200 chars)",
  "keyTopics": ["topic1", "topic2", "topic3"],
  "suggestedTags": ["tag1", "tag2", "tag3"],
  "suggestedTitle": "Appropriate title for the content",
  "contentType": "notes|meeting|todo|brainstorm|technical|personal|mixed",
  "sentiment": 0.5,
  "actionItems": [
    {
      "text": "Action item description",
      "priority": "low|medium|high|urgent",
      "dueDate": null
    }
  ],
  "insights": {
    "main_theme": "Theme description",
    "key_concepts": ["concept1", "concept2"],
    "urgency_level": "low|medium|high",
    "requires_followup": true|false
  }
}

Focus on extracting actionable insights and organizing the information clearly.
''';
  }

  /// Parse AI response from JSON
  AIAnalysis _parseAIResponse(String response) {
    try {
      // Extract JSON from response (in case there's additional text)
      final jsonMatch = RegExp(r'\{.*\}', dotAll: true).firstMatch(response);
      if (jsonMatch == null) {
        throw Exception('No JSON found in response');
      }
      
      final jsonData = json.decode(jsonMatch.group(0)!);
      
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
      
    } catch (e) {
      debugPrint('Error parsing AI response: $e');
      // Return basic analysis if parsing fails
      return AIAnalysis(
        summary: 'Analysis completed',
        keyTopics: [],
        suggestedTags: [],
        suggestedTitle: 'Scanned Note',
        contentType: ContentType.notes,
        sentiment: 0.0,
        actionItems: [],
        insights: {'parse_error': e.toString()},
      );
    }
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
}

enum AIProvider {
  openAI,
  gemini,
  mockAI,
}
