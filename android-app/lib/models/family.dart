import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'family.g.dart';

/// Represents a family group that can share notes and collaborate.
@JsonSerializable(explicitToJson: true)
class Family extends Equatable {
  /// Unique identifier (UUID)
  final String id;

  /// Display name for the family
  final String name;

  /// User ID of the family administrator
  final String adminUserId;

  /// When the family was created
  @JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
  final DateTime createdAt;

  /// List of all member user IDs
  final List<String> memberIds;

  /// Family-wide settings and preferences
  final FamilySettings settings;

  /// Last modification timestamp
  @JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
  final DateTime updatedAt;

  const Family({
    required this.id,
    required this.name,
    required this.adminUserId,
    required this.createdAt,
    required this.memberIds,
    required this.settings,
    required this.updatedAt,
  });

  /// Creates a Family instance from JSON
  factory Family.fromJson(Map<String, dynamic> json) => _$FamilyFromJson(json);

  /// Converts Family instance to JSON
  Map<String, dynamic> toJson() => _$FamilyToJson(this);

  /// Creates a copy of Family with modified fields
  Family copyWith({
    String? id,
    String? name,
    String? adminUserId,
    DateTime? createdAt,
    List<String>? memberIds,
    FamilySettings? settings,
    DateTime? updatedAt,
  }) {
    return Family(
      id: id ?? this.id,
      name: name ?? this.name,
      adminUserId: adminUserId ?? this.adminUserId,
      createdAt: createdAt ?? this.createdAt,
      memberIds: memberIds ?? this.memberIds,
      settings: settings ?? this.settings,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        adminUserId,
        createdAt,
        memberIds,
        settings,
        updatedAt,
      ];

  @override
  String toString() {
    return 'Family(id: $id, name: $name, adminUserId: $adminUserId, '
           'memberCount: ${memberIds.length}, createdAt: $createdAt)';
  }

  /// Helper method to convert DateTime to/from JSON
  static DateTime _dateTimeFromJson(String date) => DateTime.parse(date);
  static String _dateTimeToJson(DateTime date) => date.toIso8601String();
}

/// Family-wide configuration settings.
@JsonSerializable(explicitToJson: true)
class FamilySettings extends Equatable {
  /// Whether family members can share notes publicly
  final bool allowPublicSharing;

  /// Whether sharing notes requires approval
  final bool requireApprovalForSharing;

  /// Maximum number of members allowed
  final int maxMembers;

  /// Default expiration time for shared notes
  @JsonKey(fromJson: _durationFromJson, toJson: _durationToJson)
  final Duration defaultNoteExpiration;

  /// Whether real-time synchronization is enabled
  final bool enableRealTimeSync;

  /// Notification preferences for the family
  final NotificationPreferences notifications;

  const FamilySettings({
    required this.allowPublicSharing,
    required this.requireApprovalForSharing,
    required this.maxMembers,
    required this.defaultNoteExpiration,
    required this.enableRealTimeSync,
    required this.notifications,
  });

  /// Creates a FamilySettings instance from JSON
  factory FamilySettings.fromJson(Map<String, dynamic> json) =>
      _$FamilySettingsFromJson(json);

  /// Converts FamilySettings instance to JSON
  Map<String, dynamic> toJson() => _$FamilySettingsToJson(this);

  /// Creates a copy of FamilySettings with modified fields
  FamilySettings copyWith({
    bool? allowPublicSharing,
    bool? requireApprovalForSharing,
    int? maxMembers,
    Duration? defaultNoteExpiration,
    bool? enableRealTimeSync,
    NotificationPreferences? notifications,
  }) {
    return FamilySettings(
      allowPublicSharing: allowPublicSharing ?? this.allowPublicSharing,
      requireApprovalForSharing: requireApprovalForSharing ?? this.requireApprovalForSharing,
      maxMembers: maxMembers ?? this.maxMembers,
      defaultNoteExpiration: defaultNoteExpiration ?? this.defaultNoteExpiration,
      enableRealTimeSync: enableRealTimeSync ?? this.enableRealTimeSync,
      notifications: notifications ?? this.notifications,
    );
  }

  @override
  List<Object?> get props => [
        allowPublicSharing,
        requireApprovalForSharing,
        maxMembers,
        defaultNoteExpiration,
        enableRealTimeSync,
        notifications,
      ];

  /// Helper method to convert Duration to/from JSON
  static Duration _durationFromJson(String duration) {
    // Parse ISO 8601 duration format (e.g., "P30D" for 30 days)
    final regex = RegExp(r'P(\d+)D');
    final match = regex.firstMatch(duration);
    if (match != null) {
      final days = int.parse(match.group(1)!);
      return Duration(days: days);
    }
    return const Duration(days: 30); // Default fallback
  }

  static String _durationToJson(Duration duration) {
    return 'P${duration.inDays}D';
  }
}

/// Notification preferences for the family.
@JsonSerializable(explicitToJson: true)
class NotificationPreferences extends Equatable {
  /// Whether to send email invitations
  final bool emailInvitations;

  /// Whether to send push notifications
  final bool pushNotifications;

  /// Frequency of activity digest emails
  final ActivityDigestFrequency activityDigest;

  const NotificationPreferences({
    required this.emailInvitations,
    required this.pushNotifications,
    required this.activityDigest,
  });

  /// Creates a NotificationPreferences instance from JSON
  factory NotificationPreferences.fromJson(Map<String, dynamic> json) =>
      _$NotificationPreferencesFromJson(json);

  /// Converts NotificationPreferences instance to JSON
  Map<String, dynamic> toJson() => _$NotificationPreferencesToJson(this);

  /// Creates a copy of NotificationPreferences with modified fields
  NotificationPreferences copyWith({
    bool? emailInvitations,
    bool? pushNotifications,
    ActivityDigestFrequency? activityDigest,
  }) {
    return NotificationPreferences(
      emailInvitations: emailInvitations ?? this.emailInvitations,
      pushNotifications: pushNotifications ?? this.pushNotifications,
      activityDigest: activityDigest ?? this.activityDigest,
    );
  }

  @override
  List<Object?> get props => [
        emailInvitations,
        pushNotifications,
        activityDigest,
      ];
}

/// Frequency options for activity digest emails.
enum ActivityDigestFrequency {
  @JsonValue('never')
  never,
  @JsonValue('daily')
  daily,
  @JsonValue('weekly')
  weekly,
}
