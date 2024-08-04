// Copyright (c) 2020, alex@justprodev.com.
// All rights reserved. Use of this source code is governed by a
// MIT License that can be found in the LICENSE file.

import 'dart:async';

import 'package:hive_flutter/hive_flutter.dart';

import '../http_cache.dart';

const _boxName = '__hive_json_hive_cache';

class HttpHiveCache extends HttpCache {
  late final LazyBox _cache;

  bool _isInit = false;
  Future<void>? _initializing;

  Future<void> _init() async {
    if (_initializing == null) {
      // start initializing process
      Future<void> init() async {
        if (_isInit) return; // for any case
        await Hive.initFlutter();
        try {
          _cache = await Hive.openLazyBox(_boxName);
        } catch (e) {
          await Hive.deleteBoxFromDisk(_boxName);
          _cache = await Hive.openLazyBox(_boxName);
        }
        _isInit = true; // complete
        _initializing = null;
      }

      _initializing = init();
    }
    await _initializing; // wait the new one or already exists process
  }

  @override
  Future<void> delete(String key) async {
    if (!_isInit) await _init();
    await _cache.delete(key);
  }

  @override
  Future<void> emptyCache() async {
    if (!_isInit) await _init();
    await _cache.clear();
  }

  @override
  Future<String?> peek(String key) async {
    if (!_isInit) await _init();
    return await _cache.get(key);
  }

  @override
  Future<void> put(String key, String json) async {
    if (!_isInit) await _init();
    await _cache.put(key, json);
  }
}
