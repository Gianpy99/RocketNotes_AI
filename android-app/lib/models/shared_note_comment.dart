import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'shared_note_comment.g.dart';

/// Represents a comment on a shared note
@JsonSerializable()
class SharedNoteComment extends Equatable {
  /// Unique identifier for this comment
  final String id;

  /// ID of the shared note this comment belongs to
  final String sharedNoteId;

  /// ID of the user who made the comment
  final String userId;

  /// Display name of the user who made the comment
  final String userDisplayName;

  /// Comment content
  final String content;

  /// When the comment was created
  @JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
  final DateTime createdAt;

  /// When the comment was last updated (for edits)
  @JsonKey(fromJson: _nullableDateTimeFromJson, toJson: _nullableDateTimeToJson)
  final DateTime? updatedAt;

  /// Whether this comment has been soft deleted
  final bool isDeleted;

  /// When the comment was soft deleted (for recovery)
  @JsonKey(fromJson: _nullableDateTimeFromJson, toJson: _nullableDateTimeToJson)
  final DateTime? deletedAt;

  /// Whether this comment has been edited
  final bool isEdited;

  /// ID of parent comment (for threaded comments)
  final String? parentCommentId;

  /// List of user IDs who liked this comment
  final List<String> likedBy;

  /// Replies to this comment (for threaded comments)
  final List<SharedNoteComment> replies;

  /// Number of likes
  int get likeCount => likedBy.length;

  const SharedNoteComment({
    required this.id,
    required this.sharedNoteId,
    required this.userId,
    required this.userDisplayName,
    required this.content,
    required this.createdAt,
    this.updatedAt,
    this.isEdited = false,
    this.parentCommentId,
    this.likedBy = const [],
    this.replies = const [],
    this.isDeleted = false,
    this.deletedAt,
  });

  /// Creates a SharedNoteComment instance from JSON
  factory SharedNoteComment.fromJson(Map<String, dynamic> json) =>
      _$SharedNoteCommentFromJson(json);

  /// Converts SharedNoteComment instance to JSON
  Map<String, dynamic> toJson() => _$SharedNoteCommentToJson(this);

  /// Creates a copy of SharedNoteComment with modified fields
  SharedNoteComment copyWith({
    String? id,
    String? sharedNoteId,
    String? userId,
    String? userDisplayName,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isEdited,
    String? parentCommentId,
    List<String>? likedBy,
    List<SharedNoteComment>? replies,
    bool? isDeleted,
    DateTime? deletedAt,
  }) {
    return SharedNoteComment(
      id: id ?? this.id,
      sharedNoteId: sharedNoteId ?? this.sharedNoteId,
      userId: userId ?? this.userId,
      userDisplayName: userDisplayName ?? this.userDisplayName,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isEdited: isEdited ?? this.isEdited,
      parentCommentId: parentCommentId ?? this.parentCommentId,
      likedBy: likedBy ?? this.likedBy,
      replies: replies ?? this.replies,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        sharedNoteId,
        userId,
        userDisplayName,
        content,
        createdAt,
        updatedAt,
        isEdited,
        parentCommentId,
        likedBy,
        replies,
        isDeleted,
        deletedAt,
      ];

  @override
  String toString() {
    return 'SharedNoteComment(id: $id, userDisplayName: $userDisplayName, '
           'content: ${content.substring(0, content.length > 50 ? 50 : content.length)}${content.length > 50 ? "..." : ""}, '
           'createdAt: $createdAt, likeCount: $likeCount)';
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
