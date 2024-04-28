// Copyright (c) 2020, alex@justprodev.com.
// All rights reserved. Use of this source code is governed by a
// MIT License that can be found in the LICENSE file.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:json_fetcher/json_fetcher.dart';

import 'utils/create_client.dart';
import 'utils/fake_path_provider.dart';
import 'utils/mock_web_server.dart';
import 'utils/typicals.dart';

void main() {
  setUpFakePathProvider();
  setUpMockWebServer();

  // enable logging HTTP requests
  //Logger.root.onRecord.listen((record) => debugPrint(record.message));

  group('fetch', () {
    test('get', () => testFetch());
    test('get with body', () => testFetch(body: json.encode({'command': 'get_list'})));
    test('post', () => testFetch(usePost: true, body: json.encode({'command': 'get_typicals'})));
    test('cachedUrl', () async {
      final JsonHttpClient client = await createClient();
      int count = 0;
      final refreshUrl = '$prefix$getTypicalsMethod?refresh=true';
      final cacheUrl = prefix + getTypicalsMethod;
      server.enqueue(body: '[{ "data": "$typicalData1"}]');
      var s = TypicalFetcher(client).fetch(refreshUrl, cacheUrl: cacheUrl).listen((event) {
        count++;
      });
      await s.asFuture();
      s.cancel();
      server.enqueue(body: '[{ "data": "$typicalData1"}, { "data": "$typicalData2"}]');
      s = TypicalFetcher(client).fetch(cacheUrl).listen((event) {
        count++;
      });
      await s.asFuture();
      s.cancel();
      assert(count == 3, '(count=$count) Content from $refreshUrl is not cached using $cacheUrl as cache key');
    });
  });

  test('get', () => testRequest('GET', null));
  test('get with body', () => testRequest('GET', json.encode({'command': 'get_list'})));
  test('post', () => testRequest('POST', json.encode({'command': 'get_list'})));

  test('errors', () async {
    final JsonHttpClient client = await createClient();

    Object? error;
    List<Typical>? result;

    drop() {
      error = null;
      result = null;
    }

    checkResult() {
      assert(result != null, 'Result must be filled');
    }

    fetch({allowErrorWhenCacheExists = false}) async {
      var s = fetchTypicals(client, prefix, allowErrorWhenCacheExists: allowErrorWhenCacheExists).listen((event) {
        result = event;
        expect(event, equals(generateTypicals([typicalData1])));
      });

      try {
        await s.asFuture();
        s.cancel();
      } catch (e) {
        assert(true, e is JsonFetcherException);
        error = (e as JsonFetcherException).error;
      }
    }

    drop();
    // put error
    server.enqueue(body: '[{ "data": "$typicalData1"}');
    await fetch();
    if (error is! FormatException) {
      fail('Exception should be thrown because of FormatException in the non-cached data,'
          ' and we have no valid cached data');
    }

    drop();
    // remove error
    server.enqueue(body: '[{ "data": "$typicalData1"}]');
    await fetch();
    if (error != null) fail('Exception should\'t be thrown because of FormatException in the cached data');
    checkResult();

    drop();
    // put error again
    server.enqueue(body: '[{ "data": "$typicalData1"}');
    await fetch();
    if (error != null) fail('Exception should\'t be thrown because we have valid document in cache');
    checkResult();

    drop();
    // put error again
    server.enqueue(body: '[{ "data": "$typicalData1"}');
    await fetch();
    if (error is! FormatException) {
      fail('Exception should be thrown because of FormatException in the non-cached data');
    }
    //checkResult(); // we don't have a valid result because the cached document was overwritten with invalid data

    // emulate 404
    server.enqueue(httpCode: 404);
    drop();
    await fetch();
    if (error == null) fail('Exception should be thrown because of HttpException and no valid cache');
    //checkResult(); // we don't have a valid result because the cached document was overwritten with invalid data

    drop();
    // put valid data
    server.enqueue(body: '[{ "data": "$typicalData1"}]');
    await fetch();
    if (error != null) fail('Exception should\'t be thrown because of FormatException in the cached data');
    checkResult();

    // emulate 404
    server.enqueue(httpCode: 404);
    drop();
    await fetch();
    if (error != null) fail('Exception should\'t be thrown because we have valid cache');
    checkResult();

    // test keeping the cache between network errors, emulate 404
    server.enqueue(httpCode: 404);
    drop();
    await fetch();
    if (error != null) fail('Exception should\'t be thrown because we have valid cache');
    checkResult();

    // test allowErrorWhenCacheExists, emulate 404
    server.enqueue(httpCode: 404);
    drop();
    await fetch(allowErrorWhenCacheExists: true);
    if (error == null) {
      fail('Exception should be thrown because we have valid cache but \'allowErrorWhenCacheExists==true`\'');
    }
    checkResult();
  });

  test('on_fetched', () async {
    int fCalls = 0;

    drop() => fCalls = 0;
    onFetched(_, __) => fCalls++;

    final JsonHttpClient client = await createClient(onFetched: onFetched);

    // normal case
    server.enqueue(body: '[{ "data": "$typicalData1"}]');
    // put error
    server.enqueue(body: '[{ "data": "$typicalData1"}');
    // remove error
    server.enqueue(body: '[{ "data": "$typicalData1"}]');
    // same document
    server.enqueue(body: '[{ "data": "$typicalData1"}]');
    // put error again
    server.enqueue(body: '[{ "data": "$typicalData1"}');

    fetch() async {
      try {
        await fetchTypicals(client, prefix).last;
      } catch (e) {
        // ignore
      }
    }

    drop();
    await fetch();
    assert(fCalls == 1, 'onFetch(calls: $fCalls) should be called once because of valid data');

    drop();
    await fetch();
    if (fCalls > 0) fail('onFetch(calls: $fCalls) should\'t be call because of invalid data in the cache');

    drop();
    await fetch();
    if (fCalls != 1) {
      fail('onFetch(calls: $fCalls) should be called once because of FormatException in the cached data only');
    }

    drop();
    await fetch();
    if (fCalls > 0) fail('onFetch(calls: $fCalls) should\'t be called because document has not changed');

    drop();
    await fetch();
    if (fCalls > 0) fail('onFetch(calls: $fCalls) should\'t be call because of FormatException in the non-cached data');

    // emulate 404
    server.enqueue(httpCode: 404);
    drop();
    await fetch();
    if (fCalls > 0) fail('onFetch(calls: $fCalls) should\'t be call because  of HttpException');
  });
}

