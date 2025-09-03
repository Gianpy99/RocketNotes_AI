// lib/ui/widgets/dashboard/note_statistics.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/note.dart';

class NoteStatistics extends ConsumerWidget {
  final List<Note> notes;

  const NoteStatistics({
    super.key,
    required this.notes,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    final stats = _calculateStats(notes);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode 
          ? AppColors.surfaceDark.withValues(alpha: 0.7)
          : AppColors.surfaceLight.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDarkMode 
            ? AppColors.textSecondaryDark.withValues(alpha: 0.2)
            : AppColors.textSecondaryLight.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.analytics_outlined,
                color: AppColors.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Note Statistics',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Stats Grid
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.5,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            children: [
              _StatCard(
                title: 'Total Notes',
                value: stats.totalNotes.toString(),
                icon: Icons.note_rounded,
                color: Colors.blue,
              ),
              _StatCard(
                title: 'This Week',
                value: stats.notesThisWeek.toString(),
                icon: Icons.calendar_today, // Sostituisce calendar_week_rounded che non esiste
                color: Colors.green,
              ),
              _StatCard(
                title: 'Total Tags',
                value: stats.totalTags.toString(),
                icon: Icons.local_offer_rounded,
                color: Colors.orange,
              ),
              _StatCard(
                title: 'Avg Words',
                value: stats.averageWordCount.toString(),
                icon: Icons.text_fields_rounded,
                color: Colors.purple,
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Popular Tags
          if (stats.popularTags.isNotEmpty) ...[
            Text(
              'Popular Tags',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: stats.popularTags.take(5).map((tagStat) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        tagStat.tag,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          tagStat.count.toString(),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            
            const SizedBox(height: 16),
          ],
          
          // Activity Chart Preview
          _ActivityPreview(notes: notes),
        ],
      ),
    );
  }

  NoteStats _calculateStats(List<Note> notes) {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    
    final notesThisWeek = notes.where((note) {
      return note.createdAt.isAfter(weekAgo);
    }).length;
    
    final allTags = <String>[];
    var totalWords = 0;
    
    for (final note in notes) {
      allTags.addAll(note.tags);
      totalWords += note.content.split(RegExp(r'\s+')).length;
    }
    
    final tagCounts = <String, int>{};
    for (final tag in allTags) {
      tagCounts[tag] = (tagCounts[tag] ?? 0) + 1;
    }
    
    final popularTags = tagCounts.entries
        .map((e) => TagStat(e.key, e.value))
        .toList()
      ..sort((a, b) => b.count.compareTo(a.count));
    
    return NoteStats(
      totalNotes: notes.length,
      notesThisWeek: notesThisWeek,
      totalTags: tagCounts.keys.length,
      averageWordCount: notes.isEmpty ? 0 : (totalWords / notes.length).round(),
      popularTags: popularTags,
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(
                icon,
                color: color,
                size: 20,
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          
          Text(
            title,
            style: theme.textTheme.bodySmall?.copyWith(
              color: isDarkMode 
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityPreview extends StatelessWidget {
  final List<Note> notes;

  const _ActivityPreview({required this.notes});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    final activityData = _getWeekActivity();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'This Week\'s Activity',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        
        SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: activityData.map((dayData) {
              const maxHeight = 40.0;
              final height = dayData.count == 0 
                ? 4.0 
                : (dayData.count / activityData.map((d) => d.count).reduce((a, b) => a > b ? a : b) * maxHeight).clamp(4.0, maxHeight);
              
              return Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    width: 30,
                    height: height,
                    decoration: BoxDecoration(
                      color: dayData.count > 0 
                        ? AppColors.primary.withValues(alpha: 0.8)
                        : Colors.grey.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dayData.dayName,
                    style: TextStyle(
                      fontSize: 10,
                      color: isDarkMode 
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  List<DayActivity> _getWeekActivity() {
    final now = DateTime.now();
    final activities = <DayActivity>[];
    
    for (int i = 6; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      final dayStart = DateTime(day.year, day.month, day.day);
      final dayEnd = dayStart.add(const Duration(days: 1));
      
      final notesCount = notes.where((note) {
        final createdAt = note.createdAt;
        return createdAt.isAfter(dayStart) &&
               createdAt.isBefore(dayEnd);
      }).length;
      
      activities.add(DayActivity(
        date: day,
        dayName: _getDayName(day.weekday),
        count: notesCount,
      ));
    }
    
    return activities;
  }

  String _getDayName(int weekday) {
    switch (weekday) {
      case 1: return 'M';
      case 2: return 'T';
      case 3: return 'W';
      case 4: return 'T';
      case 5: return 'F';
      case 6: return 'S';
      case 7: return 'S';
      default: return '';
    }
  }
}

class NoteStats {
  final int totalNotes;
  final int notesThisWeek;
  final int totalTags;
  final int averageWordCount;
  final List<TagStat> popularTags;

  const NoteStats({
    required this.totalNotes,
    required this.notesThisWeek,
    required this.totalTags,
    required this.averageWordCount,
    required this.popularTags,
  });
}

class TagStat {
  final String tag;
  final int count;

  const TagStat(this.tag, this.count);
}

class DayActivity {
  final DateTime date;
  final String dayName;
  final int count;

  const DayActivity({
    required this.date,
    required this.dayName,
    required this.count,
  });
}
