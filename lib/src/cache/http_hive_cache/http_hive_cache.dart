// Copyright (c) 2020, alex@justprodev.com.
// All rights reserved. Use of this source code is governed by a
// MIT License that can be found in the LICENSE file.

import 'dart:async';

import 'package:hive/hive.dart';
import 'package:json_fetcher/src/util/fnv1a_hash/fnv1a_hash.dart';

import '../../http_cache.dart';

const _boxName = '__hive_json_hive_cache';

class HttpHiveCache extends HttpCache {
  late final LazyBox _cache;

  Completer? _initializing = Completer();

  HttpHiveCache(FutureOr<String>? path) {
    Future<void> init() async {
      Hive.init(await path);
      try {
        _cache = await Hive.openLazyBox(_boxName);
        _initializing?.complete();
        _initializing = null;
      } catch (e) {
        // try to delete the box and open it again
        try {
          await Hive.deleteBoxFromDisk(_boxName);
          _cache = await Hive.openLazyBox(_boxName);
          _initializing?.complete();
          _initializing = null;
        } catch (ee) {
          _initializing?.completeError(ee);
        }
      }
    }

    init();
  }

  @override
  Future<void> delete(String key) async {
    if (_initializing != null) await _initializing!.future;
    await _cache.delete(key);
  }

  @override
  Future<void> emptyCache() async {
    if (_initializing != null) await _initializing!.future;
    await _cache.clear();
  }

  @override
  Future<String?> peek(String key) async {
    if (_initializing != null) await _initializing!.future;
    return await _cache.get(key);
  }

  @override
  Future<void> put(String key, String json) async {
    if (_initializing != null) await _initializing!.future;
    await _cache.put(key, json);
  }

  /// This implementation uses FNV-1a hash function of the url + body
  @override
  String createKey(String url, {String? body}) => fastHash('$url${body ?? ''}');
}
