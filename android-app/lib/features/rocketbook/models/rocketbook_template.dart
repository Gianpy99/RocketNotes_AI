// ==========================================
// lib/features/rocketbook/models/rocketbook_template.dart
// ==========================================

import 'package:flutter/material.dart';

/// Enumeration of Rocketbook Fusion Plus templates
enum RocketbookTemplate {
  monthlyDashboard,
  listPage,
  monthly,
  weekly,
  customTable,
  projectManagement,
  meetingNotes,
  lined,
  dotGrid,
  graph,
  blank,
  unknown;

  String get displayName {
    switch (this) {
      case RocketbookTemplate.monthlyDashboard:
        return 'Monthly Dashboard';
      case RocketbookTemplate.listPage:
        return 'List Page';
      case RocketbookTemplate.monthly:
        return 'Monthly Calendar';
      case RocketbookTemplate.weekly:
        return 'Weekly Planner';
      case RocketbookTemplate.customTable:
        return 'Custom Table';
      case RocketbookTemplate.projectManagement:
        return 'Project Management';
      case RocketbookTemplate.meetingNotes:
        return 'Meeting Notes';
      case RocketbookTemplate.lined:
        return 'Lined';
      case RocketbookTemplate.dotGrid:
        return 'Dot Grid';
      case RocketbookTemplate.graph:
        return 'Graph';
      case RocketbookTemplate.blank:
        return 'Blank';
      case RocketbookTemplate.unknown:
        return 'Unknown Template';
    }
  }

  String get description {
    switch (this) {
      case RocketbookTemplate.monthlyDashboard:
        return 'Monthly overview with goals and tracking';
      case RocketbookTemplate.listPage:
        return 'Task lists and to-do items';
      case RocketbookTemplate.monthly:
        return 'Full month calendar view';
      case RocketbookTemplate.weekly:
        return 'Weekly schedule and planning';
      case RocketbookTemplate.customTable:
        return 'Customizable table for data';
      case RocketbookTemplate.projectManagement:
        return 'Project tracking and milestones';
      case RocketbookTemplate.meetingNotes:
        return 'Meeting notes with action items';
      case RocketbookTemplate.lined:
        return 'Standard lined paper';
      case RocketbookTemplate.dotGrid:
        return 'Dot grid for flexible notes';
      case RocketbookTemplate.graph:
        return 'Graph paper for diagrams';
      case RocketbookTemplate.blank:
        return 'Blank page for sketches';
      case RocketbookTemplate.unknown:
        return 'Template not recognized';
    }
  }

  IconData get icon {
    switch (this) {
      case RocketbookTemplate.monthlyDashboard:
        return Icons.dashboard;
      case RocketbookTemplate.listPage:
        return Icons.checklist;
      case RocketbookTemplate.monthly:
        return Icons.calendar_month;
      case RocketbookTemplate.weekly:
        return Icons.calendar_view_week;
      case RocketbookTemplate.customTable:
        return Icons.table_chart;
      case RocketbookTemplate.projectManagement:
        return Icons.assignment;
      case RocketbookTemplate.meetingNotes:
        return Icons.meeting_room;
      case RocketbookTemplate.lined:
        return Icons.notes;
      case RocketbookTemplate.dotGrid:
        return Icons.grid_on;
      case RocketbookTemplate.graph:
        return Icons.grid_4x4;
      case RocketbookTemplate.blank:
        return Icons.crop_portrait;
      case RocketbookTemplate.unknown:
        return Icons.help_outline;
    }
  }

  /// Get expected data structure for this template
  TemplateStructure get structure {
    switch (this) {
      case RocketbookTemplate.monthlyDashboard:
        return TemplateStructure.monthlyDashboard;
      case RocketbookTemplate.listPage:
        return TemplateStructure.list;
      case RocketbookTemplate.monthly:
        return TemplateStructure.calendar;
      case RocketbookTemplate.weekly:
        return TemplateStructure.weekly;
      case RocketbookTemplate.customTable:
        return TemplateStructure.table;
      case RocketbookTemplate.projectManagement:
        return TemplateStructure.project;
      case RocketbookTemplate.meetingNotes:
        return TemplateStructure.meeting;
      default:
        return TemplateStructure.freeform;
    }
  }
}

/// Expected structure for each template type
enum TemplateStructure {
  monthlyDashboard,  // Goals, metrics, habits
  list,              // Checkboxes, items
  calendar,          // Days, events
  weekly,            // Days with time slots
  table,             // Rows and columns
  project,           // Tasks, timeline, status
  meeting,           // Title, attendees, notes, actions
  freeform;          // Free text/drawing
}

/// Rocketbook symbol (bottom of each page)
enum RocketbookSymbol {
  bell,          // 🔔 Notifications/reminders
  diamond,       // 💎 Archive/important
  star,          // ⭐ Favorites
  clover,        // 🍀 Category 1
  horseshoe,     // 🧲 Category 2
  rocket,        // 🚀 Send to email/cloud
  apple;         // 🍎 Health/wellness

  String get displayName {
    switch (this) {
      case RocketbookSymbol.bell:
        return 'Bell';
      case RocketbookSymbol.diamond:
        return 'Diamond';
      case RocketbookSymbol.star:
        return 'Star';
      case RocketbookSymbol.clover:
        return 'Clover';
      case RocketbookSymbol.horseshoe:
        return 'Horseshoe';
      case RocketbookSymbol.rocket:
        return 'Rocket';
      case RocketbookSymbol.apple:
        return 'Apple';
    }
  }

