// Copyright (c) 2020, alex@justprodev.com.
// All rights reserved. Use of this source code is governed by a
// MIT License that can be found in the LICENSE file.

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart';
import 'package:json_fetcher/json_fetcher.dart';
import 'package:json_fetcher/loggable_http_client.dart';
import 'package:logging/logging.dart';
import 'package:mock_web_server/mock_web_server.dart';

import 'fake_path_provider.dart';

final getTypicalsMethod = "gettypicals${DateTime.now().millisecond}";
const typicalData1 = "data1";
const typicalData2 = "data2";

class Typical {
  String? data;

  static Typical fromMap(Map<String, dynamic> map) {
    Typical typical = Typical();
    typical.data = map['data'];
    return typical;
  }

  // needed just for test
  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Typical && runtimeType == other.runtimeType && data == other.data;

  // needed just for test
  @override
  int get hashCode => data.hashCode;
}

class _TypicalFetcher extends JsonHttpFetcher<List<Typical>> {
  const _TypicalFetcher(JsonHttpClient client) : super(client);

  /// compute json parsing in separated thread
  @override
  Future<List<Typical>> parse(String source) => compute(_parseTypicals, source);

  static List<Typical> _parseTypicals(String source) {
    final parsed = json.decode(source);
    return parsed.map<Typical>((json) => Typical.fromMap(json)).toList();
  }
}

Stream<List<Typical>> fetchTypicals(JsonHttpClient client, String prefix, {allowErrorWhenCacheExists = false}) =>
    _TypicalFetcher(client).fetch(prefix + getTypicalsMethod, allowErrorWhenCacheExists: allowErrorWhenCacheExists);

const authHeaders1 = {'authorization': 'Bearer 12345'};
const authHeaders2 = {'authorization': 'Bearer 67890'};

Future<JsonHttpClient> createClient({Function(String url, Object document)? onFetched}) async {
  var selectedAuthHeaders = authHeaders1;
  final JsonHttpClient client = JsonHttpClient(
      LoggableHttpClient(Client(), Logger((JsonHttpClient).toString()), config: LoggableHttpClientConfig.full()),
      auth: AuthInfo((_) => selectedAuthHeaders, (_) async {
        selectedAuthHeaders = authHeaders2;
        return true;
      }),
      onFetched: onFetched,
      onError: (e, t) => Logger.root.severe('Error in JsonHttpClient: $e', e, t));
  await client.cache.emptyCache();
  return client;
}

late MockWebServer server;

String get prefix => server.url;

