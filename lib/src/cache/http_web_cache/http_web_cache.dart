// Copyright (c) 2020, alex@justprodev.com.
// All rights reserved. Use of this source code is governed by a
// MIT License that can be found in the LICENSE file.

import 'dart:async';
import 'dart:js_interop';

import 'package:json_fetcher/src/cache/http_web_cache/utils.dart';
import 'package:json_fetcher/src/util/fnv1a_hash/fnv1a_hash.dart';
import 'package:meta/meta.dart';
import 'package:web/web.dart';

import '../../http_cache.dart';

@visibleForTesting
const dbName = '__json_fetcher';
final _storeName = 'cache';

/// Web-based cache
///
/// 1. Uses IndexedDB
/// 2. Keys are strings, see [createKey]
class HttpWebCache extends HttpCache {
  IDBDatabase? db;
  Completer? _initializing = Completer();

  HttpWebCache() {
    var dbRequest = window.self.indexedDB.open(dbName, 1);

    dbRequest.onupgradeneeded = (IDBVersionChangeEvent e) {
      final newDb = dbRequest.result as IDBDatabase;
      if (!newDb.objectStoreNames.contains(_storeName)) {
        print("Creating objectStore $_storeName in database $dbName with version 1");
        newDb.createObjectStore(_storeName);
      }
    }.toJS;

    dbRequest.asFuture().then((db) {
      this.db = db as IDBDatabase;
      if (_initializing?.isCompleted == false) _initializing!.complete();
      _initializing = null;
    }).catchError((e) {
      if (_initializing?.isCompleted == false) _initializing!.completeError(e);
    });
  }

  @override
  Future<void> delete(String key) async {
    if (_initializing != null) await _initializing!.future;
    await db!.transaction(_storeName.toJS, 'readwrite').objectStore(_storeName).delete(key.toJS).asFuture();
  }

  @override
  Future<void> emptyCache() async {
    if (_initializing != null) await _initializing!.future;
    await db!.transaction(_storeName.toJS, 'readwrite').objectStore(_storeName).clear().asFuture();
  }

  @override
  Future<String?> get(String key) async {
    if (_initializing != null) await _initializing!.future;
    final value = await db!.transaction(_storeName.toJS, 'readonly').objectStore(_storeName).get(key.toJS).asFuture();
    return value.dartify() as String?;
  }

  @override
  Future<void> put(String key, String json) async {
    if (_initializing != null) await _initializing!.future;
    await db!.transaction(_storeName.toJS, 'readwrite').objectStore(_storeName).put(json.toJS, key.toJS).asFuture();
  }

  /// This implementation uses FNV-1a hash function of the url + body
  @override
  String createKey(String url, {String? body}) => fastHash('$url${body ?? ''}');
}
