// Copyright (c) 2020, alex@justprodev.com.
// All rights reserved. Use of this source code is governed by a
// MIT License that can be found in the LICENSE file.

import 'package:json_fetcher/src/cache/http_cache_io_impl.dart' as io_cache_impl;
import 'package:json_fetcher/src/cache/http_cache_web_impl.dart' as web_cache_impl;
import 'package:json_fetcher/src/http_cache.dart';
import 'package:test/test.dart';

void main() {
  test('io', () async {
    final cache = io_cache_impl.createCache('temp');
    await testCache(cache);
  });

  test('web', () async {
    // we providing path here, because of unit test in Dart VM
    final cache = web_cache_impl.createCache('temp');
    await testCache(cache);
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
  for(final key in keys) {
    await impl.put(key, 'value');
  }
  await impl.emptyCache();
  for(final key in keys) {
    expect(await impl.peek(key), null);
  }
}