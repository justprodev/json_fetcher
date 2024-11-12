// Copyright (c) alex@justprodev.com.
// All rights reserved. Use of this source code is governed by a
// MIT License that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:json_fetcher/src/json_http_fetcher.dart';

import 'src/util/isolate/isolate_stub.dart'
    if (dart.library.io) 'src/util/isolate/isolate_io.dart'
    if (dart.library.html) 'src/util/isolate/isolate_web.dart';

/// get result from service as is, without parsing actually
///
/// ```dart
/// await for(final ok in PlainFetcher<bool>(client).fetch(checkSomeUrl)) {
///   if(ok) {
///     print("Good");
///   } else {
///     print("Bad");
///   }
/// };
/// ```
class PlainFetcher<T> extends JsonHttpFetcher<T> {
  const PlainFetcher(super.client);

  @override
  T parse(String source) => json.decode(source);
}

/// General fetcher to use [JsonHttpFetcher] in a functional way.
///
/// ```dart
/// await for(final ok in JsonFetcher<bool>(client, (json) => json['ok'] as bool).fetch(url)) {
///   if(ok) {
///     print("Good");
///   } else {
///     print("Bad");
///   }
/// };
/// ```
///
class JsonFetcher<T> extends JsonHttpFetcher<T> {
  /// Converter from json to object
  /// json will be decoded from string using [jsonDecode]
  final FutureOr<T> Function(dynamic json) converter;

  const JsonFetcher(super.client, this.converter);

  @override
  FutureOr<T> parse(String source) => converter(jsonDecode(source));
}

/// Version of [JsonFetcher] that invokes [converter] in isolate.
class IsolatedJsonFetcher<T> extends JsonFetcher<T> {
  const IsolatedJsonFetcher(super.client, super.converter);

  @override
  FutureOr<T> parse(String source) {
    // Prevent capturing client
    // ignore: no_leading_underscores_for_local_identifiers
    final _converter = converter;
    return run(() => _converter(jsonDecode(source)));
  }
}
