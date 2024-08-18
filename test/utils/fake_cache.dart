// Created by alex@justprodev.com on 19.08.2024.

import 'package:json_fetcher/src/http_cache.dart';

/// cache that does nothing
class FakeCache implements HttpCache {
  const FakeCache();

  @override
  String createKey(String url, {String? body}) => '';

  @override
  Future<void> evict(String url, {String? body}) => Future.value();

  @override
  Future<String?> get(String key) => Future.value(null);

  @override
  Future<void> put(String key, String value) => Future.value();

  @override
  Future<void> delete(String key) => Future.value();

  @override
  Future<void> emptyCache() => Future.value();
}