// ==========================================
// lib/features/rocketbook/services/template_data_extractor.dart
// ==========================================

import 'package:flutter/foundation.dart';
import '../models/rocketbook_template.dart';

/// Service to extract structured data from Rocketbook templates
class TemplateDataExtractor {
  static final TemplateDataExtractor _instance = TemplateDataExtractor._();
  static TemplateDataExtractor get instance => _instance;
  
  TemplateDataExtractor._();

  /// Extract data from recognized template
  Future<ExtractedData> extractData({
    required RocketbookTemplate template,
    required String ocrText,
  }) async {
    debugPrint('[TemplateExtractor] Extracting data from ${template.displayName}');
    
    try {
      switch (template) {
        case RocketbookTemplate.meetingNotes:
          return _extractMeetingNotes(ocrText);
        
        case RocketbookTemplate.projectManagement:
          return _extractProjectManagement(ocrText);
        
        case RocketbookTemplate.weekly:
          return _extractWeeklyPlanner(ocrText);
        
        case RocketbookTemplate.monthly:
          return _extractMonthlyCalendar(ocrText);
        
        case RocketbookTemplate.monthlyDashboard:
          return _extractMonthlyDashboard(ocrText);
        
        case RocketbookTemplate.listPage:
          return _extractListPage(ocrText);
        
        case RocketbookTemplate.customTable:
          return _extractCustomTable(ocrText);
        
        case RocketbookTemplate.lined:
        case RocketbookTemplate.dotGrid:
        case RocketbookTemplate.graph:
        case RocketbookTemplate.blank:
          return _extractPlainText(ocrText);
        
        case RocketbookTemplate.unknown:
          return ExtractedData(
            template: template,
            title: 'Unknown Template',
            content: ocrText,
          );
      }
    } catch (e) {
      debugPrint('[TemplateExtractor] Error extracting data: $e');
      return ExtractedData(
        template: template,
        title: 'Extraction Error',
        content: ocrText,
        error: e.toString(),
      );
    }
  }

  ExtractedData _extractMeetingNotes(String text) {
    final data = <String, dynamic>{};
    
    // Extract title (first line usually)
    final lines = text.split('\n').where((l) => l.trim().isNotEmpty).toList();
    final title = lines.isNotEmpty ? lines.first : 'Meeting Notes';
    
    // Extract date patterns (e.g., "Jan 15, 2024", "15/01/2024")
    final datePattern = RegExp(r'\b(\d{1,2}[/-]\d{1,2}[/-]\d{2,4}|\w+ \d{1,2},? \d{4})\b');
    final dateMatch = datePattern.firstMatch(text);
    if (dateMatch != null) {
      data['date'] = dateMatch.group(0);
    }
    
    // Extract attendees (look for "Attendees:", "Participants:", etc.)
    final attendeePattern = RegExp(r'(?:attendees?|participants?):(.+?)(?:\n\n|\Z)', 
      caseSensitive: false, dotAll: true);
    final attendeeMatch = attendeePattern.firstMatch(text);
    if (attendeeMatch != null) {
      data['attendees'] = attendeeMatch.group(1)?.trim().split(',')
        .map((a) => a.trim()).toList();
    }
    
    // Extract action items (lines starting with ☐, □, [ ], -, *, etc.)
    final actionPattern = RegExp(r'^[\s]*[☐□\[\]\-\*]\s*(.+)$', multiLine: true);
    final actions = actionPattern.allMatches(text)
      .map((m) => m.group(1)?.trim())
      .where((a) => a != null && a.isNotEmpty)
      .toList();
    if (actions.isNotEmpty) {
      data['actionItems'] = actions;
    }
    
    // Extract notes section
    data['notes'] = text;
    
    return ExtractedData(
      template: RocketbookTemplate.meetingNotes,
      title: title,
      content: text,
      structuredData: data,
    );
  }

