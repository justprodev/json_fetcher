import 'package:freezed_annotation/freezed_annotation.dart';

part 'movie.freezed.dart';
part 'movie.g.dart';

@freezed
class Movie with _$Movie {
  const factory Movie({
    @JsonKey(name: 'title') String? title,
    @JsonKey(name: 'year') int? year,
    @JsonKey(name: 'cast') List<String>? cast,
    @JsonKey(name: 'genres') List<String>? genres,
    @JsonKey(name: 'href') String? href,
    @JsonKey(name: 'extract') String? extract,
    @JsonKey(name: 'thumbnail') String? thumbnail,
    @JsonKey(name: 'thumbnail_width') int? thumbnailWidth,
    @JsonKey(name: 'thumbnail_height') int? thumbnailHeight,
  }) = _Movie;

  factory Movie.fromJson(Map<String, Object?> json) => _$MovieFromJson(json);
}

