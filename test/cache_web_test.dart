// Created by alex@justprodev.com on 08.11.2024.

@TestOn('browser')
library;

import 'dart:async';
import 'dart:js_interop';

import 'package:json_fetcher/json_fetcher.dart';
import 'package:json_fetcher/src/cache/http_web_cache/http_web_cache.dart';
import 'package:json_fetcher/src/cache/http_web_cache/utils.dart';
import 'package:test/test.dart';
import 'package:web/web.dart';

import 'cache_test.dart' show testCache;

void main() {
  late HttpCache cache;

  setUp(() {
    cache = createCache();
  });

  tearDown(() {
    (cache as HttpWebCache).db?.close();
  });

  test('general cache', () async {
    await testCache(cache);
  });

  test('persistence', () async {
    await cache.put('321', '321');
    (cache as HttpWebCache).db!.close();
    cache = createCache();
    expect(await cache.get('321'), '321');
  });

  test('init onerror', () async {
    Object? error;
    try {
      // waiting closing cache
      await cache.get('123');
      (cache as HttpWebCache).db!.close();

      // emulate Version error and handle it in cache init
      window.indexedDB.open(dbName, 20);
      cache = createCache();
      await cache.get('123');
    } catch (e) {
      error = e;
    }
    expect(error, isNotNull);
  });
}
