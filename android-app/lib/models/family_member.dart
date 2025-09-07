import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'family_member.g.dart';

/// Represents an individual user within a family with specific permissions.
@JsonSerializable()
class FamilyMember extends Equatable {
  /// Reference to the user account
  final String userId;

  /// Reference to the family
  final String familyId;

  /// Role within the family (owner, admin, editor, viewer, limited)
  final FamilyRole role;

  /// Granular permission flags
  final MemberPermissions permissions;

  /// When the user joined the family
  @JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
  final DateTime joinedAt;

  /// Last activity timestamp
  @JsonKey(fromJson: _nullableDateTimeFromJson, toJson: _nullableDateTimeToJson)
  final DateTime? lastActiveAt;

  /// Whether membership is active
  final bool isActive;

  const FamilyMember({
    required this.userId,
    required this.familyId,
    required this.role,
    required this.permissions,
    required this.joinedAt,
    this.lastActiveAt,
    this.isActive = true,
  });

  /// Creates a FamilyMember instance from JSON
  factory FamilyMember.fromJson(Map<String, dynamic> json) =>
      _$FamilyMemberFromJson(json);

  /// Converts FamilyMember instance to JSON
  Map<String, dynamic> toJson() => _$FamilyMemberToJson(this);

  /// Creates a copy of FamilyMember with modified fields
  FamilyMember copyWith({
    String? userId,
    String? familyId,
    FamilyRole? role,
    MemberPermissions? permissions,
    DateTime? joinedAt,
    DateTime? lastActiveAt,
    bool? isActive,
  }) {
    return FamilyMember(
      userId: userId ?? this.userId,
      familyId: familyId ?? this.familyId,
      role: role ?? this.role,
      permissions: permissions ?? this.permissions,
      joinedAt: joinedAt ?? this.joinedAt,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  List<Object?> get props => [
        userId,
        familyId,
        role,
        permissions,
        joinedAt,
        lastActiveAt,
        isActive,
      ];

  @override
  String toString() {
    return 'FamilyMember(userId: $userId, familyId: $familyId, role: $role, '
           'isActive: $isActive, joinedAt: $joinedAt)';
  }

  /// Helper method to convert DateTime to/from JSON
  static DateTime _dateTimeFromJson(String date) => DateTime.parse(date);
  static String _dateTimeToJson(DateTime date) => date.toIso8601String();

  /// Helper method to convert nullable DateTime to/from JSON
  static DateTime? _nullableDateTimeFromJson(String? date) =>
      date != null ? DateTime.parse(date) : null;
  static String? _nullableDateTimeToJson(DateTime? date) =>
      date?.toIso8601String();

  /// Convenience getters for common permission checks
  bool get canInvite => permissions.canInviteMembers;
  bool get canRemove => permissions.canRemoveMembers;
  bool get canShare => permissions.canShareNotes;
  bool get canEdit => permissions.canEditSharedNotes;
  bool get canDelete => permissions.canDeleteSharedNotes;
  bool get canManage => permissions.canManagePermissions;

  /// Check if user has owner-level permissions
  bool get isOwner => role == FamilyRole.owner;

  /// Check if user has admin-level permissions
  bool get isAdmin => role == FamilyRole.owner || role == FamilyRole.admin;

  /// Check if user can modify family settings
  bool get canModifyFamily => isOwner || canManage;

  /// Check if user can manage other members
  bool get canManageMembers => isAdmin || canInvite || canRemove;

  /// Get display name for the role
  String get roleDisplayName {
    switch (role) {
      case FamilyRole.owner:
        return 'Owner';
      case FamilyRole.admin:
        return 'Admin';
      case FamilyRole.editor:
        return 'Editor';
      case FamilyRole.viewer:
        return 'Viewer';
      case FamilyRole.limited:
        return 'Limited';
    }
  }

  /// Create a family owner member
  factory FamilyMember.createOwner({
    required String userId,
    required String familyId,
  }) {
    return FamilyMember(
      userId: userId,
      familyId: familyId,
      role: FamilyRole.owner,
      permissions: MemberPermissions.owner(),
      joinedAt: DateTime.now(),
      isActive: true,
    );
  }

  /// Create a member with default permissions for their role
  factory FamilyMember.createWithRole({
    required String userId,
    required String familyId,
    required FamilyRole role,
  }) {
    return FamilyMember(
      userId: userId,
      familyId: familyId,
      role: role,
      permissions: MemberPermissions.forRole(role),
      joinedAt: DateTime.now(),
      isActive: true,
    );
  }
}

/// Enumeration of possible roles within a family.
enum FamilyRole {
  @JsonValue('owner')
  owner, // Full control, can delete family

  @JsonValue('admin')
  admin, // Can manage members and permissions

  @JsonValue('editor')
  editor, // Can share notes and edit shared content

  @JsonValue('viewer')
  viewer, // Read-only access to shared notes

  @JsonValue('limited')
  limited, // Access only to specific shared notes
}

/// Granular permissions for family members.
@JsonSerializable()
class MemberPermissions extends Equatable {
  /// Whether the member can invite new members
  final bool canInviteMembers;

  /// Whether the member can remove other members
  final bool canRemoveMembers;

  /// Whether the member can share notes with the family
  final bool canShareNotes;

  /// Whether the member can edit shared notes
  final bool canEditSharedNotes;

  /// Whether the member can delete shared notes
  final bool canDeleteSharedNotes;

  /// Whether the member can manage permissions of other members
  final bool canManagePermissions;

  const MemberPermissions({
    required this.canInviteMembers,
    required this.canRemoveMembers,
    required this.canShareNotes,
    required this.canEditSharedNotes,
    required this.canDeleteSharedNotes,
    required this.canManagePermissions,
  });

  /// Creates a MemberPermissions instance from JSON
  factory MemberPermissions.fromJson(Map<String, dynamic> json) =>
      _$MemberPermissionsFromJson(json);

  /// Converts MemberPermissions instance to JSON
  Map<String, dynamic> toJson() => _$MemberPermissionsToJson(this);

  /// Creates a copy of MemberPermissions with modified fields
  MemberPermissions copyWith({
    bool? canInviteMembers,
    bool? canRemoveMembers,
    bool? canShareNotes,
    bool? canEditSharedNotes,
    bool? canDeleteSharedNotes,
    bool? canManagePermissions,
  }) {
    return MemberPermissions(
      canInviteMembers: canInviteMembers ?? this.canInviteMembers,
      canRemoveMembers: canRemoveMembers ?? this.canRemoveMembers,
      canShareNotes: canShareNotes ?? this.canShareNotes,
      canEditSharedNotes: canEditSharedNotes ?? this.canEditSharedNotes,
      canDeleteSharedNotes: canDeleteSharedNotes ?? this.canDeleteSharedNotes,
      canManagePermissions: canManagePermissions ?? this.canManagePermissions,
    );
  }

  @override
  List<Object?> get props => [
        canInviteMembers,
        canRemoveMembers,
        canShareNotes,
        canEditSharedNotes,
        canDeleteSharedNotes,
        canManagePermissions,
      ];

  @override
  String toString() {
    return 'MemberPermissions(invite: $canInviteMembers, remove: $canRemoveMembers, '
           'share: $canShareNotes, edit: $canEditSharedNotes, delete: $canDeleteSharedNotes, '
           'manage: $canManagePermissions)';
  }

  /// Create owner permissions (all permissions)
  factory MemberPermissions.owner() {
    return const MemberPermissions(
      canInviteMembers: true,
      canRemoveMembers: true,
      canShareNotes: true,
      canEditSharedNotes: true,
      canDeleteSharedNotes: true,
      canManagePermissions: true,
    );
  }

  /// Create admin permissions (most permissions except deleting family)
  factory MemberPermissions.admin() {
    return const MemberPermissions(
      canInviteMembers: true,
      canRemoveMembers: true,
      canShareNotes: true,
      canEditSharedNotes: true,
      canDeleteSharedNotes: true,
      canManagePermissions: true,
    );
  }

  /// Create editor permissions (can share and edit)
  factory MemberPermissions.editor() {
    return const MemberPermissions(
      canInviteMembers: false,
      canRemoveMembers: false,
      canShareNotes: true,
      canEditSharedNotes: true,
      canDeleteSharedNotes: false,
      canManagePermissions: false,
    );
  }

  /// Create viewer permissions (read-only)
  factory MemberPermissions.viewer() {
    return const MemberPermissions(
      canInviteMembers: false,
      canRemoveMembers: false,
      canShareNotes: false,
      canEditSharedNotes: false,
      canDeleteSharedNotes: false,
      canManagePermissions: false,
    );
  }

  /// Create limited permissions (minimal access)
  factory MemberPermissions.limited() {
    return const MemberPermissions(
      canInviteMembers: false,
      canRemoveMembers: false,
      canShareNotes: false,
      canEditSharedNotes: false,
      canDeleteSharedNotes: false,
      canManagePermissions: false,
    );
  }

  /// Create permissions based on role
  factory MemberPermissions.forRole(FamilyRole role) {
    switch (role) {
      case FamilyRole.owner:
        return MemberPermissions.owner();
      case FamilyRole.admin:
        return MemberPermissions.admin();
      case FamilyRole.editor:
        return MemberPermissions.editor();
      case FamilyRole.viewer:
        return MemberPermissions.viewer();
      case FamilyRole.limited:
        return MemberPermissions.limited();
    }
  }

  /// Check if this permission set has administrative capabilities
  bool get hasAdminCapabilities =>
      canInviteMembers || canRemoveMembers || canManagePermissions;

  /// Check if this permission set allows content modification
  bool get canModifyContent => canEditSharedNotes || canDeleteSharedNotes;

  /// Check if this permission set allows any sharing capabilities
  bool get canShareContent => canShareNotes || canEditSharedNotes;
}