  ExtractedData _extractProjectManagement(String text) {
    final data = <String, dynamic>{};
    
    final lines = text.split('\n').where((l) => l.trim().isNotEmpty).toList();
    final title = lines.isNotEmpty ? lines.first : 'Project';
    
    // Extract tasks (checkbox items)
    final taskPattern = RegExp(r'^[\s]*[☐□\[\]\-\*]\s*(.+)$', multiLine: true);
    final tasks = taskPattern.allMatches(text)
      .map((m) => m.group(1)?.trim())
      .where((t) => t != null && t.isNotEmpty)
      .toList();
    if (tasks.isNotEmpty) {
      data['tasks'] = tasks;
    }
    
    // Extract dates/deadlines
    final datePattern = RegExp(r'\b(\d{1,2}[/-]\d{1,2}[/-]\d{2,4})\b');
    final dates = datePattern.allMatches(text)
      .map((m) => m.group(0))
      .toList();
    if (dates.isNotEmpty) {
      data['deadlines'] = dates;
    }
    
    // Extract milestones (lines with milestone indicators)
    final milestonePattern = RegExp(r'(?:milestone|phase|sprint):(.+?)(?:\n|$)', 
      caseSensitive: false);
    final milestones = milestonePattern.allMatches(text)
      .map((m) => m.group(1)?.trim())
      .where((m) => m != null && m.isNotEmpty)
      .toList();
    if (milestones.isNotEmpty) {
      data['milestones'] = milestones;
    }
    
    return ExtractedData(
      template: RocketbookTemplate.projectManagement,
      title: title,
      content: text,
      structuredData: data,
    );
  }

  ExtractedData _extractWeeklyPlanner(String text) {
    final data = <String, dynamic>{};
    
    final title = 'Weekly Planner';
    
    // Extract week dates
    final weekPattern = RegExp(r'week of (.+?)(?:\n|$)', caseSensitive: false);
    final weekMatch = weekPattern.firstMatch(text);
    if (weekMatch != null) {
      data['weekOf'] = weekMatch.group(1)?.trim();
    }
    
    // Extract daily entries (look for day names)
    final dayPattern = RegExp(r'(monday|tuesday|wednesday|thursday|friday|saturday|sunday):(.+?)(?=(?:monday|tuesday|wednesday|thursday|friday|saturday|sunday):|$)', 
      caseSensitive: false, dotAll: true);
    final days = <String, String>{};
    for (final match in dayPattern.allMatches(text)) {
      final day = match.group(1)?.trim();
      final content = match.group(2)?.trim();
      if (day != null && content != null) {
        days[day] = content;
      }
    }
    if (days.isNotEmpty) {
      data['days'] = days;
    }
    
    // Extract time slots
    final timePattern = RegExp(r'(\d{1,2}:\d{2}(?:\s*[AP]M)?)\s+(.+?)(?:\n|$)', 
      caseSensitive: false);
    final appointments = timePattern.allMatches(text)
      .map((m) => {'time': m.group(1), 'event': m.group(2)?.trim()})
      .toList();
    if (appointments.isNotEmpty) {
      data['appointments'] = appointments;
    }
    
    return ExtractedData(
      template: RocketbookTemplate.weekly,
      title: title,
      content: text,
      structuredData: data,
    );
  }

  ExtractedData _extractMonthlyCalendar(String text) {
    final data = <String, dynamic>{};
    
    // Extract month and year
    final monthPattern = RegExp(r'(january|february|march|april|may|june|july|august|september|october|november|december)\s+(\d{4})', 
      caseSensitive: false);
    final monthMatch = monthPattern.firstMatch(text);
    if (monthMatch != null) {
      data['month'] = monthMatch.group(1);
      data['year'] = monthMatch.group(2);
    }
    
    final title = monthMatch != null 
      ? '${monthMatch.group(1)} ${monthMatch.group(2)}'
      : 'Monthly Calendar';
    
    // Extract dated events (date followed by text)
    final eventPattern = RegExp(r'(\d{1,2})[:\s]+(.+?)(?:\n|$)');
    final events = <Map<String, String>>[];
    for (final match in eventPattern.allMatches(text)) {
      events.add({
        'date': match.group(1)!,
        'event': match.group(2)?.trim() ?? '',
      });
    }
    if (events.isNotEmpty) {
      data['events'] = events;
    }
    
    return ExtractedData(
      template: RocketbookTemplate.monthly,
      title: title,
      content: text,
      structuredData: data,
    );
  }

