import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'note_permission.g.dart';

/// Represents the permissions granted to a family member for a specific shared note.
///
/// This model defines granular permissions for note access, editing, and collaboration
/// within the family sharing system.
@JsonSerializable()
class NotePermission extends Equatable {
  /// Unique identifier for this permission instance
  final String id;

  /// ID of the shared note these permissions apply to
  final String sharedNoteId;

  /// ID of the user these permissions are granted to
  final String userId;

  /// ID of the family member record
  final String familyMemberId;

  /// Whether the user can view the note
  final bool canView;

  /// Whether the user can edit the note content
  final bool canEdit;

  /// Whether the user can comment on the note
  final bool canComment;

  /// Whether the user can delete the note (their own comments or the entire note if owner)
  final bool canDelete;

  /// Whether the user can share the note with others
  final bool canShare;

  /// Whether the user can export the note
  final bool canExport;

  /// Whether the user can invite others to collaborate
  final bool canInviteCollaborators;

  /// Whether the user receives notifications about note changes
  final bool receiveNotifications;

  /// When these permissions were granted
  @JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
  final DateTime grantedAt;

  /// ID of the user who granted these permissions
  final String grantedBy;

  /// Optional expiration date for these permissions
  @JsonKey(fromJson: _nullableDateTimeFromJson, toJson: _nullableDateTimeToJson)
  final DateTime? expiresAt;

  /// Whether these permissions are currently active
  final bool isActive;

  /// Last time these permissions were used/accessed
  @JsonKey(fromJson: _nullableDateTimeFromJson, toJson: _nullableDateTimeToJson)
  final DateTime? lastAccessedAt;

  const NotePermission({
    required this.id,
    required this.sharedNoteId,
    required this.userId,
    required this.familyMemberId,
    required this.canView,
    required this.canEdit,
    required this.canComment,
    required this.canDelete,
    required this.canShare,
    required this.canExport,
    required this.canInviteCollaborators,
    required this.receiveNotifications,
    required this.grantedAt,
    required this.grantedBy,
    this.expiresAt,
    this.isActive = true,
    this.lastAccessedAt,
  });

  /// Creates a NotePermission instance from JSON
  factory NotePermission.fromJson(Map<String, dynamic> json) =>
      _$NotePermissionFromJson(json);

  /// Converts NotePermission instance to JSON
  Map<String, dynamic> toJson() => _$NotePermissionToJson(this);

  /// Creates a copy of NotePermission with modified fields
  NotePermission copyWith({
    String? id,
    String? sharedNoteId,
    String? userId,
    String? familyMemberId,
    bool? canView,
    bool? canEdit,
    bool? canComment,
    bool? canDelete,
    bool? canShare,
    bool? canExport,
    bool? canInviteCollaborators,
    bool? receiveNotifications,
    DateTime? grantedAt,
    String? grantedBy,
    DateTime? expiresAt,
    bool? isActive,
    DateTime? lastAccessedAt,
  }) {
    return NotePermission(
      id: id ?? this.id,
      sharedNoteId: sharedNoteId ?? this.sharedNoteId,
      userId: userId ?? this.userId,
      familyMemberId: familyMemberId ?? this.familyMemberId,
      canView: canView ?? this.canView,
      canEdit: canEdit ?? this.canEdit,
      canComment: canComment ?? this.canComment,
      canDelete: canDelete ?? this.canDelete,
      canShare: canShare ?? this.canShare,
      canExport: canExport ?? this.canExport,
      canInviteCollaborators: canInviteCollaborators ?? this.canInviteCollaborators,
      receiveNotifications: receiveNotifications ?? this.receiveNotifications,
      grantedAt: grantedAt ?? this.grantedAt,
      grantedBy: grantedBy ?? this.grantedBy,
      expiresAt: expiresAt ?? this.expiresAt,
      isActive: isActive ?? this.isActive,
      lastAccessedAt: lastAccessedAt ?? this.lastAccessedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        sharedNoteId,
        userId,
        familyMemberId,
        canView,
        canEdit,
        canComment,
        canDelete,
        canShare,
        canExport,
        canInviteCollaborators,
        receiveNotifications,
        grantedAt,
        grantedBy,
        expiresAt,
        isActive,
        lastAccessedAt,
      ];

  @override
  String toString() {
    return 'NotePermission(id: $id, sharedNoteId: $sharedNoteId, userId: $userId, '
           'canView: $canView, canEdit: $canEdit, canComment: $canComment, '
           'isActive: $isActive, grantedAt: $grantedAt)';
  }

  /// Check if permissions have expired
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  /// Check if permissions are effectively active (active and not expired)
  bool get isEffectivelyActive => isActive && !isExpired;

  /// Get permission level as a string for display
  String get permissionLevel {
    if (canEdit && canShare && canInviteCollaborators) return 'Full Access';
    if (canEdit && canComment) return 'Editor';
    if (canComment) return 'Commenter';
    if (canView) return 'Viewer';
    return 'No Access';
  }

  /// Create read-only permissions
  factory NotePermission.readOnly({
    required String id,
    required String sharedNoteId,
    required String userId,
    required String familyMemberId,
    required String grantedBy,
  }) {
    return NotePermission(
      id: id,
      sharedNoteId: sharedNoteId,
      userId: userId,
      familyMemberId: familyMemberId,
      canView: true,
      canEdit: false,
      canComment: false,
      canDelete: false,
      canShare: false,
      canExport: false,
      canInviteCollaborators: false,
      receiveNotifications: true,
      grantedAt: DateTime.now(),
      grantedBy: grantedBy,
    );
  }

  /// Create editor permissions
  factory NotePermission.editor({
    required String id,
    required String sharedNoteId,
    required String userId,
    required String familyMemberId,
    required String grantedBy,
  }) {
    return NotePermission(
      id: id,
      sharedNoteId: sharedNoteId,
      userId: userId,
      familyMemberId: familyMemberId,
      canView: true,
      canEdit: true,
      canComment: true,
      canDelete: false,
      canShare: false,
      canExport: false,
      canInviteCollaborators: false,
      receiveNotifications: true,
      grantedAt: DateTime.now(),
      grantedBy: grantedBy,
    );
  }

  /// Create full access permissions (for note owner)
  factory NotePermission.fullAccess({
    required String id,
    required String sharedNoteId,
    required String userId,
    required String familyMemberId,
    required String grantedBy,
  }) {
    return NotePermission(
      id: id,
      sharedNoteId: sharedNoteId,
      userId: userId,
      familyMemberId: familyMemberId,
      canView: true,
      canEdit: true,
      canComment: true,
      canDelete: true,
      canShare: true,
      canExport: true,
      canInviteCollaborators: true,
      receiveNotifications: true,
      grantedAt: DateTime.now(),
      grantedBy: grantedBy,
    );
  }

  /// Helper method to convert DateTime to/from JSON
  static DateTime _dateTimeFromJson(String date) => DateTime.parse(date);
  static String _dateTimeToJson(DateTime date) => date.toIso8601String();

  /// Helper method to convert nullable DateTime to/from JSON
  static DateTime? _nullableDateTimeFromJson(String? date) =>
      date != null ? DateTime.parse(date) : null;
  static String? _nullableDateTimeToJson(DateTime? date) =>
      date?.toIso8601String();
}
