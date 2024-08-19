import 'package:freezed_annotation/freezed_annotation.dart';

part 'photo.freezed.dart';
part 'photo.g.dart';

@freezed
class Photo with _$Photo {
  const factory Photo({
    @JsonKey(name: 'albumId') int? albumId,
    @JsonKey(name: 'id') int? id,
    @JsonKey(name: 'title') String? title,
    @JsonKey(name: 'url') String? url,
    @JsonKey(name: 'thumbnailUrl') String? thumbnailUrl,
  }) = _Photo;

  factory Photo.fromJson(Map<String, Object?> json) => _$PhotoFromJson(json);
}