void main() {
  setUpFakePathProvider();

  List<Typical> generate(List<String> data) => <Typical>[...data.map((e) => Typical()..data = e)];

  // enable logging HTTP requests
  // Logger.root.onRecord.listen((record) => debugPrint(record.message));

  setUp(() async {
    server = MockWebServer(port: 8082);
    await server.start();
  });

  tearDown(() async {
    await server.shutdown();
  });

  test('cache', () async {
    final JsonHttpClient client = await createClient();

    // The response queue is First In First Out
    // 1 not cached
    server.enqueue(body: '[{ "data": "$typicalData1"}]');
    // 1 cached + 1 not cached
    server.enqueue(body: '[{ "data": "$typicalData1"}, { "data": "$typicalData2"}]');
    // 1 cached + 1 cached
    server.enqueue(body: '[{ "data": "$typicalData1"}, { "data": "$typicalData2"}]');

    var s = fetchTypicals(client, prefix).listen((event) {
      expect(event, equals(generate([typicalData1])));
    });
    await s.asFuture();
    s.cancel();

    var count = 0;
    s = fetchTypicals(client, prefix).listen((event) {
      if (count == 0) {
        expect(event, equals(generate([typicalData1]))); // 1 cached
      } else if (count == 1) {
        expect(event, equals(generate([typicalData1, typicalData2]))); // 1 cached + 1 not cached
      }
      count++;
    });
    await s.asFuture();
    s.cancel();
    expect(count, equals(2));

    count = 0;
    s = fetchTypicals(client, prefix).listen((event) {
      expect(event, equals(generate([typicalData1, typicalData2]))); // 1 cached + 1 cached
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
      expect(server.takeRequest().headers['authorization'], authHeaders1['authorization']);
    }

    // emulate refreshToken
    server.enqueue(httpCode: 401);
    // 1 cached + 1 cached
    server.enqueue(body: '[{ "data": "$typicalData1"}, { "data": "$typicalData2"}]');

    count = 0;
    s = fetchTypicals(client, prefix).listen((event) {
      expect(event, equals(generate([typicalData1, typicalData2]))); // 1 cached + 1 cached
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
    s = fetchTypicals(client, prefix).listen((event) {
      count++;
    });
    await s.asFuture();
    s.cancel();
    assert(count == 1, 'Cache should be empty');

    // testing different url used for storing caching
    await client.cache.emptyCache();
    count = 0;
    final refreshUrl = '$prefix$getTypicalsMethod?refresh=true';
    final cacheUrl = prefix + getTypicalsMethod;
    server.enqueue(body: '[{ "data": "$typicalData1"}]');
    s = _TypicalFetcher(client).fetch(refreshUrl, cacheUrl: cacheUrl).listen((event) {
      count++;
    });
    await s.asFuture();
    s.cancel();
    server.enqueue(body: '[{ "data": "$typicalData1"}, { "data": "$typicalData2"}]');
    s = _TypicalFetcher(client).fetch(cacheUrl).listen((event) {
      count++;
    });
    await s.asFuture();
    s.cancel();
    assert(count == 3, '(count=$count) Content from $refreshUrl is not cached using $cacheUrl as cache key');
  });

  test('get', () async {
    final JsonHttpClient client = await createClient();

    // The response queue is First In First Out
    server.enqueue(body: '[{ "data": "$typicalData1"}]');

    List<Typical> r = await _TypicalFetcher(client).get(prefix + getTypicalsMethod);

    expect(r, equals(generate([typicalData1])));
    server.takeRequest(); // just remove first request

    // emulate refreshToken
    server.enqueue(httpCode: 401);
    server.enqueue(body: '[{ "data": "$typicalData1"}, { "data": "$typicalData2"}]');

    r = await _TypicalFetcher(client).get(prefix + getTypicalsMethod);

    expect(r, equals(generate([typicalData1, typicalData2])));

    // 401 response rerquested with authHeaders1
    expect(server.takeRequest().headers['authorization'], authHeaders1['authorization']);
    // headers after 'refreshToken' contains authHeaders2
    expect(server.takeRequest().headers['authorization'], authHeaders2['authorization']);
  });

  test('post', () async {
    final JsonHttpClient client = await createClient();

    // The response queue is First In First Out
    server.enqueue(body: '[{ "data": "$typicalData1"}]');

    String postData = json.encode({'command': 'get_list'});

    var parsed = json.decode((await client.post(prefix + getTypicalsMethod, postData)).body);
    List<Typical> r = parsed.map<Typical>((json) => Typical.fromMap(json)).toList();

    expect(r, equals(generate([typicalData1])));
    expect(server.takeRequest().body, postData);

    // emulate refreshToken
    server.enqueue(httpCode: 401);
    server.enqueue(body: '[{ "data": "$typicalData1"}, { "data": "$typicalData2"}]');

    parsed = json.decode((await client.post(prefix + getTypicalsMethod, postData)).body);
    r = parsed.map<Typical>((json) => Typical.fromMap(json)).toList();

    expect(r, equals(generate([typicalData1, typicalData2])));

    // 401 response rerquested with authHeaders1
    expect(server.takeRequest().headers['authorization'], authHeaders1['authorization']);
    // headers after 'refreshToken' contains authHeaders2
    expect(server.takeRequest().headers['authorization'], authHeaders2['authorization']);
  });

  test('put', () async {
    final JsonHttpClient client = await createClient();

    // The response queue is First In First Out
    server.enqueue(body: '[{ "data": "$typicalData1"}]');

    String postData = json.encode({'command': 'get_list'});

    var parsed = json.decode((await client.put(prefix + getTypicalsMethod, postData)).body);
    List<Typical> r = parsed.map<Typical>((json) => Typical.fromMap(json)).toList();

    expect(r, equals(generate([typicalData1])));
    expect(server.takeRequest().body, postData);

    // emulate refreshToken
    server.enqueue(httpCode: 401);
    // 1 cached + 1 cached
    server.enqueue(body: '[{ "data": "$typicalData1"}, { "data": "$typicalData2"}]');

    parsed = json.decode((await client.put(prefix + getTypicalsMethod, postData)).body);
    r = parsed.map<Typical>((json) => Typical.fromMap(json)).toList();

    expect(r, equals(generate([typicalData1, typicalData2])));

    // 401 response rerquested with authHeaders1
    expect(server.takeRequest().headers['authorization'], authHeaders1['authorization']);
    // headers after 'refreshToken' contains authHeaders2
    expect(server.takeRequest().headers['authorization'], authHeaders2['authorization']);
  });

  test('delete', () async {
    final JsonHttpClient client = await createClient();

    // The response queue is First In First Out
    server.enqueue(body: '[{ "data": "$typicalData1"}]');

    String postData = json.encode({'command': 'get_list'});

    var parsed = json.decode((await client.put(prefix + getTypicalsMethod, postData)).body);
    List<Typical> r = parsed.map<Typical>((json) => Typical.fromMap(json)).toList();

    expect(r, equals(generate([typicalData1])));
    expect(server.takeRequest().body, postData);

    // emulate refreshToken
    server.enqueue(httpCode: 401);
    server.enqueue(body: '[{ "data": "$typicalData1"}, { "data": "$typicalData2"}]');

    parsed = json.decode((await client.put(prefix + getTypicalsMethod, postData)).body);
    r = parsed.map<Typical>((json) => Typical.fromMap(json)).toList();

    expect(r, equals(generate([typicalData1, typicalData2])));

    // 401 response rerquested with authHeaders1
    expect(server.takeRequest().headers['authorization'], authHeaders1['authorization']);
    // headers after 'refreshToken' contains authHeaders2
    expect(server.takeRequest().headers['authorization'], authHeaders2['authorization']);
  });

  test('patch', () async {
    final JsonHttpClient client = await createClient();

    // The response queue is First In First Out
    server.enqueue(body: '[{ "data": "$typicalData1"}]');

    String postData = json.encode({'command': 'get_list'});

    var parsed = json.decode((await client.patch(prefix + getTypicalsMethod, postData)).body);
    List<Typical> r = parsed.map<Typical>((json) => Typical.fromMap(json)).toList();

    expect(r, equals(generate([typicalData1])));
    expect(server.takeRequest().body, postData);

    // emulate refreshToken
    server.enqueue(httpCode: 401);
    server.enqueue(body: '[{ "data": "$typicalData1"}, { "data": "$typicalData2"}]');

    parsed = json.decode((await client.patch(prefix + getTypicalsMethod, postData)).body);
    r = parsed.map<Typical>((json) => Typical.fromMap(json)).toList();

    expect(r, equals(generate([typicalData1, typicalData2])));

    // 401 response rerquested with authHeaders1
    expect(server.takeRequest().headers['authorization'], authHeaders1['authorization']);
    // headers after 'refreshToken' contains authHeaders2
    expect(server.takeRequest().headers['authorization'], authHeaders2['authorization']);
  });

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
        expect(event, equals(generate([typicalData1])));
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

  // also example of dealing with POST to cache results by hand
  test('post_cache', () async {
    final JsonHttpClient client = await createClient();

    server.enqueue(body: '[{ "data": "$typicalData1"}]');

    final url = server.url + getTypicalsMethod;
    final postData = json.encode({'command': 'get_list'});
    // 1. create key using request
    final key = client.cache.createKey(url + postData);

    // 2. fetch data using POST
    var result = await client.post(url, postData);
    final typical = await _TypicalFetcher(client).parse(result.body);
    expect(typical, equals(generate([typicalData1])));
    // 3. put result to cache
    await client.cache.put(key, result.body);
    // 4. get result from cache
    final typical2 = await _TypicalFetcher(client).parse((await client.cache.peek(key))!);
    expect(typical2, equals(typical));
  });
}
