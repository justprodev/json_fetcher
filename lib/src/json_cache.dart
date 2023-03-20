// Copyright (c) 2020-2022, alex@justprodev.com.
// All rights reserved. Use of this source code is governed by a
// MIT License that can be found in the LICENSE file.

/// always download file (after returning it from memory or cache firstly)
/// very simple interface
abstract class JsonCache {
  /// get file.
  /// probably stream will be closed after receiving file from the network
  /// if [cacheUrl] is specified, it will be used for the cache key instead of [url]
  Stream<String> get(String url, {Map<String, String>? headers, bool nocache = false, String? cacheUrl});
  /// force remove file from the cache
  Future<void> evict(String url);
  /// empty the cache entirely
  Future<void> emptyCache();
}