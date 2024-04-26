// Copyright (c) 2020, alex@justprodev.com.
// All rights reserved. Use of this source code is governed by a
// MIT License that can be found in the LICENSE file.

import 'dart:async';

import 'package:hive_flutter/hive_flutter.dart';

import '../json_cache.dart';
import '../util/fnv1a_hash/fnv1a_hash.dart';

const _boxName = '__hive_json_hive_cache';

// todo: move get outside, because is useful for any cache

class JsonHiveCache implements JsonCache {
  final Future<String> Function(String url, Map<String, String>? headers) _get;
  final Function(Object error, StackTrace trace)? _onError;

  late final LazyBox _cache;

  bool _isInit = false;
  Future<void>? _initializing;

  JsonHiveCache(this._get, this._onError);

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
  Stream<String> get(String url, {Map<String, String>? headers, bool nocache = false, String? cacheUrl}) {
    StreamController<String> controller = StreamController.broadcast();

    void getValue() async {
      try {
        if (!_isInit) await _init();

        String? cachedString;

        if (!nocache) {
          try {
            cachedString = await _cache.get(createKey(cacheUrl ?? url));
          } catch (e, trace) {
            // probably not fatal error, just skip
            // but report
            _onError?.call(e, trace);
          }

          if (cachedString != null && !controller.isClosed) {
            controller.add(cachedString);
          }
        }

        //print("download $url start");
        final onlineString = await _download(url, headers: headers, cacheUrl: cacheUrl);
        //print("download $url stop");
        if (!controller.isClosed) {
          if (onlineString != cachedString) {
            controller.add(onlineString);
          }
        } // online
      } catch (e) {
        if (!controller.isClosed) controller.addError(e);
      } finally {
        if (!controller.isClosed) await controller.close();
      }
    }

    getValue();

    return controller.stream;
  }

  @override
  Future<void> evict(String url) async {
    if (!_isInit) await _init();
    await _cache.delete(createKey(url));
  }

  @override
  Future<void> emptyCache() async {
    if (!_isInit) await _init();
    await _cache.clear();
  }

  @override
  Future<String> peek(String key) async {
    if (!_isInit) await _init();
    return await _cache.get(key);
  }

  @override
  Future<void> put(String key, String json) async {
    if (!_isInit) await _init();
    await _cache.put(key, json);
  }

  @override
  String createKey(String data) => fastHash(data);

  Future<String> _download(String url, {Map<String, String>? headers, String? cacheUrl}) async {
    final String value = await _get(url, headers);
    await _cache.put(createKey(cacheUrl ?? url), value);
    return value;
  }
}