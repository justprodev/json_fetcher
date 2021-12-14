import 'dart:async';
import 'dart:collection';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:logging/logging.dart';

import '../json_fetcher.dart';

/// Created by alex@justprodev.com on 22.06.2021.

const _BOX_NAME = '__hive_json_hive_cache';

class JsonHiveCache implements JsonCache {
  final JsonHttpClient client;

  static late Logger _log = Logger((JsonHiveCache).toString());

  late final Map<String, StreamController<String>> _downloads = HashMap();
  late final LazyBox _cache;

  bool _isInit = false;
  Future<void>? _initializing;

  JsonHiveCache(this.client);

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
  Stream<String> get(String url, {Map<String, String>? headers, nocache: false}) {
    StreamController<String>? oldController = _downloads[url];

    // prev download started - return it
    if(oldController!=null && !oldController.isClosed) return oldController.stream;

    StreamController<String> controller = StreamController();
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
        final onlineString = await _download(url, authHeaders: headers);
        //print("download $url stop");
        if (!controller.isClosed) {
          if(onlineString != cachedString) // skip if a data the same
            controller.add(onlineString);
        } // online
      } catch (e, trace) {
        _log.severe("Failed to download file from $url", e, trace);
        if(!controller.isClosed) controller.addError(e);
      } finally {
        if(!controller.isClosed) await controller.close();
        _downloads.remove(url);
      }
    }

    _getValue();

    return controller.stream;
  }

  Future<String> _download(String url, {Map<String, String>? authHeaders}) async {
    final String value = (await client.get(url)).body;
    await _cache.put(url, value);
    return value;
  }

  Future<void> evict(key) => _cache.delete(key);
  Future<void> emptyCache() => _cache.clear();
}