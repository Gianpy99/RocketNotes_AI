// ==========================================
// lib/data/services/topic_ai_service.dart
// ==========================================

import 'package:flutter/foundation.dart';
import '../models/note.dart';
import '../models/topic.dart';
import 'ai_service.dart';

/// Service for AI-powered topic analysis and summarization
class TopicAIService {
  final AIService _aiService = AIService();

  /// Generate a comprehensive summary of all notes in a topic
  Future<TopicSummary> generateTopicSummary({
    required Topic topic,
    required List<NoteModel> notes,
  }) async {
    try {
      debugPrint('[TopicAI] Generating summary for topic: ${topic.name} with ${notes.length} notes');

      if (notes.isEmpty) {
        return TopicSummary(
          topicId: topic.id,
          topicName: topic.name,
          summary: 'No notes in this topic yet.',
          keyPoints: [],
          noteCount: 0,
          generatedAt: DateTime.now(),
        );
      }

      // Prepare context from all notes
      final notesContext = _prepareNotesContext(notes);

      // Generate AI summary
      final prompt = _buildSummaryPrompt(topic, notes, notesContext);
      final aiResponse = await _aiService.chat(prompt);

      // Parse AI response
      final summary = _parseAISummary(aiResponse);

      return TopicSummary(
        topicId: topic.id,
        topicName: topic.name,
        summary: summary['overview'] ?? aiResponse,
        keyPoints: summary['keyPoints'] ?? [],
        actionItems: summary['actionItems'],
        insights: summary['insights'],
        noteCount: notes.length,
        generatedAt: DateTime.now(),
      );
    } catch (e) {
      debugPrint('[TopicAI] Error generating summary: $e');
      return TopicSummary(
        topicId: topic.id,
        topicName: topic.name,
        summary: 'Error generating summary: $e',
        keyPoints: [],
        noteCount: notes.length,
        generatedAt: DateTime.now(),
      );
    }
  }

  /// Generate insights about topic trends over time
  Future<String> generateTopicInsights({
    required Topic topic,
    required List<NoteModel> notes,
  }) async {
    try {
      if (notes.isEmpty) return 'No notes to analyze yet.';

      final prompt = '''
Analyze these notes from the topic "${topic.name}" and provide insights about:
1. Main themes and patterns
2. Evolution over time
3. Areas requiring attention
4. Recommendations

Notes:
${notes.map((n) => '- ${n.title}: ${n.content.substring(0, n.content.length > 200 ? 200 : n.content.length)}...').join('\n')}

Provide a concise analysis (max 300 words).
''';

      return await _aiService.chat(prompt);
    } catch (e) {
      debugPrint('[TopicAI] Error generating insights: $e');
      return 'Error generating insights: $e';
    }
  }

  /// Compare multiple topics
  Future<String> compareTopics({
    required List<Topic> topics,
    required Map<String, List<NoteModel>> topicNotes,
  }) async {
    try {
      final comparisons = topics.map((topic) {
        final notes = topicNotes[topic.id] ?? [];
        return '${topic.name}: ${notes.length} notes';
      }).join(', ');

      final prompt = '''
Compare these topics and their activities:
$comparisons

Provide insights about:
1. Which topics have most activity
2. Relationships between topics
3. Suggestions for organization

Keep it brief (max 200 words).
''';

      return await _aiService.chat(prompt);
    } catch (e) {
      return 'Error comparing topics: $e';
    }
  }

  // Private helper methods

  String _prepareNotesContext(List<NoteModel> notes) {
    return notes.map((note) {
      final dateStr = '${note.createdAt.year}-${note.createdAt.month}-${note.createdAt.day}';
      return '[$dateStr] ${note.title}\n${note.content}';
    }).join('\n\n---\n\n');
  }

