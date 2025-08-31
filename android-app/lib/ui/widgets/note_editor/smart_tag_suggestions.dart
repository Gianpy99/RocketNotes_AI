// lib/ui/widgets/note_editor/smart_tag_suggestions.dart
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class SmartTagSuggestions extends StatefulWidget {
  final String content;
  final List<String> currentTags;
  final List<String> recentTags;
  final Function(List<String>) onTagsSelected;

  const SmartTagSuggestions({
    super.key,
    required this.content,
    required this.currentTags,
    required this.recentTags,
    required this.onTagsSelected,
  });

  @override
  State<SmartTagSuggestions> createState() => _SmartTagSuggestionsState();
}

class _SmartTagSuggestionsState extends State<SmartTagSuggestions> {
  List<TagSuggestion> _suggestions = [];
  bool _isAnalyzing = false;

  @override
  void initState() {
    super.initState();
    _generateSuggestions();
  }

  @override
  void didUpdateWidget(SmartTagSuggestions oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.content != widget.content && widget.content.length > 20) {
      _debouncedGenerateSuggestions();
    }
  }

  void _debouncedGenerateSuggestions() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && widget.content.length > 20) {
        _generateSuggestions();
      }
    });
  }

  void _generateSuggestions() {
    if (widget.content.trim().length < 20) {
      setState(() {
        _suggestions = [];
      });
      return;
    }

    setState(() {
      _isAnalyzing = true;
    });

    // Simulate analysis delay
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        final suggestions = _analyzeContentForTags(widget.content);
        setState(() {
          _suggestions = suggestions;
          _isAnalyzing = false;
        });
      }
    });
  }

  List<TagSuggestion> _analyzeContentForTags(String content) {
    final suggestions = <TagSuggestion>[];
    final contentLower = content.toLowerCase();
    final words = contentLower.split(RegExp(r'\W+'));

    // Common categories with keywords
    final categories = {
      'meeting': ['meeting', 'agenda', 'discussion', 'call', 'zoom', 'teams'],
      'idea': ['idea', 'concept', 'brainstorm', 'thought', 'innovation'],
      'todo': ['todo', 'task', 'action', 'complete', 'finish', 'deadline'],
      'project': ['project', 'development', 'build', 'create', 'design'],
      'personal': ['personal', 'diary', 'journal', 'reflection', 'private'],
      'work': ['work', 'office', 'job', 'career', 'professional'],
      'research': ['research', 'study', 'analysis', 'investigation', 'findings'],
      'important': ['important', 'urgent', 'critical', 'priority', 'key'],
      'review': ['review', 'feedback', 'evaluation', 'assessment', 'retrospective'],
      'learning': ['learn', 'education', 'tutorial', 'course', 'training'],
    };

    // Domain-specific tags
    final domains = {
      'tech': ['code', 'programming', 'development', 'software', 'api', 'database'],
      'design': ['design', 'ui', 'ux', 'interface', 'mockup', 'wireframe'],
      'business': ['business', 'strategy', 'market', 'revenue', 'profit', 'sales'],
      'finance': ['finance', 'budget', 'cost', 'investment', 'money', 'expense'],
      'health': ['health', 'fitness', 'exercise', 'medical', 'doctor', 'wellness'],
      'travel': ['travel', 'trip', 'vacation', 'flight', 'hotel', 'destination'],
    };

    // Check for category matches
    for (final entry in categories.entries) {
      final tag = entry.key;
      final keywords = entry.value;
      
      if (widget.currentTags.contains(tag)) continue;
      
      final matchCount = keywords.where((keyword) => 
        words.any((word) => word.contains(keyword)) ||
        contentLower.contains(keyword)
      ).length;
      
      if (matchCount > 0) {
        suggestions.add(TagSuggestion(
          tag: tag,
          confidence: (matchCount / keywords.length).clamp(0.0, 1.0),
          reason: 'Found ${matchCount == 1 ? 'keyword' : 'keywords'}: ${keywords.where((k) => contentLower.contains(k)).join(', ')}',
          source: TagSuggestionSource.content,
        ));
      }
    }

    // Check for domain matches
    for (final entry in domains.entries) {
      final tag = entry.key;
      final keywords = entry.value;
      
      if (widget.currentTags.contains(tag)) continue;
      
      final matchCount = keywords.where((keyword) => 
        words.any((word) => word.contains(keyword)) ||
        contentLower.contains(keyword)
      ).length;
      
      if (matchCount >= 2) { // Higher threshold for domain tags
        suggestions.add(TagSuggestion(
          tag: tag,
          confidence: (matchCount / keywords.length).clamp(0.0, 1.0),
          reason: 'Technical content detected',
          source: TagSuggestionSource.domain,
        ));
      }
    }

    // Add recent tags that might be relevant
    for (final recentTag in widget.recentTags) {
      if (widget.currentTags.contains(recentTag)) continue;
      if (suggestions.any((s) => s.tag == recentTag)) continue;
      
      if (suggestions.length < 5) {
        suggestions.add(TagSuggestion(
          tag: recentTag,
          confidence: 0.4,
          reason: 'Recently used tag',
          source: TagSuggestionSource.recent,
        ));
      }
    }

    // Sort by confidence and take top 6
    suggestions.sort((a, b) => b.confidence.compareTo(a.confidence));
    return suggestions.take(6).toList();
  }

  void _applySuggestion(TagSuggestion suggestion) {
    final newTags = [...widget.currentTags, suggestion.tag];
    widget.onTagsSelected(newTags);
    
    // Remove applied suggestion
    setState(() {
      _suggestions.removeWhere((s) => s.tag == suggestion.tag);
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added tag: ${suggestion.tag}'),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_suggestions.isEmpty && !_isAnalyzing) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.local_offer_outlined,
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Smart Tag Suggestions',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                if (_isAnalyzing) ...[
                  const SizedBox(width: 12),
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ],
              ],
            ),
            
            if (_isAnalyzing)
              const Padding(
                padding: EdgeInsets.only(top: 16),
                child: Text(
                  'Analyzing content...',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
              )
            else if (_suggestions.isNotEmpty) ...[
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _suggestions.map((suggestion) {
                  return _SuggestionChip(
                    suggestion: suggestion,
                    onTap: () => _applySuggestion(suggestion),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  final TagSuggestion suggestion;
  final VoidCallback onTap;

  const _SuggestionChip({
    required this.suggestion,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: suggestion.reason,
      child: ActionChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(suggestion.tag),
            const SizedBox(width: 4),
            Icon(
              _getSourceIcon(),
              size: 14,
              color: Colors.grey[600],
            ),
          ],
        ),
        onPressed: onTap,
        backgroundColor: _getBackgroundColor(),
        side: BorderSide(
          color: _getBorderColor(),
          width: 1,
        ),
      ),
    );
  }

  Color _getBackgroundColor() {
    switch (suggestion.source) {
      case TagSuggestionSource.content:
        return Colors.blue.shade50;
      case TagSuggestionSource.domain:
        return Colors.purple.shade50;
      case TagSuggestionSource.recent:
        return Colors.grey.shade50;
    }
  }

  Color _getBorderColor() {
    switch (suggestion.source) {
      case TagSuggestionSource.content:
        return Colors.blue.shade200;
      case TagSuggestionSource.domain:
        return Colors.purple.shade200;
      case TagSuggestionSource.recent:
        return Colors.grey.shade300;
    }
  }

  IconData _getSourceIcon() {
    switch (suggestion.source) {
      case TagSuggestionSource.content:
        return Icons.article_outlined;
      case TagSuggestionSource.domain:
        return Icons.category_outlined;
      case TagSuggestionSource.recent:
        return Icons.history;
    }
  }
}

enum TagSuggestionSource {
  content,
  domain,
  recent,
}

class TagSuggestion {
  final String tag;
  final double confidence;
  final String reason;
  final TagSuggestionSource source;

  const TagSuggestion({
    required this.tag,
    required this.confidence,
    required this.reason,
    required this.source,
  });
}
