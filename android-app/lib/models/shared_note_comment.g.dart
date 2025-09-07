// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shared_note_comment.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SharedNoteComment _$SharedNoteCommentFromJson(Map<String, dynamic> json) =>
    SharedNoteComment(
      id: json['id'] as String,
      sharedNoteId: json['sharedNoteId'] as String,
      userId: json['userId'] as String,
      userDisplayName: json['userDisplayName'] as String,
      content: json['content'] as String,
      createdAt:
          SharedNoteComment._dateTimeFromJson(json['createdAt'] as String),
      updatedAt: SharedNoteComment._nullableDateTimeFromJson(
          json['updatedAt'] as String?),
      isEdited: json['isEdited'] as bool? ?? false,
      parentCommentId: json['parentCommentId'] as String?,
      likedBy: (json['likedBy'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      replies: (json['replies'] as List<dynamic>?)
              ?.map(
                  (e) => SharedNoteComment.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$SharedNoteCommentToJson(SharedNoteComment instance) =>
    <String, dynamic>{
      'id': instance.id,
      'sharedNoteId': instance.sharedNoteId,
      'userId': instance.userId,
      'userDisplayName': instance.userDisplayName,
      'content': instance.content,
      'createdAt': SharedNoteComment._dateTimeToJson(instance.createdAt),
      'updatedAt':
          SharedNoteComment._nullableDateTimeToJson(instance.updatedAt),
      'isEdited': instance.isEdited,
      'parentCommentId': instance.parentCommentId,
      'likedBy': instance.likedBy,
      'replies': instance.replies,
    };
