// lib/ui/widgets/home/stats_overview.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../presentation/providers/app_providers.dart';

class StatsOverview extends ConsumerWidget {
  const StatsOverview({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notesAsyncValue = ref.watch(notesProvider);
    
    return notesAsyncValue.when(
      data: (notes) {
        final totalNotes = notes.length;
        final tagsCount = notes.expand((note) => note.tags).toSet().length;
        final recentNotes = notes.where(
          (note) => DateTime.now().difference(note.updatedAt).inDays < 7
        ).length;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildStat(
                  context,
                  icon: Icons.note_rounded,
                  value: totalNotes.toString(),
                  label: 'Total Notes',
                ),
              ),
              Container(width: 1, height: 40, color: Colors.grey.shade300),
              Expanded(
                child: _buildStat(
                  context,
                  icon: Icons.local_offer_rounded,
                  value: tagsCount.toString(),
                  label: 'Tags',
                ),
              ),
              Container(width: 1, height: 40, color: Colors.grey.shade300),
              Expanded(
                child: _buildStat(
                  context,
                  icon: Icons.update_rounded,
                  value: recentNotes.toString(),
                  label: 'Recent',
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildStat(
    BuildContext context, {
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          color: AppColors.primary,
          size: 24,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
