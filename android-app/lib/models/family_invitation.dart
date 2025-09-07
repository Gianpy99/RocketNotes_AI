import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'family_member.dart';

part 'family_invitation.g.dart';

/// Represents an invitation sent to a user to join a family.
///
/// This model tracks the invitation lifecycle from creation to acceptance/rejection,
/// including expiration, permissions, and audit information.
@JsonSerializable()
class FamilyInvitation extends Equatable {
  /// Unique identifier for this invitation
  final String id;

  /// ID of the family the user is being invited to
  final String familyId;

  /// Email address of the invited user
  final String email;

  /// Role the user will have if they accept
  final FamilyRole role;

  /// Permissions the user will have if they accept
  final MemberPermissions permissions;

  /// ID of the user who sent the invitation
  final String invitedBy;

  /// When the invitation was created
  @JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
  final DateTime createdAt;

  /// When the invitation expires
  @JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
  final DateTime expiresAt;

  /// Current status of the invitation
  final InvitationStatus status;

  /// When the invitation was accepted (if applicable)
  @JsonKey(fromJson: _nullableDateTimeFromJson, toJson: _nullableDateTimeToJson)
  final DateTime? acceptedAt;

  /// When the invitation was rejected (if applicable)
  @JsonKey(fromJson: _nullableDateTimeFromJson, toJson: _nullableDateTimeToJson)
  final DateTime? rejectedAt;

  /// ID of the user who accepted/rejected (if applicable)
  final String? respondedBy;

  /// Optional message from the inviter
  final String? message;

  /// Number of times the invitation has been sent
  final int sendCount;

  /// When the invitation was last sent
  @JsonKey(fromJson: _nullableDateTimeFromJson, toJson: _nullableDateTimeToJson)
  final DateTime? lastSentAt;

  /// Whether this invitation was sent via email
  final bool sentViaEmail;

  /// Whether this invitation was sent via push notification
  final bool sentViaPush;

  /// Optional invitation token for secure acceptance
  final String? invitationToken;

  /// Additional metadata for the invitation
  final Map<String, dynamic> metadata;

  const FamilyInvitation({
    required this.id,
    required this.familyId,
    required this.email,
    required this.role,
    required this.permissions,
    required this.invitedBy,
    required this.createdAt,
    required this.expiresAt,
    this.status = InvitationStatus.pending,
    this.acceptedAt,
    this.rejectedAt,
    this.respondedBy,
    this.message,
    this.sendCount = 1,
    this.lastSentAt,
    this.sentViaEmail = true,
    this.sentViaPush = false,
    this.invitationToken,
    this.metadata = const {},
  });

  /// Creates a FamilyInvitation instance from JSON
  factory FamilyInvitation.fromJson(Map<String, dynamic> json) =>
      _$FamilyInvitationFromJson(json);

  /// Converts FamilyInvitation instance to JSON
  Map<String, dynamic> toJson() => _$FamilyInvitationToJson(this);

