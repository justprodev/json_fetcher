// Copyright (c) 2020, alex@justprodev.com.
// All rights reserved. Use of this source code is governed by a
// MIT License that can be found in the LICENSE file.

/// Cache for JSON data
abstract class JsonCache {
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
  Stream<String> get(String url, {Map<String, String>? headers, bool nocache = false, String? cacheUrl});

  /// force remove file from the cache
  Future<void> evict(String url);

  /// empty the cache entirely
  Future<void> emptyCache();

  /// get json from cache
  Future<String?> peek(String key);

  /// put json to cache
  Future<void> put(String key, String json);

  /// create cache key
  String createKey(String data);
}