  IconData get icon {
    switch (this) {
      case RocketbookSymbol.bell:
        return Icons.notifications;
      case RocketbookSymbol.diamond:
        return Icons.diamond;
      case RocketbookSymbol.star:
        return Icons.star;
      case RocketbookSymbol.clover:
        return Icons.local_florist;
      case RocketbookSymbol.horseshoe:
        return Icons.attractions;
      case RocketbookSymbol.rocket:
        return Icons.rocket_launch;
      case RocketbookSymbol.apple:
        return Icons.apple;
    }
  }
}

/// Configuration for a symbol action
class SymbolAction {
  final RocketbookSymbol symbol;
  final SymbolActionType actionType;
  final String? destination; // Email, cloud service, topic ID, etc.
  final bool enabled;

  SymbolAction({
    required this.symbol,
    required this.actionType,
    this.destination,
    this.enabled = true,
  });

  SymbolAction copyWith({
    RocketbookSymbol? symbol,
    SymbolActionType? actionType,
    String? destination,
    bool? enabled,
  }) {
    return SymbolAction(
      symbol: symbol ?? this.symbol,
      actionType: actionType ?? this.actionType,
      destination: destination ?? this.destination,
      enabled: enabled ?? this.enabled,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'symbol': symbol.name,
      'actionType': actionType.name,
      'destination': destination,
      'enabled': enabled,
    };
  }

  factory SymbolAction.fromJson(Map<String, dynamic> json) {
    return SymbolAction(
      symbol: RocketbookSymbol.values.firstWhere(
        (s) => s.name == json['symbol'],
        orElse: () => RocketbookSymbol.bell,
      ),
      actionType: SymbolActionType.values.firstWhere(
        (t) => t.name == json['actionType'],
        orElse: () => SymbolActionType.none,
      ),
      destination: json['destination'],
      enabled: json['enabled'] ?? true,
    );
  }
}

/// Type of action for symbol
enum SymbolActionType {
  none,
  email,
  googleDrive,
  dropbox,
  evernote,
  slack,
  icloud,
  onedrive,
  assignToTopic,
  createReminder,
  markFavorite,
  archive,
  custom;

  String get displayName {
    switch (this) {
      case SymbolActionType.none:
        return 'No Action';
      case SymbolActionType.email:
        return 'Send to Email';
      case SymbolActionType.googleDrive:
        return 'Google Drive';
      case SymbolActionType.dropbox:
        return 'Dropbox';
      case SymbolActionType.evernote:
        return 'Evernote';
      case SymbolActionType.slack:
        return 'Slack';
      case SymbolActionType.icloud:
        return 'iCloud';
      case SymbolActionType.onedrive:
        return 'OneDrive';
      case SymbolActionType.assignToTopic:
        return 'Assign to Topic';
      case SymbolActionType.createReminder:
        return 'Create Reminder';
      case SymbolActionType.markFavorite:
        return 'Mark as Favorite';
      case SymbolActionType.archive:
        return 'Archive';
      case SymbolActionType.custom:
        return 'Custom Action';
    }
  }

  IconData get icon {
    switch (this) {
      case SymbolActionType.none:
        return Icons.block;
      case SymbolActionType.email:
        return Icons.email;
      case SymbolActionType.googleDrive:
        return Icons.cloud;
      case SymbolActionType.dropbox:
        return Icons.cloud_upload;
      case SymbolActionType.evernote:
        return Icons.note;
      case SymbolActionType.slack:
        return Icons.chat;
      case SymbolActionType.icloud:
        return Icons.cloud_circle;
      case SymbolActionType.onedrive:
        return Icons.cloud_done;
      case SymbolActionType.assignToTopic:
        return Icons.topic;
      case SymbolActionType.createReminder:
        return Icons.alarm;
      case SymbolActionType.markFavorite:
        return Icons.star;
      case SymbolActionType.archive:
        return Icons.archive;
      case SymbolActionType.custom:
        return Icons.settings;
    }
  }
}

/// Default symbol configurations (customizable by user)
class DefaultSymbolConfigs {
  static List<SymbolAction> get defaults => [
        SymbolAction(
          symbol: RocketbookSymbol.bell,
          actionType: SymbolActionType.createReminder,
        ),
        SymbolAction(
          symbol: RocketbookSymbol.diamond,
          actionType: SymbolActionType.archive,
        ),
        SymbolAction(
          symbol: RocketbookSymbol.star,
          actionType: SymbolActionType.markFavorite,
        ),
        SymbolAction(
          symbol: RocketbookSymbol.clover,
          actionType: SymbolActionType.assignToTopic,
          destination: 'personal', // Default topic
        ),
        SymbolAction(
          symbol: RocketbookSymbol.horseshoe,
          actionType: SymbolActionType.assignToTopic,
          destination: 'work', // Default topic
        ),
        SymbolAction(
          symbol: RocketbookSymbol.rocket,
          actionType: SymbolActionType.email,
        ),
        SymbolAction(
          symbol: RocketbookSymbol.apple,
          actionType: SymbolActionType.assignToTopic,
          destination: 'health', // Default topic
        ),
      ];
}
