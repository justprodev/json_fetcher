// Copyright (c) 2020-2022, alex@justprodev.com.
// All rights reserved. Use of this source code is governed by a
// MIT License that can be found in the LICENSE file.

import 'dart:async';
import 'dart:collection';

import 'package:hive_flutter/hive_flutter.dart';

import '../json_cache.dart';
import '../json_http_client.dart';

const _BOX_NAME = '__hive_json_hive_cache';

// todo: move get outside, because is useful for any cache

class JsonHiveCache implements JsonCache {
  final Future<String> Function(String url, Map<String, String>? headers) _get;

  late final Map<String, StreamController<String>> _downloads = HashMap();
  late final LazyBox _cache;

  bool _isInit = false;
  Future<void>? _initializing;

  JsonHiveCache(this._get);

  Future<void> _init() async {
    if(_initializing==null) {
      // start initializing process
      Future<void> init() async {
        if(_isInit) return;  // for any case
        await Hive.initFlutter();
        try {
          _cache = await Hive.openLazyBox(_BOX_NAME);
        } catch(e) {
          await Hive.deleteBoxFromDisk(_BOX_NAME);
          _cache = await Hive.openLazyBox(_BOX_NAME);
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
  Stream<String> get(String url, {Map<String, String>? headers, nocache: false}) {
    // ignore: close_sinks, will be closed in other get() call, that initiated this download
    StreamController<String>? oldController = _downloads[url];

    // prev download started - return it
    if(oldController!=null && !oldController.isClosed) return oldController.stream;

    StreamController<String> controller = StreamController.broadcast();
    _downloads[url] = controller;

    void _getValue() async {
      try {
        if(!_isInit) await _init();

        String? cachedString;

        if(!nocache) {
          cachedString = await _cache.get(url);
          if(cachedString!=null && !controller.isClosed) {
            controller.add(cachedString);
          }
        }

        //print("download $url start");
        final onlineString = await _download(url);
        //print("download $url stop");
        if (!controller.isClosed) {
          if(onlineString != cachedString) // skip if a data the same
            controller.add(onlineString);
        } // online
      } catch (e) {
        if(!controller.isClosed) controller.addError(e);
      } finally {
        if(!controller.isClosed) await controller.close();
        _downloads.remove(url);
      }
    }

    _getValue();

    return controller.stream;
  }

  Future<String> _download(String url, {Map<String, String>? headers}) async {
    final String value = await _get(url, headers);
    await _cache.put(url, value);
    return value;
  }

  Future<void> evict(key) => _cache.delete(key);
  Future<void> emptyCache() => _cache.clear();
}