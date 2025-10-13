// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'family_member.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FamilyMember _$FamilyMemberFromJson(Map<String, dynamic> json) => FamilyMember(
      userId: json['userId'] as String,
      familyId: json['familyId'] as String,
      role: $enumDecode(_$FamilyRoleEnumMap, json['role']),
      permissions: MemberPermissions.fromJson(
          json['permissions'] as Map<String, dynamic>),
      joinedAt: FamilyMember._dateTimeFromJson(json['joinedAt'] as String),
      lastActiveAt: FamilyMember._nullableDateTimeFromJson(
          json['lastActiveAt'] as String?),
      isActive: json['isActive'] as bool? ?? true,
      name: json['name'] as String?,
      avatarPath: json['avatarPath'] as String?,
      relationship: json['relationship'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      isEmergencyContact: json['isEmergencyContact'] as bool? ?? false,
    );

Map<String, dynamic> _$FamilyMemberToJson(FamilyMember instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'familyId': instance.familyId,
      'role': _$FamilyRoleEnumMap[instance.role]!,
      'permissions': instance.permissions.toJson(),
      'joinedAt': FamilyMember._dateTimeToJson(instance.joinedAt),
      'lastActiveAt':
          FamilyMember._nullableDateTimeToJson(instance.lastActiveAt),
      'isActive': instance.isActive,
      'name': instance.name,
      'avatarPath': instance.avatarPath,
      'relationship': instance.relationship,
      'phoneNumber': instance.phoneNumber,
      'isEmergencyContact': instance.isEmergencyContact,
    };

const _$FamilyRoleEnumMap = {
  FamilyRole.owner: 'owner',
  FamilyRole.admin: 'admin',
  FamilyRole.editor: 'editor',
  FamilyRole.viewer: 'viewer',
  FamilyRole.limited: 'limited',
};

MemberPermissions _$MemberPermissionsFromJson(Map<String, dynamic> json) =>
    MemberPermissions(
      canInviteMembers: json['canInviteMembers'] as bool,
      canRemoveMembers: json['canRemoveMembers'] as bool,
      canShareNotes: json['canShareNotes'] as bool,
      canEditSharedNotes: json['canEditSharedNotes'] as bool,
      canDeleteSharedNotes: json['canDeleteSharedNotes'] as bool,
      canManagePermissions: json['canManagePermissions'] as bool,
    );

Map<String, dynamic> _$MemberPermissionsToJson(MemberPermissions instance) =>
    <String, dynamic>{
      'canInviteMembers': instance.canInviteMembers,
      'canRemoveMembers': instance.canRemoveMembers,
      'canShareNotes': instance.canShareNotes,
      'canEditSharedNotes': instance.canEditSharedNotes,
      'canDeleteSharedNotes': instance.canDeleteSharedNotes,
      'canManagePermissions': instance.canManagePermissions,
    };
