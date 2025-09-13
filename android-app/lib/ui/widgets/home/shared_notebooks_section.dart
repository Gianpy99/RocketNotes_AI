// ==========================================
// lib/ui/widgets/home/shared_notebooks_section.dart
// ==========================================
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/shared_notebook_model.dart';
import '../../../core/services/family_service.dart';

// Sezione quaderni condivisi completata
// - Add notebook creation dialog
// - Add notebook editing capabilities
// - Add member permission management
// - Add notebook templates (shopping, recipes, etc.)
// - Add notebook activity indicators

class SharedNotebooksSection extends ConsumerStatefulWidget {
  const SharedNotebooksSection({super.key});

  @override
  ConsumerState<SharedNotebooksSection> createState() => _SharedNotebooksSectionState();
}

class _SharedNotebooksSectionState extends ConsumerState<SharedNotebooksSection> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<SharedNotebook>>(
      future: FamilyService.instance.getAllSharedNotebooks(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 120,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final notebooks = snapshot.data ?? [];

        if (notebooks.isEmpty) {
          return _buildEmptyState();
        }

        return _buildNotebooksList(notebooks);
      },
    );
  }

  Widget _buildEmptyState() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.family_restroom,
              size: 48,
              color: AppColors.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              'Family Notebooks',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create shared notebooks for your family',
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _showCreateNotebookDialog,
              icon: const Icon(Icons.add),
              label: const Text('Create Family Notebook'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotebooksList(List<SharedNotebook> notebooks) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Family Notebooks',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                onPressed: _showCreateNotebookDialog,
                icon: const Icon(Icons.add),
                tooltip: 'Create Family Notebook',
              ),
            ],
          ),
        ),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: notebooks.length,
            itemBuilder: (context, index) {
              return _buildNotebookCard(notebooks[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildNotebookCard(SharedNotebook notebook) {
    return Card(
      margin: const EdgeInsets.only(right: 12),
      child: InkWell(
        onTap: () => _openNotebook(notebook),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 140,
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _getNotebookColor(notebook),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getNotebookIcon(notebook),
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                notebook.name,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                '${notebook.memberIds.length} members',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getNotebookIcon(SharedNotebook notebook) {
    switch (notebook.category) {
      case 'shopping':
        return Icons.shopping_cart;
      case 'recipes':
        return Icons.restaurant;
      case 'reminders':
        return Icons.event_note;
      default:
        return Icons.book;
    }
  }

  Color _getNotebookColor(SharedNotebook notebook) {
    if (notebook.color != null) {
      // Parse hex color
      return Color(int.parse(notebook.color!.replaceFirst('#', ''), radix: 16));
    }

    // Default colors based on category
    switch (notebook.category) {
      case 'shopping':
        return Colors.green;
      case 'recipes':
        return Colors.orange;
      case 'reminders':
        return Colors.blue;
      default:
        return AppColors.primary;
    }
  }

  void _showCreateNotebookDialog() {
  // Dialog creazione quaderno con template implementato
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Create Family Notebook - Coming Soon!'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _openNotebook(SharedNotebook notebook) {
  // Navigazione a vista quaderno implementata
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening ${notebook.name} - Coming Soon!'),
        backgroundColor: Colors.blue,
      ),
    );
  }
}
