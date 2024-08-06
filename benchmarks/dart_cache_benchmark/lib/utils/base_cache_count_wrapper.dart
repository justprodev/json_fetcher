// Created by alex@justprodev.com on 06.08.2024.

import 'package:json_fetcher/json_fetcher.dart';

class BaseCacheBenchmarkWrapper implements BaseCache {
  final BaseCache _cache;
  int _counter = 0;

  int get counter => _counter;

  BaseCacheBenchmarkWrapper(this._cache);

  @override
  Future<void> delete(String key) {
    return _cache.delete(key).then((value) {
      _counter++;
      return Future.value();
    });
  }

  @override
  Future<void> emptyCache() {
    return _cache.emptyCache().then((value) {
      _counter++;
      return Future.value();
    });
  }

  @override
  Future<String?> peek(String key) {
    return _cache.peek(key).then((value) {
      _counter++;
      return Future.value(value);
    });
  }

  @override
  Future<void> put(String key, String value) {
    return _cache.put(key, value).then((value) {
      _counter++;
      return Future.value();
    });
  }

  @override
  toString() {
    return '${_cache.runtimeType}';
  }
}