  ExtractedData _extractMonthlyDashboard(String text) {
    final data = <String, dynamic>{};
    
    final lines = text.split('\n').where((l) => l.trim().isNotEmpty).toList();
    final title = lines.isNotEmpty ? lines.first : 'Monthly Dashboard';
    
    // Extract goals
    final goalPattern = RegExp(r'(?:goal|objective):(.+?)(?:\n|$)', 
      caseSensitive: false);
    final goals = goalPattern.allMatches(text)
      .map((m) => m.group(1)?.trim())
      .where((g) => g != null && g.isNotEmpty)
      .toList();
    if (goals.isNotEmpty) {
      data['goals'] = goals;
    }
    
    // Extract metrics/KPIs (numbers with labels)
    final metricPattern = RegExp(r'(.+?):\s*(\d+(?:\.\d+)?)\s*(%|units?|items?)?', 
      caseSensitive: false);
    final metrics = <Map<String, String>>[];
    for (final match in metricPattern.allMatches(text)) {
      metrics.add({
        'name': match.group(1)?.trim() ?? '',
        'value': match.group(2) ?? '',
        'unit': match.group(3) ?? '',
      });
    }
    if (metrics.isNotEmpty) {
      data['metrics'] = metrics;
    }
    
    // Extract habit tracker (checkboxes)
    final habitPattern = RegExp(r'^[\s]*[☐□✓✗]\s*(.+)$', multiLine: true);
    final habits = habitPattern.allMatches(text)
      .map((m) => m.group(1)?.trim())
      .where((h) => h != null && h.isNotEmpty)
      .toList();
    if (habits.isNotEmpty) {
      data['habits'] = habits;
    }
    
    return ExtractedData(
      template: RocketbookTemplate.monthlyDashboard,
      title: title,
      content: text,
      structuredData: data,
    );
  }

  ExtractedData _extractListPage(String text) {
    final data = <String, dynamic>{};
    
    final lines = text.split('\n').where((l) => l.trim().isNotEmpty).toList();
    final title = lines.isNotEmpty ? lines.first : 'List';
    
    // Extract checklist items
    final itemPattern = RegExp(r'^[\s]*[☐□✓✗\[\]\-\*]\s*(.+)$', multiLine: true);
    final items = itemPattern.allMatches(text)
      .map((m) => m.group(1)?.trim())
      .where((i) => i != null && i.isNotEmpty)
      .toList();
    
    // Check for completed items (marked with ✓, ✗, [x])
    final completedPattern = RegExp(r'^[\s]*[✓✗]\s*(.+)$', multiLine: true);
    final completed = completedPattern.allMatches(text)
      .map((m) => m.group(1)?.trim())
      .where((i) => i != null && i.isNotEmpty)
      .toList();
    
    data['items'] = items;
    if (completed.isNotEmpty) {
      data['completed'] = completed;
    }
    
    return ExtractedData(
      template: RocketbookTemplate.listPage,
      title: title,
      content: text,
      structuredData: data,
    );
  }

  ExtractedData _extractCustomTable(String text) {
    final data = <String, dynamic>{};
    
    final lines = text.split('\n').where((l) => l.trim().isNotEmpty).toList();
    final title = lines.isNotEmpty ? lines.first : 'Table';
    
    // Try to detect table structure (rows with | or tabs)
    final tableRows = <List<String>>[];
    for (final line in lines) {
      if (line.contains('|')) {
        final cells = line.split('|')
          .map((c) => c.trim())
          .where((c) => c.isNotEmpty)
          .toList();
        if (cells.isNotEmpty) {
          tableRows.add(cells);
        }
      } else if (line.contains('\t')) {
        final cells = line.split('\t')
          .map((c) => c.trim())
          .where((c) => c.isNotEmpty)
          .toList();
        if (cells.isNotEmpty) {
          tableRows.add(cells);
        }
      }
    }
    
    if (tableRows.isNotEmpty) {
      data['rows'] = tableRows;
      data['columnCount'] = tableRows.first.length;
      data['rowCount'] = tableRows.length;
    }
    
    return ExtractedData(
      template: RocketbookTemplate.customTable,
      title: title,
      content: text,
      structuredData: data,
    );
  }

  ExtractedData _extractPlainText(String text) {
    final lines = text.split('\n').where((l) => l.trim().isNotEmpty).toList();
    final title = lines.isNotEmpty ? lines.first : 'Note';
    
    return ExtractedData(
      template: RocketbookTemplate.lined,
      title: title,
      content: text,
    );
  }
}

/// Extracted data from a template
class ExtractedData {
  final RocketbookTemplate template;
  final String title;
  final String content;
  final Map<String, dynamic>? structuredData;
  final String? error;

  ExtractedData({
    required this.template,
    required this.title,
    required this.content,
    this.structuredData,
    this.error,
  });

  bool get hasStructuredData => structuredData != null && structuredData!.isNotEmpty;
  bool get hasError => error != null;

  @override
  String toString() {
    return 'ExtractedData(template: ${template.displayName}, title: $title, hasStructured: $hasStructuredData, error: $error)';
  }
}
