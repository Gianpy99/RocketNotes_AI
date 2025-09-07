import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'note_permission.dart';

part 'shared_note.g.dart';

/// Represents a note that has been shared within a family.
///
/// This model tracks the sharing relationship between a note and family members,
/// including permissions, sharing metadata, and collaboration state.
@JsonSerializable()
class SharedNote extends Equatable {
  /// Unique identifier for this shared note instance
  final String id;

  /// ID of the original note being shared
  final String noteId;

  /// ID of the family this note is shared with
  final String familyId;

  /// ID of the user who shared the note
  final String sharedBy;

  /// When the note was shared
  @JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
  final DateTime sharedAt;

  /// Title of the shared note (may differ from original)
  final String title;

  /// Optional description of why the note was shared
  final String? description;

  /// Current sharing permissions
  final NotePermission permission;

  /// Whether sharing requires approval from family owner
  final bool requiresApproval;

  /// Current approval status
  final SharingStatus status;

  /// ID of user who approved/rejected (if applicable)
  final String? approvedBy;

  /// When approval decision was made
  @JsonKey(fromJson: _nullableDateTimeFromJson, toJson: _nullableDateTimeToJson)
  final DateTime? approvedAt;

  /// Optional expiration date for sharing
  @JsonKey(fromJson: _nullableDateTimeFromJson, toJson: _nullableDateTimeToJson)
  final DateTime? expiresAt;

  /// Whether real-time collaboration is enabled
  final bool allowCollaboration;

  /// Current collaboration session ID (if active)
  final String? collaborationSessionId;

  /// List of user IDs currently viewing the note
  final List<String> activeViewers;

  /// Last modification timestamp
  @JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
  final DateTime updatedAt;

  /// Version number for conflict resolution
  final int version;

  const SharedNote({
    required this.id,
    required this.noteId,
    required this.familyId,
    required this.sharedBy,
    required this.sharedAt,
    required this.title,
    required this.permission,
    this.description,
    this.requiresApproval = false,
    this.status = SharingStatus.pending,
    this.approvedBy,
    this.approvedAt,
    this.expiresAt,
    this.allowCollaboration = false,
    this.collaborationSessionId,
    this.activeViewers = const [],
    required this.updatedAt,
    this.version = 1,
  });

  /// Creates a SharedNote instance from JSON
  factory SharedNote.fromJson(Map<String, dynamic> json) =>
      _$SharedNoteFromJson(json);

  /// Converts SharedNote instance to JSON
  Map<String, dynamic> toJson() => _$SharedNoteToJson(this);

  /// Creates a copy of SharedNote with modified fields
  SharedNote copyWith({
    String? id,
    String? noteId,
    String? familyId,
    String? sharedBy,
    DateTime? sharedAt,
    String? title,
    String? description,
    NotePermission? permission,
    bool? requiresApproval,
    SharingStatus? status,
    String? approvedBy,
    DateTime? approvedAt,
    DateTime? expiresAt,
    bool? allowCollaboration,
    String? collaborationSessionId,
    List<String>? activeViewers,
    DateTime? updatedAt,
    int? version,
  }) {
    return SharedNote(
      id: id ?? this.id,
      noteId: noteId ?? this.noteId,
      familyId: familyId ?? this.familyId,
      sharedBy: sharedBy ?? this.sharedBy,
      sharedAt: sharedAt ?? this.sharedAt,
      title: title ?? this.title,
      description: description ?? this.description,
      permission: permission ?? this.permission,
      requiresApproval: requiresApproval ?? this.requiresApproval,
      status: status ?? this.status,
      approvedBy: approvedBy ?? this.approvedBy,
      approvedAt: approvedAt ?? this.approvedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      allowCollaboration: allowCollaboration ?? this.allowCollaboration,
      collaborationSessionId: collaborationSessionId ?? this.collaborationSessionId,
      activeViewers: activeViewers ?? this.activeViewers,
      updatedAt: updatedAt ?? this.updatedAt,
      version: version ?? this.version,
    );
  }

  @override
  List<Object?> get props => [
        id,
        noteId,
        familyId,
        sharedBy,
        sharedAt,
        title,
        description,
        permission,
        requiresApproval,
        status,
        approvedBy,
        approvedAt,
        expiresAt,
        allowCollaboration,
        collaborationSessionId,
        activeViewers,
        updatedAt,
        version,
      ];

  @override
  String toString() {
    return 'SharedNote(id: $id, noteId: $noteId, familyId: $familyId, '
           'title: $title, status: $status, sharedBy: $sharedBy, '
           'sharedAt: $sharedAt, version: $version)';
  }

  /// Check if the sharing has expired
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  /// Check if collaboration is currently active
  bool get isCollaborationActive => collaborationSessionId != null;

  /// Check if the note is currently being viewed by anyone
  bool get hasActiveViewers => activeViewers.isNotEmpty;

  /// Get the number of active viewers
  int get viewerCount => activeViewers.length;

  /// Helper method to convert DateTime to/from JSON
  static DateTime _dateTimeFromJson(String date) => DateTime.parse(date);
  static String _dateTimeToJson(DateTime date) => date.toIso8601String();

  /// Helper method to convert nullable DateTime to/from JSON
  static DateTime? _nullableDateTimeFromJson(String? date) =>
      date != null ? DateTime.parse(date) : null;
  static String? _nullableDateTimeToJson(DateTime? date) =>
      date?.toIso8601String();
}

/// Status of a shared note
enum SharingStatus {
  /// Waiting for approval from family owner/admin
  pending,

  /// Approved and actively shared
  approved,

  /// Rejected by family owner/admin
  rejected,

  /// Sharing has expired
  expired,

  /// Sharing was revoked by the sharer
  revoked,
}

/// Extension methods for SharingStatus
extension SharingStatusExtension on SharingStatus {
  String get displayName {
    switch (this) {
      case SharingStatus.pending:
        return 'Pending Approval';
      case SharingStatus.approved:
        return 'Shared';
      case SharingStatus.rejected:
        return 'Rejected';
      case SharingStatus.expired:
        return 'Expired';
      case SharingStatus.revoked:
        return 'Revoked';
    }
  }

  bool get isActive => this == SharingStatus.approved;
  bool get isPending => this == SharingStatus.pending;
  bool get isInactive => !isActive && !isPending;
}
