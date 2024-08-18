// Copyright (c) 2020, alex@justprodev.com.
// All rights reserved. Use of this source code is governed by a
// MIT License that can be found in the LICENSE file.

import 'dart:io';

import 'package:json_fetcher/json_fetcher.dart' as general show createCache;
import 'package:json_fetcher/src/cache/http_cache_io_impl.dart' as io_cache_impl;
import 'package:json_fetcher/src/cache/http_cache_web_impl.dart' as web_cache_impl;
import 'package:json_fetcher/src/cache/http_files_cache/http_files_cache.dart';
import 'package:json_fetcher/src/cache/http_files_cache/http_files_cache_worker.dart';
import 'package:json_fetcher/src/http_cache.dart';
import 'package:json_fetcher/src/util/fnv1a_hash/fnv1a_hash.dart';
import 'package:test/test.dart';

const temp = 'temp';

void main() {
  group('io', () {
    group('worker', () {
      test('isolate', () => testWorkerIsolate());
      test('handleJob', () => testWorkerHandleJob());
      test('error', () => testWorkerErrors());
    });

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

  group('web', () {
    // we providing path here, because of unit test in Dart VM
    test('cache', () async {
      final cache = web_cache_impl.createCache(temp);
      await testCache(cache);
    });
    test('path by future', () => testCreateCacheWithPathByFuture((path) => web_cache_impl.createCache(path)));
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

Future<void> testWorkerHandleJob() async {
  final root = Directory('$temp/handle_job');
  if (root.existsSync()) root.deleteSync(recursive: true);
  root.createSync(recursive: true);

  final key = '123';
  final value = 'value';
  final file = getFile(root.path, key);
  String? result;

  // put
  result = HttpFilesCacheWorker.handleJob(PutJob(root.path, key, value));
  expect(result, null);
  expect(file.existsSync(), true);
  expect(file.readAsStringSync(), value);

  // get
  result = HttpFilesCacheWorker.handleJob(GetJob(root.path, key));
  expect(result, value);

  // delete
  result = HttpFilesCacheWorker.handleJob(DeleteJob(root.path, key));
  expect(result, null);
  expect(file.existsSync(), false);
  result = HttpFilesCacheWorker.handleJob(GetJob(root.path, key));
  expect(result, null);

  // emptyCache
  HttpFilesCacheWorker.handleJob(PutJob(root.path, key, value));
  result = HttpFilesCacheWorker.handleJob(EmptyCacheJob(root.path));
  expect(result, null);
  expect(file.parent.existsSync(), false);
  result = HttpFilesCacheWorker.handleJob(GetJob(root.path, key));
  expect(result, null);
}

Future<void> testWorkerErrors() async {
  final worker = await HttpFilesCacheWorker.create();
  Object? error;
  final dir = Directory('$temp/nonExistentDir234324324234');
  if (dir.existsSync()) dir.deleteSync(recursive: true);
  final job = PutJob(dir.path, '123', 'value');
  try {
    await worker.run(job);
  } catch (e) {
    error = e;
  }
  expect(error, isNotNull);
  error = null;
  dir.createSync(recursive: true);
  try {
    await worker.run(job);
  } catch (e) {
    error = e;
  }
  expect(error, isNull);
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

Future<void> testWorkerIsolate() async {
  final path = '$temp/isolate';
  final dir = Directory(path);
  if (dir.existsSync()) dir.deleteSync(recursive: true);
  dir.createSync(recursive: true);
  final worker = await HttpFilesCacheWorker.create();

  // test concurrency for different keys
  final numbersFrom0To10 = List.generate(10, (index) => index.toString());
  await Future.wait(numbersFrom0To10.map((number) => worker.run(PutJob(path, number, number))));
  final values = await Future.wait(numbersFrom0To10.map((number) => worker.run(GetJob(path, number))));
  expect(values, numbersFrom0To10);

  // test concurrency for same key
  final key = numbersFrom0To10.first;
  await Future.wait(numbersFrom0To10.map((number) => worker.run(PutJob(path, key, number))));
  final value = await worker.run(GetJob(path, key));
  expect(value, numbersFrom0To10.last);

  // create exception
  final message1 = 'isolate not spawned';
  late String message2;
  await HttpFilesCacheWorker.create((entryPoint, sendPort, {String? debugName}) async {
    throw message1;
  }).then((_) => message2 = 'isolate spawned').catchError((e) => message2 = e);
  expect(message2, message1);
}
