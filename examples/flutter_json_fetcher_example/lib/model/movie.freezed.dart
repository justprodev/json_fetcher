// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'movie.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Movie _$MovieFromJson(Map<String, dynamic> json) {
  return _Movie.fromJson(json);
}

/// @nodoc
mixin _$Movie {
  @JsonKey(name: 'title')
  String? get title => throw _privateConstructorUsedError;
  @JsonKey(name: 'year')
  int? get year => throw _privateConstructorUsedError;
  @JsonKey(name: 'cast')
  List<String>? get cast => throw _privateConstructorUsedError;
  @JsonKey(name: 'genres')
  List<String>? get genres => throw _privateConstructorUsedError;
  @JsonKey(name: 'href')
  String? get href => throw _privateConstructorUsedError;
  @JsonKey(name: 'extract')
  String? get extract => throw _privateConstructorUsedError;
  @JsonKey(name: 'thumbnail')
  String? get thumbnail => throw _privateConstructorUsedError;
  @JsonKey(name: 'thumbnail_width')
  int? get thumbnailWidth => throw _privateConstructorUsedError;
  @JsonKey(name: 'thumbnail_height')
  int? get thumbnailHeight => throw _privateConstructorUsedError;

  /// Serializes this Movie to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Movie
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MovieCopyWith<Movie> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MovieCopyWith<$Res> {
  factory $MovieCopyWith(Movie value, $Res Function(Movie) then) =
      _$MovieCopyWithImpl<$Res, Movie>;
  @useResult
  $Res call(
      {@JsonKey(name: 'title') String? title,
      @JsonKey(name: 'year') int? year,
      @JsonKey(name: 'cast') List<String>? cast,
      @JsonKey(name: 'genres') List<String>? genres,
      @JsonKey(name: 'href') String? href,
      @JsonKey(name: 'extract') String? extract,
      @JsonKey(name: 'thumbnail') String? thumbnail,
      @JsonKey(name: 'thumbnail_width') int? thumbnailWidth,
      @JsonKey(name: 'thumbnail_height') int? thumbnailHeight});
}

/// @nodoc
class _$MovieCopyWithImpl<$Res, $Val extends Movie>
    implements $MovieCopyWith<$Res> {
  _$MovieCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Movie
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? title = freezed,
    Object? year = freezed,
    Object? cast = freezed,
    Object? genres = freezed,
    Object? href = freezed,
    Object? extract = freezed,
    Object? thumbnail = freezed,
    Object? thumbnailWidth = freezed,
    Object? thumbnailHeight = freezed,
  }) {
    return _then(_value.copyWith(
      title: freezed == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String?,
      year: freezed == year
          ? _value.year
          : year // ignore: cast_nullable_to_non_nullable
              as int?,
      cast: freezed == cast
          ? _value.cast
          : cast // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      genres: freezed == genres
          ? _value.genres
          : genres // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      href: freezed == href
          ? _value.href
          : href // ignore: cast_nullable_to_non_nullable
              as String?,
      extract: freezed == extract
          ? _value.extract
          : extract // ignore: cast_nullable_to_non_nullable
              as String?,
      thumbnail: freezed == thumbnail
          ? _value.thumbnail
          : thumbnail // ignore: cast_nullable_to_non_nullable
              as String?,
      thumbnailWidth: freezed == thumbnailWidth
          ? _value.thumbnailWidth
          : thumbnailWidth // ignore: cast_nullable_to_non_nullable
              as int?,
      thumbnailHeight: freezed == thumbnailHeight
          ? _value.thumbnailHeight
          : thumbnailHeight // ignore: cast_nullable_to_non_nullable
              as int?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$MovieImplCopyWith<$Res> implements $MovieCopyWith<$Res> {
  factory _$$MovieImplCopyWith(
          _$MovieImpl value, $Res Function(_$MovieImpl) then) =
      __$$MovieImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'title') String? title,
      @JsonKey(name: 'year') int? year,
      @JsonKey(name: 'cast') List<String>? cast,
      @JsonKey(name: 'genres') List<String>? genres,
      @JsonKey(name: 'href') String? href,
      @JsonKey(name: 'extract') String? extract,
      @JsonKey(name: 'thumbnail') String? thumbnail,
      @JsonKey(name: 'thumbnail_width') int? thumbnailWidth,
      @JsonKey(name: 'thumbnail_height') int? thumbnailHeight});
}

