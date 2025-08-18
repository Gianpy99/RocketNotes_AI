// ==========================================
// lib/data/services/ai_service.dart
// ==========================================
import 'dart:convert';
import 'dart:math';
import '../models/note_model.dart';

// Mock AI service for demonstration
// In a real app, this would integrate with OpenAI, Claude, or other AI APIs
class AiService {
  static const int maxSummaryLength = 200;
  static const int maxTagSuggestions = 5;

  // Generate AI summary for note
  Future<String?> generateSummary(String content) async {
    try {
      if (content.trim().isEmpty) return null;
      
      // Mock AI summary generation
      await Future.delayed(const Duration(seconds: 1)); // Simulate API call
      
      // Simple extractive summary (first few sentences)
      final sentences = content.split(RegExp(r'[.!?]+'));
      if (sentences.isEmpty) return null;
      
      String summary = sentences.first.trim();
      if (summary.length > maxSummaryLength) {
        summary = '${summary.substring(0, maxSummaryLength - 3)}...';
      }
      
      return summary.isEmpty ? null : summary;
    } catch (e) {
      print('Error generating AI summary: $e');
      return null;
    }
  }

  // Suggest tags based on content
  Future<List<String>> suggestTags(String content) async {
    try {
      if (content.trim().isEmpty) return [];
      
      // Mock tag suggestion
      await Future.delayed(const Duration(milliseconds: 500));
      
      final suggestions = <String>[];
      final words = content.toLowerCase().split(RegExp(r'\W+'));
      final wordFreq = <String, int>{};
      
      // Count word frequency
      for (final word in words) {
        if (word.length > 3 && !_isStopWord(word)) {
          wordFreq[word] = (wordFreq[word] ?? 0) + 1;
        }
      }
      
      // Get top words as tag suggestions
      final sortedWords = wordFreq.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      
      for (final entry in sortedWords.take(maxTagSuggestions)) {
        suggestions.add(entry.key);
      }
      
      return suggestions;
    } catch (e) {
      print('Error suggesting tags: $e');
      return [];
    }
  }

  // Analyze note sentiment
  Future<NoteSentiment> analyzeSentiment(String content) async {
    try {
      if (content.trim().isEmpty) {
        return NoteSentiment.neutral;
      }
      
      // Mock sentiment analysis
      await Future.delayed(const Duration(milliseconds: 300));
      
      final positiveWords = ['good', 'great', 'excellent', 'happy', 'success', 'awesome', 'fantastic'];
      final negativeWords = ['bad', 'terrible', 'awful', 'sad', 'failure', 'horrible', 'disaster'];
      
      final words = content.toLowerCase().split(RegExp(r'\W+'));
      int positiveCount = 0;
      int negativeCount = 0;
      
      for (final word in words) {
        if (positiveWords.contains(word)) positiveCount++;
        if (negativeWords.contains(word)) negativeCount++;
      }
      
      if (positiveCount > negativeCount) {
        return NoteSentiment.positive;
      } else if (negativeCount > positiveCount) {
        return NoteSentiment.negative;
      } else {
        return NoteSentiment.neutral;
      }
    } catch (e) {
      print('Error analyzing sentiment: $e');
      return NoteSentiment.neutral;
    }
  }

  // Extract action items from note
  Future<List<String>> extractActionItems(String content) async {
    try {
      if (content.trim().isEmpty) return [];
      
      // Mock action item extraction
      await Future.delayed(const Duration(milliseconds: 400));
      
      final actionItems = <String>[];
      final lines = content.split('\n');
      
      for (final line in lines) {
        final trimmedLine = line.trim();
        if (trimmedLine.startsWith('- [ ]') || 
            trimmedLine.startsWith('* [ ]') ||
            trimmedLine.toLowerCase().contains('todo') ||
            trimmedLine.toLowerCase().contains('action') ||
            trimmedLine.toLowerCase().contains('task')) {
          actionItems.add(trimmedLine);
        }
      }
      
      return actionItems;
    } catch (e) {
      print('Error extracting action items: $e');
      return [];
    }
  }

  // Suggest related notes
  Future<List<String>> suggestRelatedNotes(NoteModel note, List<NoteModel> allNotes) async {
    try {
      // Mock related notes suggestion
      await Future.delayed(const Duration(milliseconds: 600));
      
      final relatedNoteIds = <String>[];
      final noteWords = note.content.toLowerCase().split(RegExp(r'\W+'));
      final noteWordSet = noteWords.where((w) => w.length > 3 && !_isStopWord(w)).toSet();
      
      for (final otherNote in allNotes) {
        if (otherNote.id == note.id) continue;
        
        final otherWords = otherNote.content.toLowerCase().split(RegExp(r'\W+'));
        final otherWordSet = otherWords.where((w) => w.length > 3 && !_isStopWord(w)).toSet();
        
        final intersection = noteWordSet.intersection(otherWordSet);
        if (intersection.length > 2) {
          relatedNoteIds.add(otherNote.id);
        }
      }
      
      return relatedNoteIds.take(5).toList();
    } catch (e) {
      print('Error suggesting related notes: $e');
      return [];
    }
  }

  // Check if word is a stop word
  bool _isStopWord(String word) {
    const stopWords = {
      'the', 'is', 'at', 'which', 'on', 'and', 'a', 'to', 'was', 'it', 'in',
      'for', 'with', 'as', 'his', 'her', 'he', 'she', 'that', 'by', 'be',
      'have', 'has', 'had', 'this', 'will', 'you', 'are', 'not', 'or', 'an',
      'but', 'can', 'if', 'from', 'they', 'we', 'been', 'their', 'said', 'do'
    };
    return stopWords.contains(word.toLowerCase());
  }
}

// Note sentiment enum
enum NoteSentiment {
  positive,
  negative,
  neutral,
}
