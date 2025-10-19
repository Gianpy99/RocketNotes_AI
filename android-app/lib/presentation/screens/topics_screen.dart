// ==========================================
// lib/presentation/screens/topics_screen.dart
// ==========================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/topic.dart';
import '../../data/models/note.dart';
import '../../data/repositories/topic_repository.dart';
import '../../data/repositories/note_repository.dart';
import '../../data/services/topic_ai_service.dart';

// Provider for topic repository
final topicRepositoryProvider = Provider<TopicRepository>((ref) {
  return TopicRepository();
});

// Provider for topics list
final topicsProvider = FutureProvider<List<Topic>>((ref) async {
  final repo = ref.read(topicRepositoryProvider);
  return await repo.getAllTopics();
});

// Provider for AI service
final topicAIServiceProvider = Provider<TopicAIService>((ref) {
  return TopicAIService();
});

class TopicsScreen extends ConsumerStatefulWidget {
  const TopicsScreen({super.key});

  @override
  ConsumerState<TopicsScreen> createState() => _TopicsScreenState();
}

class _TopicsScreenState extends ConsumerState<TopicsScreen> {
  @override
  Widget build(BuildContext context) {
    final topicsAsync = ref.watch(topicsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('📚 Topics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () => _showHelp(),
            tooltip: 'Help',
          ),
        ],
      ),
      body: topicsAsync.when(
        data: (topics) => topics.isEmpty
            ? _buildEmptyState()
            : _buildTopicsList(topics),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error: $error'),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateTopicDialog(),
        icon: const Icon(Icons.add),
        label: const Text('New Topic'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.topic, size: 100, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'No Topics Yet',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Create topics to organize your notes by project, trip, meeting, or any category!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showCreateTopicDialog(),
            icon: const Icon(Icons.add),
            label: const Text('Create First Topic'),
          ),
        ],
      ),
    );
  }

  Widget _buildTopicsList(List<Topic> topics) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: topics.length,
      itemBuilder: (context, index) {
        final topic = topics[index];
        return _buildTopicCard(topic);
      },
    );
  }

  Widget _buildTopicCard(Topic topic) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectShape.withBorder(
        borderRadius: BorderRadius.circular(12),
        borderColor: topic.color.withOpacity(0.3),
      ),
      child: InkWell(
        onTap: () => _openTopicDetail(topic),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Color indicator
                  Container(
                    width: 4,
                    height: 40,
                    decoration: BoxDecoration(
                      color: topic.color,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Icon
                  if (topic.icon != null) ...[
                    Icon(topic.icon, color: topic.color, size: 32),
                    const SizedBox(width: 12),
                  ],
                  // Name and note count
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          topic.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${topic.noteCount} notes',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Favorite icon
                  if (topic.isFavorite)
                    const Icon(Icons.star, color: Colors.amber),
                  // More menu
                  PopupMenuButton(
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'summary',
                        child: const Row(
                          children: [
                            Icon(Icons.auto_awesome),
                            SizedBox(width: 8),
                            Text('AI Summary'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'favorite',
                        child: Row(
                          children: [
                            Icon(topic.isFavorite ? Icons.star : Icons.star_border),
                            const SizedBox(width: 8),
                            Text(topic.isFavorite ? 'Unfavorite' : 'Favorite'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) => _handleTopicAction(value.toString(), topic),
                  ),
                ],
              ),
              if (topic.description != null) ...[
                const SizedBox(height: 8),
                Text(
                  topic.description!,
                  style: TextStyle(color: Colors.grey[700]),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _handleTopicAction(String action, Topic topic) async {
    switch (action) {
      case 'summary':
        await _generateAISummary(topic);
        break;
      case 'favorite':
        await ref.read(topicRepositoryProvider).toggleFavorite(topic.id);
        ref.invalidate(topicsProvider);
        break;
      case 'edit':
        await _showEditTopicDialog(topic);
        break;
      case 'delete':
        await _deleteTopic(topic);
        break;
    }
  }

  Future<void> _generateAISummary(Topic topic) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Generating AI Summary...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      // Get notes for this topic
      final noteRepo = NoteRepository();
      final allNotes = await noteRepo.getAllNotes();
      final topicNotes = allNotes.where((n) => n.topicId == topic.id).toList();

      // Generate summary
      final aiService = ref.read(topicAIServiceProvider);
      final summary = await aiService.generateTopicSummary(
        topic: topic,
        notes: topicNotes,
      );

      // Close loading
      if (mounted) Navigator.pop(context);

      // Show summary
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => _buildSummaryDialog(summary),
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Widget _buildSummaryDialog(TopicSummary summary) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.auto_awesome, color: Colors.purple),
          const SizedBox(width: 8),
          Expanded(child: Text('AI Summary: ${summary.topicName}')),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${summary.noteCount} notes analyzed'),
            const Divider(),
            const SizedBox(height: 8),
            const Text(
              'Overview:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(summary.summary),
            if (summary.keyPoints.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Key Points:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              ...summary.keyPoints.map((point) => Padding(
                    padding: const EdgeInsets.only(left: 8, top: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• '),
                        Expanded(child: Text(point)),
                      ],
                    ),
                  )),
            ],
            if (summary.actionItems != null && summary.actionItems!.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Action Items:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              ...summary.actionItems!.map((action) => Padding(
                    padding: const EdgeInsets.only(left: 8, top: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.check_box_outline_blank, size: 16),
                        const SizedBox(width: 4),
                        Expanded(child: Text(action)),
                      ],
                    ),
                  )),
            ],
            if (summary.insights != null) ...[
              const SizedBox(height: 16),
              const Text(
                'Insights:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(summary.insights!),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }

  void _openTopicDetail(Topic topic) {
    // TODO: Navigate to topic detail screen with notes filtered by topicId
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Opening ${topic.name}...')),
    );
  }

  Future<void> _showCreateTopicDialog() async {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    Color selectedColor = TopicColors.predefined.first;
    IconData? selectedIcon;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Create New Topic'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Topic Name*',
                    hintText: 'e.g., Work Trip to Milan',
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(
                    labelText: 'Description (optional)',
                    hintText: 'What is this topic about?',
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                const Text('Color:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: TopicColors.predefined.map((color) {
                    final isSelected = color == selectedColor;
                    return GestureDetector(
                      onTap: () => setState(() => selectedColor = color),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: isSelected
                              ? Border.all(color: Colors.black, width: 3)
                              : null,
                        ),
                        child: isSelected
                            ? const Icon(Icons.check, color: Colors.white)
                            : null,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a topic name')),
                  );
                  return;
                }

                final topic = Topic.create(
                  name: nameController.text.trim(),
                  description: descController.text.trim().isEmpty
                      ? null
                      : descController.text.trim(),
                  color: selectedColor,
                  icon: selectedIcon,
                );

                await ref.read(topicRepositoryProvider).saveTopic(topic);
                ref.invalidate(topicsProvider);
                
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showEditTopicDialog(Topic topic) async {
    // Similar to create dialog but with existing values
    // Implementation omitted for brevity
  }

  Future<void> _deleteTopic(Topic topic) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Topic?'),
        content: Text('Are you sure you want to delete "${topic.name}"?\n\nNotes in this topic will not be deleted, just ungrouped.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(topicRepositoryProvider).deleteTopic(topic.id);
      ref.invalidate(topicsProvider);
    }
  }

  void _showHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.help_outline, color: Colors.blue),
            SizedBox(width: 8),
            Text('About Topics'),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Topics help you organize notes by project, trip, meeting, or any category.',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              Text('Features:'),
              SizedBox(height: 8),
              Text('• 📝 Group related notes together'),
              Text('• 🤖 AI-powered summaries of all notes in a topic'),
              Text('• 🎨 Custom colors and icons'),
              Text('• ⭐ Mark favorite topics'),
              SizedBox(height: 16),
              Text('Examples:'),
              SizedBox(height: 8),
              Text('• "Milan Work Trip" - All notes from your business trip'),
              Text('• "Q1 Marketing Meeting" - Meeting notes and action items'),
              Text('• "Project Alpha" - All project-related notes'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it!'),
          ),
        ],
      ),
    );
  }
}

// Helper class for custom shape with border
class RoundedRectShape extends ShapeBorder {
  final BorderRadius borderRadius;
  final Color? borderColor;
  final double borderWidth;

  const RoundedRectShape.withBorder({
    required this.borderRadius,
    this.borderColor,
    this.borderWidth = 2.0,
  });

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return Path()..addRRect(borderRadius.toRRect(rect).deflate(borderWidth));
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    return Path()..addRRect(borderRadius.toRRect(rect));
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    if (borderColor != null) {
      final paint = Paint()
        ..color = borderColor!
        ..style = PaintingStyle.stroke
        ..strokeWidth = borderWidth;
      canvas.drawRRect(borderRadius.toRRect(rect), paint);
    }
  }

  @override
  ShapeBorder scale(double t) => this;
}
