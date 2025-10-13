import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/analytics_service.dart';
import '../../data/models/note_model.dart';
import '../providers/app_providers_simple.dart';

class StatisticsScreen extends ConsumerWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
  final repo = ref.read(noteRepositoryProvider);
  DateTime now = DateTime.now();
  Duration selected = const Duration(days: 30);
  DateTime from = now.subtract(selected);

    return FutureBuilder<List<NoteModel>>(
      future: repo.getAllNotes(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Scaffold(
            appBar: AppBar(title: const Text('Statistics')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final analytics = AnalyticsService.instance;
        return FutureBuilder(
          future: Future.wait([
            analytics.getSummary(from: from, to: now),
            analytics.getWeeklyDistribution(from: from, to: now),
          ]),
          builder: (context, AsyncSnapshot<List<dynamic>> snap) {
            if (snap.connectionState != ConnectionState.done) {
              return Scaffold(
                appBar: AppBar(title: const Text('Statistics')),
                body: const Center(child: CircularProgressIndicator()),
              );
            }

            final summary = snap.data![0] as AnalyticsSummary;
            final weeks = snap.data![1] as List<WeekBucket>;

            return StatefulBuilder(builder: (context, setLocalState) {
              return Scaffold(
                appBar: AppBar(
                  title: const Text('Statistics'),
                  backgroundColor: Theme.of(context).colorScheme.inversePrimary,
                  actions: [
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.filter_list),
                      onSelected: (value) {
                        setLocalState(() {
                          now = DateTime.now();
                          if (value == '7') {
                            selected = const Duration(days: 7);
                          } else if (value == '30') {
                            selected = const Duration(days: 30);
                          } else {
                            selected = const Duration(days: 365);
                          }
                          from = now.subtract(selected);
                        });
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(value: '7', child: Text('Last 7 days')),
                        PopupMenuItem(value: '30', child: Text('Last 30 days')),
                        PopupMenuItem(value: '365', child: Text('Last year')),
                      ],
                    ),
                    IconButton(
                      tooltip: 'Custom range',
                      icon: const Icon(Icons.date_range),
                      onPressed: () async {
                        final picked = await showDateRangePicker(
                          context: context,
                          firstDate: DateTime.now().subtract(const Duration(days: 365 * 5)),
                          lastDate: DateTime.now(),
                          initialDateRange: DateTimeRange(start: from, end: now),
                        );
                        if (picked != null) {
                          setLocalState(() {
                            from = picked.start;
                            now = picked.end;
                            selected = now.difference(from);
                          });
                        }
                      },
                    ),
                  ],
                ),
              body: Padding(
                padding: const EdgeInsets.all(16),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _kpiGrid(context, summary),
                      const SizedBox(height: 24),
                      _weeklyChart(context, weeks),
                      const SizedBox(height: 24),
                      _topTags(context, summary),
                      const SizedBox(height: 24),
                      _modeSplit(context, summary),
                    ],
                  ),
                ),
              ),
            );
            });
          },
        );
      },
    );
  }

  Widget _kpiCard(BuildContext context, String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
        color: color.withAlpha((0.08 * 255).round()),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha((0.3 * 255).round())),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 8),
              Text(title, style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _kpiGrid(BuildContext context, AnalyticsSummary s) {
    return GridView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.6,
      ),
      children: [
        _kpiCard(context, 'Total Notes', s.totalNotes.toString(), Icons.note, Colors.blue),
        _kpiCard(context, 'With AI', s.notesWithAI.toString(), Icons.smart_toy, Colors.purple),
        _kpiCard(context, 'With OCR/Images', s.notesWithOCR.toString(), Icons.image, Colors.green),
        _kpiCard(context, 'Avg/day', s.avgNotesPerDay.toStringAsFixed(2), Icons.calendar_today, Colors.orange),
        _kpiCard(context, 'Avg OCR (ms)', s.avgOcrMs.toStringAsFixed(0), Icons.speed, Colors.teal),
        _kpiCard(context, 'Sentiment', s.avgSentiment.toStringAsFixed(2), Icons.mood, Colors.pink),
      ],
    );
  }

  Widget _weeklyChart(BuildContext context, List<WeekBucket> weeks) {
    if (weeks.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Weekly Distribution', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: weeks.map((w) {
            final height = (w.count * 8).toDouble().clamp(8.0, 140.0);
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(height: height, decoration: BoxDecoration(color: Colors.blueAccent, borderRadius: BorderRadius.circular(6))),
                    const SizedBox(height: 6),
                    Text('W${w.weekNumber}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    Text('${w.count}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _topTags(BuildContext context, AnalyticsSummary s) {
    if (s.topTags.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Top Tags', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: s.topTags
              .map((t) => Chip(
                    label: Text('${t.tag} (${t.count})'),
                    backgroundColor: Colors.grey.shade200,
                  ))
              .toList(),
        ),
      ],
    );
  }

  Widget _modeSplit(BuildContext context, AnalyticsSummary s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Mode Split', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _kpiCard(context, 'Work', s.workNotes.toString(), Icons.work, Colors.blueGrey),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _kpiCard(context, 'Personal', s.personalNotes.toString(), Icons.person, Colors.green),
            ),
          ],
        )
      ],
    );
  }
}
