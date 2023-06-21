// Copyright (c) alex@justprodev.com.
// All rights reserved. Use of this source code is governed by a
// MIT License that can be found in the LICENSE file.

import 'dart:convert';

import 'package:json_fetcher/src/json_http_fetcher.dart';

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
  PlainFetcher(super.client);

  @override
  T parse(String source) => json.decode(source);
}