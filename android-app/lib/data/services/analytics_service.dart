// lib/data/services/analytics_service.dart
import 'package:hive/hive.dart';
import '../models/note_model.dart';
import '../../features/rocketbook/models/scanned_content.dart';
import '../../core/constants/app_constants.dart';

class AnalyticsService {
  AnalyticsService._();
  static final AnalyticsService instance = AnalyticsService._();

  Box<NoteModel> get _notesBox => Hive.box<NoteModel>(AppConstants.notesBox);
  Box<ScannedContent> get _scansBox => Hive.box<ScannedContent>(AppConstants.scansBox);

  /// KPI principali per una finestra temporale
  Future<AnalyticsSummary> getSummary({required DateTime from, required DateTime to}) async {
    final notes = _notesBox.values.where((n) => !n.isArchived && n.createdAt.isAfter(from) && n.createdAt.isBefore(to)).toList();
    final total = notes.length;
    final withAi = notes.where((n) => (n.aiSummary?.isNotEmpty ?? false)).length;
    final withOcr = notes.where((n) => n.tags.contains('ocr') || n.attachments.isNotEmpty).length;

    // Tag frequencies
    final Map<String, int> tagFreq = {};
    for (final n in notes) {
      for (final t in n.tags) {
        tagFreq[t] = (tagFreq[t] ?? 0) + 1;
      }
    }
    final topTags = tagFreq.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Giorni attivi
    final Set<String> activeDays = notes.map((n) => _dayKey(n.createdAt)).toSet();

    // Media note per giorno
    final days = to.difference(from).inDays.clamp(1, 365);
    final avgPerDay = total / days;

    // Tempo medio OCR/AI
    final scans = _scansBox.values.where((s) => s.scannedAt.isAfter(from) && s.scannedAt.isBefore(to)).toList();
    final ocrTimes = scans.map((s) => s.ocrMetadata.processingTime.inMilliseconds).where((ms) => ms > 0).toList();
  final avgOcrMs = ocrTimes.isEmpty ? 0.0 : (ocrTimes.reduce((a, b) => a + b) / ocrTimes.length).toDouble();
    // AI time: usa insights['ai_processing_ms'] se presente
    final aiTimes = scans
        .map((s) => s.aiAnalysis?.insights['ai_processing_ms'])
        .where((v) => v != null)
        .map((v) => (v is int) ? v : (v is double ? v.toInt() : 0))
        .where((ms) => ms > 0)
        .cast<int>()
        .toList();
    final avgAiMs = aiTimes.isEmpty ? 0.0 : (aiTimes.reduce((a, b) => a + b) / aiTimes.length).toDouble();

    // Sentiment medio (se presente in aiAnalysis)
    double sentimentSum = 0;
    int sentimentCount = 0;
    for (final s in scans) {
      final sentiment = s.aiAnalysis?.sentiment;
      if (sentiment != null) { sentimentSum += sentiment; sentimentCount++; }
    }
    final avgSentiment = sentimentCount == 0 ? 0.0 : (sentimentSum / sentimentCount);

    // Split per mode
    final workCount = notes.where((n) => n.mode == 'work').length;
    final personalCount = notes.where((n) => n.mode == 'personal').length;

    return AnalyticsSummary(
      totalNotes: total,
      notesWithAI: withAi,
      notesWithOCR: withOcr,
      topTags: topTags.take(5).map((e) => TagCount(e.key, e.value)).toList(),
      activeDays: activeDays.length,
      avgNotesPerDay: avgPerDay,
      avgOcrMs: avgOcrMs,
      avgAiMs: avgAiMs,
      avgSentiment: avgSentiment,
      workNotes: workCount,
      personalNotes: personalCount,
    );
  }

  /// Distribuzione per settimana nell'ultimo mese
  Future<List<WeekBucket>> getWeeklyDistribution({required DateTime from, required DateTime to}) async {
    final notes = _notesBox.values.where((n) => !n.isArchived && n.createdAt.isAfter(from) && n.createdAt.isBefore(to)).toList();
    final Map<int, int> weekCounts = {};
    for (final n in notes) {
      final week = _isoWeekOfYear(n.createdAt);
      weekCounts[week] = (weekCounts[week] ?? 0) + 1;
    }
    final buckets = weekCounts.entries.map((e) => WeekBucket(weekNumber: e.key, count: e.value)).toList()
      ..sort((a, b) => a.weekNumber.compareTo(b.weekNumber));
    return buckets;
  }

  String _dayKey(DateTime dt) => '${dt.year}-${dt.month}-${dt.day}';

  // Calcolo ISO week semplificato
  int _isoWeekOfYear(DateTime date) {
    // Sposta la settimana a partire dal lunedì
    final thursday = date.add(Duration(days: (3 - ((date.weekday + 6) % 7))));
    final firstThursday = DateTime(thursday.year, 1, 4);
    final diff = thursday.difference(firstThursday);
    return 1 + (diff.inDays / 7).floor();
  }
}

class AnalyticsSummary {
  final int totalNotes;
  final int notesWithAI;
  final int notesWithOCR;
  final List<TagCount> topTags;
  final int activeDays;
  final double avgNotesPerDay;
  final double avgOcrMs;
  final double avgAiMs;
  final double avgSentiment; // -1..1
  final int workNotes;
  final int personalNotes;

  AnalyticsSummary({
    required this.totalNotes,
    required this.notesWithAI,
    required this.notesWithOCR,
    required this.topTags,
    required this.activeDays,
    required this.avgNotesPerDay,
    this.avgOcrMs = 0,
    this.avgAiMs = 0,
    this.avgSentiment = 0,
    this.workNotes = 0,
    this.personalNotes = 0,
  });
}

class TagCount {
  final String tag;
  final int count;
  TagCount(this.tag, this.count);
}

class WeekBucket {
  final int weekNumber;
  final int count;
  WeekBucket({required this.weekNumber, required this.count});
}