  String _buildSummaryPrompt(Topic topic, List<NoteModel> notes, String context) {
    return '''
You are analyzing a collection of notes for the topic: "${topic.name}"
${topic.description != null ? 'Description: ${topic.description}' : ''}

Total notes: ${notes.length}
Date range: ${notes.first.createdAt} to ${notes.last.createdAt}

Please provide:
1. OVERVIEW: A comprehensive summary (2-3 sentences)
2. KEY POINTS: List the 5 most important points (bullet points)
3. ACTION ITEMS: Extract any action items or tasks mentioned
4. INSIGHTS: Notable patterns or insights

Notes content:
$context

Format your response as:
OVERVIEW:
[your overview here]

KEY POINTS:
- [point 1]
- [point 2]
...

ACTION ITEMS:
- [action 1]
...

INSIGHTS:
[your insights here]
''';
  }

  Map<String, dynamic> _parseAISummary(String response) {
    try {
      final sections = <String, dynamic>{};
      
      // Extract overview
      final overviewMatch = RegExp(r'OVERVIEW:\s*(.+?)(?=KEY POINTS:|ACTION ITEMS:|INSIGHTS:|$)', dotAll: true)
          .firstMatch(response);
      if (overviewMatch != null) {
        sections['overview'] = overviewMatch.group(1)?.trim();
      }

      // Extract key points
      final keyPointsMatch = RegExp(r'KEY POINTS:\s*(.+?)(?=ACTION ITEMS:|INSIGHTS:|$)', dotAll: true)
          .firstMatch(response);
      if (keyPointsMatch != null) {
        final pointsText = keyPointsMatch.group(1)?.trim() ?? '';
        sections['keyPoints'] = pointsText
            .split('\n')
            .where((line) => line.trim().startsWith('-'))
            .map((line) => line.trim().substring(1).trim())
            .toList();
      }

      // Extract action items
      final actionMatch = RegExp(r'ACTION ITEMS:\s*(.+?)(?=INSIGHTS:|$)', dotAll: true)
          .firstMatch(response);
      if (actionMatch != null) {
        final actionsText = actionMatch.group(1)?.trim() ?? '';
        if (actionsText.isNotEmpty) {
          sections['actionItems'] = actionsText
              .split('\n')
              .where((line) => line.trim().startsWith('-'))
              .map((line) => line.trim().substring(1).trim())
              .toList();
        }
      }

      // Extract insights
      final insightsMatch = RegExp(r'INSIGHTS:\s*(.+)$', dotAll: true)
          .firstMatch(response);
      if (insightsMatch != null) {
        sections['insights'] = insightsMatch.group(1)?.trim();
      }

      return sections;
    } catch (e) {
      debugPrint('[TopicAI] Error parsing AI response: $e');
      return {'overview': response};
    }
  }
}

/// Model for topic summary results
class TopicSummary {
  final String topicId;
  final String topicName;
  final String summary;
  final List<String> keyPoints;
  final List<String>? actionItems;
  final String? insights;
  final int noteCount;
  final DateTime generatedAt;

  TopicSummary({
    required this.topicId,
    required this.topicName,
    required this.summary,
    required this.keyPoints,
    this.actionItems,
    this.insights,
    required this.noteCount,
    required this.generatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'topicId': topicId,
      'topicName': topicName,
      'summary': summary,
      'keyPoints': keyPoints,
      'actionItems': actionItems,
      'insights': insights,
      'noteCount': noteCount,
      'generatedAt': generatedAt.toIso8601String(),
    };
  }

  factory TopicSummary.fromJson(Map<String, dynamic> json) {
    return TopicSummary(
      topicId: json['topicId'],
      topicName: json['topicName'],
      summary: json['summary'],
      keyPoints: List<String>.from(json['keyPoints'] ?? []),
      actionItems: json['actionItems'] != null 
          ? List<String>.from(json['actionItems'])
          : null,
      insights: json['insights'],
      noteCount: json['noteCount'],
      generatedAt: DateTime.parse(json['generatedAt']),
    );
  }
}
