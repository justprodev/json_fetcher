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
import 'package:test/test.dart';

const temp = 'temp';

void main() {
  test('web', () async {
    // we providing path here, because of unit test in Dart VM
    final cache = web_cache_impl.createCache(temp);
    await testCache(cache);
  });

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
  });

  group('path by future', () {
    test('web', () => testCreateCacheWithPathByFuture((path) => web_cache_impl.createCache(path)));
    test('io', () => testCreateCacheWithPathByFuture((path) => io_cache_impl.createCache(path)));
  });

  test('general cache creation', () {
    final cache = general.createCache(Future.value(temp));

    // we on dart:io by the way
    expect(cache, isA<HttpFilesCache>());
  });
}

Future<void> testCache(HttpCache impl) async {
  // put/peek/delete
  await impl.put('123', 'value1');
  expect(await impl.peek('123'), 'value1');
  await impl.put('123', 'value2');
  expect(await impl.peek('123'), 'value2');
  await impl.delete('123');
  expect(await impl.peek('123'), null);
  await impl.put('123', 'value3');
  expect(await impl.peek('123'), 'value3');

  // emptyCache
  final keys = ['123', '124', '125'];
  for (final key in keys) {
    await impl.put(key, 'value');
  }
  await impl.emptyCache();
  for (final key in keys) {
    expect(await impl.peek(key), null);
  }
}

Future<void> testWorkerHandleJob() async {
  final root = Directory('$temp/handle_job');
  if (root.existsSync()) root.deleteSync(recursive: true);
  root.createSync(recursive: true);

  final key = '123';
  final value = 'value';
  final dir = getDirectory(root.path, key);
  final file = File('${dir.path}/$key');

  for (final type in JobType.values) {
    final job = switch (type) {
      JobType.put => Job(root.path, type, key, value),
      JobType.peek => Job(root.path, type, key),
      JobType.delete => Job(root.path, type, key),
      JobType.emptyCache => Job(root.path, type, null),
    };

    Job runJob() => HttpFilesCacheWorker.handleJob(job);
    runPutJob() {
      if (file.existsSync()) file.deleteSync();
      HttpFilesCacheWorker.handleJob(Job(root.path, JobType.put, key, value));
    }

    final Job result;

    switch (type) {
      case JobType.put:
        if (file.existsSync()) file.deleteSync();
        result = runJob();
        expect(file.existsSync(), true);
        expect(file.readAsStringSync(), value);
        expect(result.value, null);
      case JobType.peek:
        runPutJob();
        result = runJob();
        expect(result.value, value);
        expect(file.existsSync(), true);
        expect(file.readAsStringSync(), value);
      case JobType.delete:
        runPutJob();
        result = runJob();
        expect(dir.existsSync(), true);
        expect(file.existsSync(), false);
      case JobType.emptyCache:
        runPutJob();
        result = runJob();
        expect(dir.existsSync(), false);
    }

    expect(result.type, job.type);
    expect(result.key, job.key);
  }
}

Future<void> testWorkerErrors() async {
  final worker = await HttpFilesCacheWorker.create();
  Object? error;
  final dir = Directory('$temp/nonExistentDir234324324234');
  if(dir.existsSync()) dir.deleteSync(recursive: true);
  final job = Job(dir.path, JobType.put, '123', 'value');
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
  final keys = List.generate(10, (index) => index.toString());
  await Future.wait(keys.map((key) => worker.run(Job(path, JobType.put, key, key))));
  await Future.wait(keys.map((key) async {
    expect((await worker.run(Job(path, JobType.peek, key))).value, key);
    return;
  }));
}
