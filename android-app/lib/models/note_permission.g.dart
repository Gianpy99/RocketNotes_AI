// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'note_permission.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NotePermission _$NotePermissionFromJson(Map<String, dynamic> json) =>
    NotePermission(
      id: json['id'] as String,
      sharedNoteId: json['sharedNoteId'] as String,
      userId: json['userId'] as String,
      familyMemberId: json['familyMemberId'] as String,
      canView: json['canView'] as bool,
      canEdit: json['canEdit'] as bool,
      canComment: json['canComment'] as bool,
      canDelete: json['canDelete'] as bool,
      canShare: json['canShare'] as bool,
      canExport: json['canExport'] as bool,
      canInviteCollaborators: json['canInviteCollaborators'] as bool,
      receiveNotifications: json['receiveNotifications'] as bool,
      grantedAt: NotePermission._dateTimeFromJson(json['grantedAt'] as String),
      grantedBy: json['grantedBy'] as String,
      expiresAt: NotePermission._nullableDateTimeFromJson(
          json['expiresAt'] as String?),
      isActive: json['isActive'] as bool? ?? true,
      lastAccessedAt: NotePermission._nullableDateTimeFromJson(
          json['lastAccessedAt'] as String?),
    );

Map<String, dynamic> _$NotePermissionToJson(NotePermission instance) =>
    <String, dynamic>{
      'id': instance.id,
      'sharedNoteId': instance.sharedNoteId,
      'userId': instance.userId,
      'familyMemberId': instance.familyMemberId,
      'canView': instance.canView,
      'canEdit': instance.canEdit,
      'canComment': instance.canComment,
      'canDelete': instance.canDelete,
      'canShare': instance.canShare,
      'canExport': instance.canExport,
      'canInviteCollaborators': instance.canInviteCollaborators,
      'receiveNotifications': instance.receiveNotifications,
      'grantedAt': NotePermission._dateTimeToJson(instance.grantedAt),
      'grantedBy': instance.grantedBy,
      'expiresAt': NotePermission._nullableDateTimeToJson(instance.expiresAt),
      'isActive': instance.isActive,
      'lastAccessedAt':
          NotePermission._nullableDateTimeToJson(instance.lastAccessedAt),
    };
