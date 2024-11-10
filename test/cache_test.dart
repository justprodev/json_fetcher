// Copyright (c) 2020, alex@justprodev.com.
// All rights reserved. Use of this source code is governed by a
// MIT License that can be found in the LICENSE file.

import 'dart:io';

import 'package:json_fetcher/json_fetcher.dart' as general show createCache;
import 'package:json_fetcher/src/cache/http_cache_io_impl.dart' as io_cache_impl;
import 'package:json_fetcher/src/cache/http_files_cache/http_files_cache.dart';
import 'package:json_fetcher/src/http_cache.dart';
import 'package:json_fetcher/src/util/fnv1a_hash/fnv1a_hash.dart';
import 'package:test/test.dart';

const temp = 'temp';

void main() {
  group('io', () {
    test('cache', () async {
      final cache = io_cache_impl.createCache(temp);
      await testCache(cache);
    });

    test('path by future', () => testCreateCacheWithPathByFuture((path) => io_cache_impl.createCache(path)));

    test('init error', () async {
      Object? error;
      final file = File('$temp/file');
      file.createSync(recursive: true);
      final cache = HttpFilesCache(file.path);
      try {
        await cache.get('123');
      } catch (e) {
        error = e;
      }
      expect(error, isA<FileSystemException>());
    });
  });

  test('general cache creation', () {
    final cache = general.createCache(Future.value(temp));

    // we on dart:io by the way
    expect(cache, isA<HttpFilesCache>());
  });
}

Future<void> testCache(HttpCache impl) async {
  // put/get/delete
  await impl.put('123', 'value1');
  expect(await impl.get('123'), 'value1');
  await impl.put('123', 'value2');
  expect(await impl.get('123'), 'value2');
  await impl.delete('123');
  expect(await impl.get('123'), null);
  await impl.put('123', 'value3');
  expect(await impl.get('123'), 'value3');
  await impl.delete('0'); // not exists

  // emptyCache
  final keys = ['123', '124', '125'];
  for (final key in keys) {
    await impl.put(key, 'value');
  }
  await impl.emptyCache();
  for (final key in keys) {
    expect(await impl.get(key), null);
  }

  // getKey
  final urlKey = impl.createKey('url');
  expect(urlKey, fastHash('url'));
  await impl.put(urlKey, 'value');
  expect(await impl.get(urlKey), 'value');
  await impl.evict('url');
  expect(await impl.get(urlKey), null);
}

Future<void> testCreateCacheWithPathByFuture(HttpCache Function(Future<String> path) createCache) async {
  final Future<String> path = Future.delayed(Duration(milliseconds: 10), () => temp);
  final stopwatch = Stopwatch()..start();
  // we providing path here, because of unit test in Dart VM
  final cache = createCache(path);
  await cache.put('123', 'value');
  expect(stopwatch.elapsedMilliseconds, greaterThanOrEqualTo(10));
  stopwatch.stop();
}
