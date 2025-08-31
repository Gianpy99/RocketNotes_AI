// lib/ui/widgets/note_editor/ai_content_suggestions.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';

class AIContentSuggestions extends ConsumerStatefulWidget {
  final String noteContent;
  final VoidCallback? onSuggestionApplied;

  const AIContentSuggestions({
    super.key,
    required this.noteContent,
    this.onSuggestionApplied,
  });

  @override
  ConsumerState<AIContentSuggestions> createState() => _AIContentSuggestionsState();
}

class _AIContentSuggestionsState extends ConsumerState<AIContentSuggestions> {
  bool _isExpanded = false;
  bool _isLoading = false;
  List<ContentSuggestion> _suggestions = [];

  @override
  void initState() {
    super.initState();
    if (widget.noteContent.length > 50) {
      _generateSuggestions();
    }
  }

  @override
  void didUpdateWidget(AIContentSuggestions oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.noteContent != widget.noteContent && 
        widget.noteContent.length > 50) {
      _debounceGenerateSuggestions();
    }
  }

  void _debounceGenerateSuggestions() {
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && widget.noteContent.length > 50) {
        _generateSuggestions();
      }
    });
  }

  Future<void> _generateSuggestions() async {
    if (widget.noteContent.trim().length < 50) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      // Simulate AI suggestions generation
      await Future.delayed(const Duration(seconds: 2));
      
      final suggestions = _generateMockSuggestions(widget.noteContent);
      
      setState(() {
        _suggestions = suggestions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating suggestions: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<ContentSuggestion> _generateMockSuggestions(String content) {
    final suggestions = <ContentSuggestion>[];
    
    // Grammar/spelling suggestions
    if (content.contains('recieve')) {
      suggestions.add(const ContentSuggestion(
        id: 'grammar_1',
        type: SuggestionType.correction,
        title: 'Spelling correction',
        content: 'Replace "recieve" with "receive"',
        originalText: 'recieve',
        replacementText: 'receive',
        confidence: 0.95,
      ));
    }
    
    // Content completion
    if (content.toLowerCase().contains('meeting') && !content.contains('action items')) {
      suggestions.add(const ContentSuggestion(
        id: 'completion_1',
        type: SuggestionType.completion,
        title: 'Add action items',
        content: 'Consider adding an "Action Items:" section to track follow-ups from this meeting.',
        originalText: null,
        replacementText: '\n\n## Action Items:\n- [ ] ',
        confidence: 0.80,
      ));
    }
    
    // Structure improvements
    if (content.length > 200 && !content.contains('#') && !content.contains('**')) {
      suggestions.add(const ContentSuggestion(
        id: 'improvement_1',
        type: SuggestionType.improvement,
        title: 'Add structure',
        content: 'This note could benefit from headings and formatting to improve readability.',
        originalText: null,
        replacementText: null,
        confidence: 0.70,
      ));
    }
    
    // Enhancement suggestions
    if (content.toLowerCase().contains('idea') && !content.contains('💡')) {
      suggestions.add(const ContentSuggestion(
        id: 'enhancement_1',
        type: SuggestionType.enhancement,
        title: 'Add visual cues',
        content: 'Consider adding emojis or formatting to highlight key ideas and make your notes more visually appealing.',
        originalText: 'idea',
        replacementText: '💡 idea',
        confidence: 0.60,
      ));
    }
    
    return suggestions;
  }

  void _applySuggestion(ContentSuggestion suggestion) {
    // Simulate applying suggestion
    widget.onSuggestionApplied?.call();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Applied: ${suggestion.title}'),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.green,
      ),
    );
    
    // Remove applied suggestion
    setState(() {
      _suggestions.removeWhere((s) => s.id == suggestion.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.noteContent.trim().length < 50) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        child: Column(
          children: [
            InkWell(
              onTap: () => setState(() => _isExpanded = !_isExpanded),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'AI Writing Assistant',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    if (_isLoading)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else if (_suggestions.isNotEmpty)
                      Badge(
                        label: Text('${_suggestions.length}'),
                        child: Icon(
                          _isExpanded 
                            ? Icons.keyboard_arrow_up 
                            : Icons.keyboard_arrow_down,
                        ),
                      )
                    else
                      Icon(
                        _isExpanded 
                          ? Icons.keyboard_arrow_up 
                          : Icons.keyboard_arrow_down,
                      ),
                  ],
                ),
              ),
            ),
            if (_isExpanded) ...[
              const Divider(height: 1),
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Analyzing your content...'),
                    ],
                  ),
                )
              else if (_suggestions.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Icon(
                        Icons.thumb_up_outlined,
                        size: 48,
                        color: Colors.green[400],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Looking good!',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No suggestions at the moment. Keep writing!',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  itemCount: _suggestions.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final suggestion = _suggestions[index];
                    return _SuggestionCard(
                      suggestion: suggestion,
                      onApply: () => _applySuggestion(suggestion),
                      onDismiss: () {
                        setState(() {
                          _suggestions.removeAt(index);
                        });
                      },
                    );
                  },
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SuggestionCard extends StatelessWidget {
  final ContentSuggestion suggestion;
  final VoidCallback onApply;
  final VoidCallback onDismiss;

  const _SuggestionCard({
    required this.suggestion,
    required this.onApply,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
        color: _getBackgroundColor(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getIcon(),
                size: 16,
                color: _getIconColor(),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  suggestion.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: _getIconColor(),
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            suggestion.content,
            style: const TextStyle(fontSize: 14),
          ),
          if (suggestion.originalText != null && suggestion.replacementText != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.remove, size: 16, color: Colors.red[600]),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          suggestion.originalText!,
                          style: TextStyle(
                            decoration: TextDecoration.lineThrough,
                            color: Colors.red[600],
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.add, size: 16, color: Colors.green[600]),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          suggestion.replacementText!,
                          style: TextStyle(
                            color: Colors.green[600],
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
          if (suggestion.confidence != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  'Confidence: ',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                Container(
                  width: 80,
                  height: 4,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    color: Colors.grey[300],
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: suggestion.confidence!,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2),
                        color: _getConfidenceColor(suggestion.confidence!),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${(suggestion.confidence! * 100).toInt()}%',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: onDismiss,
                child: const Text('Dismiss'),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: onApply,
                icon: const Icon(Icons.check, size: 16),
                label: const Text('Apply'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _getIconColor(),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getBackgroundColor() {
    switch (suggestion.type) {
      case SuggestionType.improvement:
        return Colors.blue.shade50;
      case SuggestionType.completion:
        return Colors.green.shade50;
      case SuggestionType.correction:
        return Colors.orange.shade50;
      case SuggestionType.enhancement:
        return Colors.purple.shade50;
    }
  }

  Color _getIconColor() {
    switch (suggestion.type) {
      case SuggestionType.improvement:
        return Colors.blue;
      case SuggestionType.completion:
        return Colors.green;
      case SuggestionType.correction:
        return Colors.orange;
      case SuggestionType.enhancement:
        return Colors.purple;
    }
  }

  IconData _getIcon() {
    switch (suggestion.type) {
      case SuggestionType.improvement:
        return Icons.trending_up;
      case SuggestionType.completion:
        return Icons.auto_fix_high;
      case SuggestionType.correction:
        return Icons.error_outline;
      case SuggestionType.enhancement:
        return Icons.star_outline;
    }
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.8) return Colors.green;
    if (confidence >= 0.6) return Colors.orange;
    return Colors.red;
  }
}

// Data models for content suggestions
enum SuggestionType {
  improvement,
  completion,
  correction,
  enhancement,
}

class ContentSuggestion {
  final String id;
  final SuggestionType type;
  final String title;
  final String content;
  final String? originalText;
  final String? replacementText;
  final double? confidence;
  final Map<String, dynamic>? metadata;

  const ContentSuggestion({
    required this.id,
    required this.type,
    required this.title,
    required this.content,
    this.originalText,
    this.replacementText,
    this.confidence,
    this.metadata,
  });

  factory ContentSuggestion.fromJson(Map<String, dynamic> json) {
    return ContentSuggestion(
      id: json['id'] as String,
      type: SuggestionType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => SuggestionType.improvement,
      ),
      title: json['title'] as String,
      content: json['content'] as String,
      originalText: json['originalText'] as String?,
      replacementText: json['replacementText'] as String?,
      confidence: json['confidence'] as double?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'title': title,
      'content': content,
      'originalText': originalText,
      'replacementText': replacementText,
      'confidence': confidence,
      'metadata': metadata,
    };
  }
}
