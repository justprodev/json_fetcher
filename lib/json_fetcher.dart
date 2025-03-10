// Copyright (c) 2020, alex@justprodev.com.
// All rights reserved. Use of this source code is governed by a
// MIT License that can be found in the LICENSE file.

export 'src/json_http_fetcher.dart';
export 'src/json_http_client.dart';
export 'src/json_fetcher_exception.dart';
export 'src/http_cache.dart';

import 'dart:async';

import 'src/http_cache.dart';

import 'src/cache/http_cache_impl.dart' as impl;

/// Creates a cache for [JsonHttpClient]
///
/// [path] - path to the cache directory (Not needed for web)
HttpCache createCache([FutureOr<String>? path]) => impl.createCache(path);