  /// Creates a copy of FamilyInvitation with modified fields
  FamilyInvitation copyWith({
    String? id,
    String? familyId,
    String? email,
    FamilyRole? role,
    MemberPermissions? permissions,
    String? invitedBy,
    DateTime? createdAt,
    DateTime? expiresAt,
    InvitationStatus? status,
    DateTime? acceptedAt,
    DateTime? rejectedAt,
    String? respondedBy,
    String? message,
    int? sendCount,
    DateTime? lastSentAt,
    bool? sentViaEmail,
    bool? sentViaPush,
    String? invitationToken,
    Map<String, dynamic>? metadata,
  }) {
    return FamilyInvitation(
      id: id ?? this.id,
      familyId: familyId ?? this.familyId,
      email: email ?? this.email,
      role: role ?? this.role,
      permissions: permissions ?? this.permissions,
      invitedBy: invitedBy ?? this.invitedBy,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      status: status ?? this.status,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      rejectedAt: rejectedAt ?? this.rejectedAt,
      respondedBy: respondedBy ?? this.respondedBy,
      message: message ?? this.message,
      sendCount: sendCount ?? this.sendCount,
      lastSentAt: lastSentAt ?? this.lastSentAt,
      sentViaEmail: sentViaEmail ?? this.sentViaEmail,
      sentViaPush: sentViaPush ?? this.sentViaPush,
      invitationToken: invitationToken ?? this.invitationToken,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  List<Object?> get props => [
        id,
        familyId,
        email,
        role,
        permissions,
        invitedBy,
        createdAt,
        expiresAt,
        status,
        acceptedAt,
        rejectedAt,
        respondedBy,
        message,
        sendCount,
        lastSentAt,
        sentViaEmail,
        sentViaPush,
        invitationToken,
        metadata,
      ];

  @override
  String toString() {
    return 'FamilyInvitation(id: $id, familyId: $familyId, email: $email, '
           'role: $role, status: $status, invitedBy: $invitedBy, '
           'createdAt: $createdAt, expiresAt: $expiresAt)';
  }

  /// Check if the invitation has expired
  bool get isExpired {
    return DateTime.now().isAfter(expiresAt);
  }

  /// Check if the invitation is still valid (pending and not expired)
  bool get isValid {
    return status == InvitationStatus.pending && !isExpired;
  }

  /// Check if the invitation was accepted
  bool get isAccepted => status == InvitationStatus.accepted;

  /// Check if the invitation was rejected
  bool get isRejected => status == InvitationStatus.rejected;

  /// Check if the invitation is pending
  bool get isPending => status == InvitationStatus.pending;

  /// Get the time remaining before expiration
  Duration get timeRemaining {
    final now = DateTime.now();
    if (now.isAfter(expiresAt)) return Duration.zero;
    return expiresAt.difference(now);
  }

  /// Get days remaining before expiration
  int get daysRemaining => timeRemaining.inDays;

  /// Check if invitation is expiring soon (within 24 hours)
  bool get isExpiringSoon => timeRemaining.inHours < 24 && timeRemaining.inHours > 0;

  /// Create a new invitation with updated send information
  FamilyInvitation markAsSent({
    bool viaEmail = true,
    bool viaPush = false,
  }) {
    return copyWith(
      sendCount: sendCount + 1,
      lastSentAt: DateTime.now(),
      sentViaEmail: sentViaEmail || viaEmail,
      sentViaPush: sentViaPush || viaPush,
    );
  }

  /// Accept the invitation
  FamilyInvitation accept({required String userId}) {
    return copyWith(
      status: InvitationStatus.accepted,
      acceptedAt: DateTime.now(),
      respondedBy: userId,
    );
  }

  /// Reject the invitation
  FamilyInvitation reject({required String userId}) {
    return copyWith(
      status: InvitationStatus.rejected,
      rejectedAt: DateTime.now(),
      respondedBy: userId,
    );
  }

  /// Mark the invitation as expired
  FamilyInvitation expire() {
    return copyWith(
      status: InvitationStatus.expired,
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

/// Status of a family invitation
enum InvitationStatus {
  /// Invitation sent but not yet responded to
  pending,

  /// Invitation accepted by the recipient
  accepted,

  /// Invitation rejected by the recipient
  rejected,

  /// Invitation expired before response
  expired,

  /// Invitation cancelled by the sender
  cancelled,
}

/// Extension methods for InvitationStatus
extension InvitationStatusExtension on InvitationStatus {
  String get displayName {
    switch (this) {
      case InvitationStatus.pending:
        return 'Pending';
      case InvitationStatus.accepted:
        return 'Accepted';
      case InvitationStatus.rejected:
        return 'Rejected';
      case InvitationStatus.expired:
        return 'Expired';
      case InvitationStatus.cancelled:
        return 'Cancelled';
    }
  }

  bool get isActive => this == InvitationStatus.pending;
  bool get isFinal => this != InvitationStatus.pending;
  bool get isSuccessful => this == InvitationStatus.accepted;
}