Future<void> testFetch({bool usePost = false, String? body}) async {
  final JsonHttpClient client = await createClient();

  final headers = {'test': 'test', 'test2': 'test2'};

// The response queue is First In First Out
// 1 not cached
  server.enqueue(body: '[{ "data": "$typicalData1"}]');
// 1 cached + 1 not cached
  server.enqueue(body: '[{ "data": "$typicalData1"}, { "data": "$typicalData2"}]');
// 1 cached + 1 cached
  server.enqueue(body: '[{ "data": "$typicalData1"}, { "data": "$typicalData2"}]');

  Stream<List<Typical>> fetch() {
    return fetchTypicals(client, prefix, body: body, usePost: usePost, headers: headers);
  }

  var s = fetch().listen((event) {
    expect(event, equals(generateTypicals([typicalData1])));
  });
  await s.asFuture();
  s.cancel();

  var count = 0;
  s = fetch().listen((event) {
    if (count == 0) {
      expect(event, equals(generateTypicals([typicalData1]))); // 1 cached
    } else if (count == 1) {
      expect(event, equals(generateTypicals([typicalData1, typicalData2]))); // 1 cached + 1 not cached
    }
    count++;
  });
  await s.asFuture();
  s.cancel();
  expect(count, equals(2));

  count = 0;
  s = fetch().listen((event) {
    expect(event, equals(generateTypicals([typicalData1, typicalData2]))); // 1 cached + 1 cached
    count++;
  });
  await s.asFuture();
  s.cancel();
// stream should produce only one event - list from the cache
// and list from online should be skipped because it's equals to cache
  expect(count, equals(1));

  /// all requests sent with header {'authorization': 'Bearer 12345'}
  var requests = server.requestCount;
  for (int i = 0; i < requests; i++) {
    final request = server.takeRequest();
    if (body != null) expect(request.body, body);
    expect(request.method, usePost ? 'POST' : 'GET');
    expect(request.headers['test'], headers['test']);
    expect(request.headers['test2'], headers['test2']);
    expect(request.headers['authorization'], authHeaders1['authorization']);
  }

// emulate refreshToken
  server.enqueue(httpCode: 401);
// 1 cached + 1 cached
  server.enqueue(body: '[{ "data": "$typicalData1"}, { "data": "$typicalData2"}]');

  count = 0;
  s = fetch().listen((event) {
    expect(event, equals(generateTypicals([typicalData1, typicalData2]))); // 1 cached + 1 cached
    count++;
  });
  await s.asFuture();
  s.cancel();
// resubmit happens silently
  expect(count, equals(1));

// 401 response requested with authHeaders1
  expect(server.takeRequest().headers['authorization'], authHeaders1['authorization']);
// headers after 'refreshToken' contains authHeaders2
  expect(server.takeRequest().headers['authorization'], authHeaders2['authorization']);

// testing empty Cache
  await client.cache.emptyCache();
  server.enqueue(body: '[]');
  count = 0;
  s = fetch().listen((event) {
    count++;
  });
  await s.asFuture();
  s.cancel();
  assert(count == 1, 'Cache should be empty');
}

Future<void> testRequest(String method, String? body) async {
  final JsonHttpClient client = await createClient();

  final headers = {'test': 'test', 'test2': 'test2'};

  Future<List<Typical>> makeRequest() async {
    switch (method) {
      case 'GET':
        return await TypicalFetcher(client).get(
          prefix + getTypicalsMethod,
          body: body,
          headers: headers,
        );
      case 'POST':
        return await TypicalFetcher(client).get(
          prefix + getTypicalsMethod,
          usePost: true,
          body: body,
          headers: headers,
        );
      default:
        throw Exception('Unknown method: $method');
    }
  }

  // The response queue is First In First Out
  server.enqueue(body: '[{ "data": "$typicalData1"}]');

  List<Typical> r = await makeRequest();

  expect(r, equals(generateTypicals([typicalData1])));
  var request = server.takeRequest();
  if (body != null) expect(request.body, body);
  expect(request.method, method);
  expect(request.headers['test'], headers['test']);
  expect(request.headers['test2'], headers['test2']);

  // emulate refreshToken
  server.enqueue(httpCode: 401);
  server.enqueue(body: '[{ "data": "$typicalData1"}, { "data": "$typicalData2"}]');

  r = await makeRequest();

  expect(r, equals(generateTypicals([typicalData1, typicalData2])));

  // 401 response requested with authHeaders1
  expect(server.takeRequest().headers['authorization'], authHeaders1['authorization']);
  // headers after 'refreshToken' contains authHeaders2
  expect(server.takeRequest().headers['authorization'], authHeaders2['authorization']);
}
