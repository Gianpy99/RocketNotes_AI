// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'family_invitation.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FamilyInvitation _$FamilyInvitationFromJson(Map<String, dynamic> json) =>
    FamilyInvitation(
      id: json['id'] as String,
      familyId: json['familyId'] as String,
      email: json['email'] as String,
      role: $enumDecode(_$FamilyRoleEnumMap, json['role']),
      permissions: MemberPermissions.fromJson(
          json['permissions'] as Map<String, dynamic>),
      invitedBy: json['invitedBy'] as String,
      createdAt:
          FamilyInvitation._dateTimeFromJson(json['createdAt'] as String),
      expiresAt:
          FamilyInvitation._dateTimeFromJson(json['expiresAt'] as String),
      status: $enumDecodeNullable(_$InvitationStatusEnumMap, json['status']) ??
          InvitationStatus.pending,
      acceptedAt: FamilyInvitation._nullableDateTimeFromJson(
          json['acceptedAt'] as String?),
      rejectedAt: FamilyInvitation._nullableDateTimeFromJson(
          json['rejectedAt'] as String?),
      respondedBy: json['respondedBy'] as String?,
      message: json['message'] as String?,
      sendCount: (json['sendCount'] as num?)?.toInt() ?? 1,
      lastSentAt: FamilyInvitation._nullableDateTimeFromJson(
          json['lastSentAt'] as String?),
      sentViaEmail: json['sentViaEmail'] as bool? ?? true,
      sentViaPush: json['sentViaPush'] as bool? ?? false,
      invitationToken: json['invitationToken'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>? ?? const {},
    );

Map<String, dynamic> _$FamilyInvitationToJson(FamilyInvitation instance) =>
    <String, dynamic>{
      'id': instance.id,
      'familyId': instance.familyId,
      'email': instance.email,
      'role': _$FamilyRoleEnumMap[instance.role]!,
      'permissions': instance.permissions,
      'invitedBy': instance.invitedBy,
      'createdAt': FamilyInvitation._dateTimeToJson(instance.createdAt),
      'expiresAt': FamilyInvitation._dateTimeToJson(instance.expiresAt),
      'status': _$InvitationStatusEnumMap[instance.status]!,
      'acceptedAt':
          FamilyInvitation._nullableDateTimeToJson(instance.acceptedAt),
      'rejectedAt':
          FamilyInvitation._nullableDateTimeToJson(instance.rejectedAt),
      'respondedBy': instance.respondedBy,
      'message': instance.message,
      'sendCount': instance.sendCount,
      'lastSentAt':
          FamilyInvitation._nullableDateTimeToJson(instance.lastSentAt),
      'sentViaEmail': instance.sentViaEmail,
      'sentViaPush': instance.sentViaPush,
      'invitationToken': instance.invitationToken,
      'metadata': instance.metadata,
    };

const _$FamilyRoleEnumMap = {
  FamilyRole.owner: 'owner',
  FamilyRole.admin: 'admin',
  FamilyRole.editor: 'editor',
  FamilyRole.viewer: 'viewer',
  FamilyRole.limited: 'limited',
};

const _$InvitationStatusEnumMap = {
  InvitationStatus.pending: 'pending',
  InvitationStatus.accepted: 'accepted',
  InvitationStatus.rejected: 'rejected',
  InvitationStatus.expired: 'expired',
  InvitationStatus.cancelled: 'cancelled',
};
