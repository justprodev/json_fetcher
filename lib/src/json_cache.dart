// Copyright (c) 2020, alex@justprodev.com.
// All rights reserved. Use of this source code is governed by a
// MIT License that can be found in the LICENSE file.

/// Cache for JSON data
abstract class JsonCache implements BaseCache {
  /// get json.
  ///
  /// Algorithm:
  ///
  /// 1. If [nocache] is false, try to get from cache, emit the result if found
  /// 2. If not found or [nocache] is true, get from the internet, emit the result if it's not equal to the cached one
  /// 3. close the stream
  ///
  /// [url] - the url to fetch, will be used to create the cache key
  /// if [cacheUrl] is specified, it will be used for the cache key instead of [url]
  ///
  @Deprecated("Use JsonHttpFetcher.fetch, or implement an logic by yourself. Will be removed in 2.0.0")
  Stream<String> get(String url, {Map<String, String>? headers, bool nocache = false, String? cacheUrl});

  /// create cache key
  String createKey(String data);

  /// remove json from the cache
  Future<void> evict(String url, {String? body}) => delete(buildKey(url, body: body));
}

/// Base cache operations, not related to network
abstract class BaseCache {
  /// get string from cache
  Future<String?> peek(String key);

  /// put string to cache
  Future<void> put(String key, String value);

  /// remove string from cache
  Future<void> delete(String key);

  /// empty the cache entirely
  Future<void> emptyCache();
}

extension KeyBuilder on JsonCache {
  /// builds key for cache based on url and body
  String buildKey(String url, {String? body}) {
    return createKey(body == null ? url : '$url$body');
  }
}
