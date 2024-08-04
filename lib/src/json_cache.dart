// Copyright (c) 2020, alex@justprodev.com.
// All rights reserved. Use of this source code is governed by a
// MIT License that can be found in the LICENSE file.

/// Cache for data fetched from the network
abstract class HttpCache implements BaseCache {
  /// create key based on url and body
  String createKey(String url, {String? body});

  /// remove json from the cache
  Future<void> evict(String url, {String? body}) => delete(createKey(url, body: body));
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