/// @nodoc
class __$$MovieImplCopyWithImpl<$Res>
    extends _$MovieCopyWithImpl<$Res, _$MovieImpl>
    implements _$$MovieImplCopyWith<$Res> {
  __$$MovieImplCopyWithImpl(
      _$MovieImpl _value, $Res Function(_$MovieImpl) _then)
      : super(_value, _then);

  /// Create a copy of Movie
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? title = freezed,
    Object? year = freezed,
    Object? cast = freezed,
    Object? genres = freezed,
    Object? href = freezed,
    Object? extract = freezed,
    Object? thumbnail = freezed,
    Object? thumbnailWidth = freezed,
    Object? thumbnailHeight = freezed,
  }) {
    return _then(_$MovieImpl(
      title: freezed == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String?,
      year: freezed == year
          ? _value.year
          : year // ignore: cast_nullable_to_non_nullable
              as int?,
      cast: freezed == cast
          ? _value._cast
          : cast // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      genres: freezed == genres
          ? _value._genres
          : genres // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      href: freezed == href
          ? _value.href
          : href // ignore: cast_nullable_to_non_nullable
              as String?,
      extract: freezed == extract
          ? _value.extract
          : extract // ignore: cast_nullable_to_non_nullable
              as String?,
      thumbnail: freezed == thumbnail
          ? _value.thumbnail
          : thumbnail // ignore: cast_nullable_to_non_nullable
              as String?,
      thumbnailWidth: freezed == thumbnailWidth
          ? _value.thumbnailWidth
          : thumbnailWidth // ignore: cast_nullable_to_non_nullable
              as int?,
      thumbnailHeight: freezed == thumbnailHeight
          ? _value.thumbnailHeight
          : thumbnailHeight // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$MovieImpl implements _Movie {
  const _$MovieImpl(
      {@JsonKey(name: 'title') this.title,
      @JsonKey(name: 'year') this.year,
      @JsonKey(name: 'cast') final List<String>? cast,
      @JsonKey(name: 'genres') final List<String>? genres,
      @JsonKey(name: 'href') this.href,
      @JsonKey(name: 'extract') this.extract,
      @JsonKey(name: 'thumbnail') this.thumbnail,
      @JsonKey(name: 'thumbnail_width') this.thumbnailWidth,
      @JsonKey(name: 'thumbnail_height') this.thumbnailHeight})
      : _cast = cast,
        _genres = genres;

  factory _$MovieImpl.fromJson(Map<String, dynamic> json) =>
      _$$MovieImplFromJson(json);

  @override
  @JsonKey(name: 'title')
  final String? title;
  @override
  @JsonKey(name: 'year')
  final int? year;
  final List<String>? _cast;
  @override
  @JsonKey(name: 'cast')
  List<String>? get cast {
    final value = _cast;
    if (value == null) return null;
    if (_cast is EqualUnmodifiableListView) return _cast;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final List<String>? _genres;
  @override
  @JsonKey(name: 'genres')
  List<String>? get genres {
    final value = _genres;
    if (value == null) return null;
    if (_genres is EqualUnmodifiableListView) return _genres;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  @JsonKey(name: 'href')
  final String? href;
  @override
  @JsonKey(name: 'extract')
  final String? extract;
  @override
  @JsonKey(name: 'thumbnail')
  final String? thumbnail;
  @override
  @JsonKey(name: 'thumbnail_width')
  final int? thumbnailWidth;
  @override
  @JsonKey(name: 'thumbnail_height')
  final int? thumbnailHeight;

  @override
  String toString() {
    return 'Movie(title: $title, year: $year, cast: $cast, genres: $genres, href: $href, extract: $extract, thumbnail: $thumbnail, thumbnailWidth: $thumbnailWidth, thumbnailHeight: $thumbnailHeight)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MovieImpl &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.year, year) || other.year == year) &&
            const DeepCollectionEquality().equals(other._cast, _cast) &&
            const DeepCollectionEquality().equals(other._genres, _genres) &&
            (identical(other.href, href) || other.href == href) &&
            (identical(other.extract, extract) || other.extract == extract) &&
            (identical(other.thumbnail, thumbnail) ||
                other.thumbnail == thumbnail) &&
            (identical(other.thumbnailWidth, thumbnailWidth) ||
                other.thumbnailWidth == thumbnailWidth) &&
            (identical(other.thumbnailHeight, thumbnailHeight) ||
                other.thumbnailHeight == thumbnailHeight));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      title,
      year,
      const DeepCollectionEquality().hash(_cast),
      const DeepCollectionEquality().hash(_genres),
      href,
      extract,
      thumbnail,
      thumbnailWidth,
      thumbnailHeight);

  /// Create a copy of Movie
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MovieImplCopyWith<_$MovieImpl> get copyWith =>
      __$$MovieImplCopyWithImpl<_$MovieImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MovieImplToJson(
      this,
    );
  }
}

abstract class _Movie implements Movie {
  const factory _Movie(
          {@JsonKey(name: 'title') final String? title,
          @JsonKey(name: 'year') final int? year,
          @JsonKey(name: 'cast') final List<String>? cast,
          @JsonKey(name: 'genres') final List<String>? genres,
          @JsonKey(name: 'href') final String? href,
          @JsonKey(name: 'extract') final String? extract,
          @JsonKey(name: 'thumbnail') final String? thumbnail,
          @JsonKey(name: 'thumbnail_width') final int? thumbnailWidth,
          @JsonKey(name: 'thumbnail_height') final int? thumbnailHeight}) =
      _$MovieImpl;

  factory _Movie.fromJson(Map<String, dynamic> json) = _$MovieImpl.fromJson;

  @override
  @JsonKey(name: 'title')
  String? get title;
  @override
  @JsonKey(name: 'year')
  int? get year;
  @override
  @JsonKey(name: 'cast')
  List<String>? get cast;
  @override
  @JsonKey(name: 'genres')
  List<String>? get genres;
  @override
  @JsonKey(name: 'href')
  String? get href;
  @override
  @JsonKey(name: 'extract')
  String? get extract;
  @override
  @JsonKey(name: 'thumbnail')
  String? get thumbnail;
  @override
  @JsonKey(name: 'thumbnail_width')
  int? get thumbnailWidth;
  @override
  @JsonKey(name: 'thumbnail_height')
  int? get thumbnailHeight;

  /// Create a copy of Movie
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MovieImplCopyWith<_$MovieImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
