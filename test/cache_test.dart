// Copyright (c) 2020, alex@justprodev.com.
// All rights reserved. Use of this source code is governed by a
// MIT License that can be found in the LICENSE file.

import 'dart:io';

import 'package:json_fetcher/src/cache/http_cache_io_impl.dart' as io_cache_impl;
import 'package:json_fetcher/src/cache/http_cache_web_impl.dart' as web_cache_impl;
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
      test('handleJob', () => testWorker());
    });

    test('cache', () async {
      final cache = io_cache_impl.createCache(temp);
      await testCache(cache);
    });
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

Future<void> testWorker() async {
  final root = Directory('$temp/handle_job')
    ..deleteSync(recursive: true)
    ..createSync(recursive: true);

  final key = '123';
  final value = 'value';
  final dir = getDirectory(root.path, key);
  final file = File('${dir.path}/$key');

  for (final type in JobType.values) {
    final job = switch (type) {
      JobType.put => Job(type, key, value),
      JobType.peek => Job(type, key),
      JobType.delete => Job(type, key),
      JobType.emptyCache => Job(type, null),
    };

    Job runJob() => HttpFilesCacheWorker.handleJob(root.path, job);
    runPutJob() {
      if (file.existsSync()) file.deleteSync();
      HttpFilesCacheWorker.handleJob(root.path, Job(JobType.put, key, value));
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
