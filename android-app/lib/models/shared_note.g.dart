// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shared_note.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SharedNote _$SharedNoteFromJson(Map<String, dynamic> json) => SharedNote(
      id: json['id'] as String,
      noteId: json['noteId'] as String,
      familyId: json['familyId'] as String,
      sharedBy: json['sharedBy'] as String,
      sharedAt: SharedNote._dateTimeFromJson(json['sharedAt'] as String),
      title: json['title'] as String,
      permission:
          NotePermission.fromJson(json['permission'] as Map<String, dynamic>),
      description: json['description'] as String?,
      requiresApproval: json['requiresApproval'] as bool? ?? false,
      status: $enumDecodeNullable(_$SharingStatusEnumMap, json['status']) ??
          SharingStatus.pending,
      approvedBy: json['approvedBy'] as String?,
      approvedAt:
          SharedNote._nullableDateTimeFromJson(json['approvedAt'] as String?),
      expiresAt:
          SharedNote._nullableDateTimeFromJson(json['expiresAt'] as String?),
      allowCollaboration: json['allowCollaboration'] as bool? ?? false,
      collaborationSessionId: json['collaborationSessionId'] as String?,
      activeViewers: (json['activeViewers'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      updatedAt: SharedNote._dateTimeFromJson(json['updatedAt'] as String),
      version: (json['version'] as num?)?.toInt() ?? 1,
    );

Map<String, dynamic> _$SharedNoteToJson(SharedNote instance) =>
    <String, dynamic>{
      'id': instance.id,
      'noteId': instance.noteId,
      'familyId': instance.familyId,
      'sharedBy': instance.sharedBy,
      'sharedAt': SharedNote._dateTimeToJson(instance.sharedAt),
      'title': instance.title,
      'description': instance.description,
      'permission': instance.permission,
      'requiresApproval': instance.requiresApproval,
      'status': _$SharingStatusEnumMap[instance.status]!,
      'approvedBy': instance.approvedBy,
      'approvedAt': SharedNote._nullableDateTimeToJson(instance.approvedAt),
      'expiresAt': SharedNote._nullableDateTimeToJson(instance.expiresAt),
      'allowCollaboration': instance.allowCollaboration,
      'collaborationSessionId': instance.collaborationSessionId,
      'activeViewers': instance.activeViewers,
      'updatedAt': SharedNote._dateTimeToJson(instance.updatedAt),
      'version': instance.version,
    };

const _$SharingStatusEnumMap = {
  SharingStatus.pending: 'pending',
  SharingStatus.approved: 'approved',
  SharingStatus.rejected: 'rejected',
  SharingStatus.expired: 'expired',
  SharingStatus.revoked: 'revoked',
};
