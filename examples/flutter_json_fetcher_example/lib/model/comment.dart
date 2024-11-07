import 'package:freezed_annotation/freezed_annotation.dart';

part 'comment.freezed.dart';
part 'comment.g.dart';

@freezed
class Comment with _$Comment {
  const factory Comment({
    @JsonKey(name: 'postId') int? postId,
    @JsonKey(name: 'id') int? id,
    @JsonKey(name: 'name') String? name,
    @JsonKey(name: 'email') String? email,
    @JsonKey(name: 'body') String? body,
  }) = _Comment;

  factory Comment.fromJson(Map<String, Object?> json) => _$CommentFromJson(json);
}

