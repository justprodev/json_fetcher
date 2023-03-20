// Copyright (c) 2020-2022, alex@justprodev.com.
// All rights reserved. Use of this source code is governed by a
// MIT License that can be found in the LICENSE file.

import 'dart:async';

import 'package:hive_flutter/hive_flutter.dart';

import '../json_cache.dart';

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

  /// [nocache] skips cache before getting the file - i.e.get from Internet then cache it
  @override
  Stream<String> get(String url, {Map<String, String>? headers, bool nocache = false, String? cacheUrl}) {
    StreamController<String> controller = StreamController.broadcast();

    void getValue() async {
      try {
        if (!_isInit) await _init();

        String? cachedString;

        if (!nocache) {
          try {
            cachedString = await _cache.get(_createKey(cacheUrl ?? url));
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

  Future<String> _download(String url, {Map<String, String>? headers, String? cacheUrl}) async {
    final String value = await _get(url, headers);
    await _cache.put(_createKey(cacheUrl ?? url), value);
    return value;
  }

  @override
  Future<void> evict(String url) async {
    if (!_isInit) await _init();
    await _cache.delete(_createKey(url));
  }

  @override
  Future<void> emptyCache() async {
    if (!_isInit) await _init();
    await _cache.clear();
  }

  String _createKey(String url) => _fastHash(url);
}

/// FNV-1a 64bit hash algorithm optimized for Dart Strings
String _fastHash(String string) {
  var hash = 0xcbf29ce484222325;

  var i = 0;
  while (i < string.length) {
    final codeUnit = string.codeUnitAt(i++);
    hash ^= codeUnit >> 8;
    hash *= 0x100000001b3;
    hash ^= codeUnit & 0xFF;
    hash *= 0x100000001b3;
  }

  return hash.toString();
}