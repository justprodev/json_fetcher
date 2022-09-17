// Copyright (c) 2020, alex@justprodev.com.
// All rights reserved. Use of this source code is governed by a
// MIT License that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart';
import 'package:json_fetcher/json_fetcher.dart';
import 'package:json_fetcher/loggable_http_client.dart';
import 'package:logging/logging.dart';
import 'package:mock_web_server/mock_web_server.dart';

import 'fake_path_provider.dart';

final GET_TYPICALS_METHOD = "gettypicals" + DateTime.now().millisecond.toString();
const TYPICAL_DATA1 = "data1";
const TYPICAL_DATA2 = "data2";

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
  _TypicalFetcher(JsonHttpClient client) : super(client);

  /// compute json parsing in separated thread
  @override
  Future<List<Typical>> parse(String source) => compute(_parseTypicals, source);

  static List<Typical> _parseTypicals(String source) {
    final parsed = json.decode(source);
    return parsed.map<Typical>((json) => Typical.fromMap(json)).toList();
  }
}

Stream<List<Typical>> fetchTypicals(JsonHttpClient client, String prefix) =>
    _TypicalFetcher(client).fetch(prefix + GET_TYPICALS_METHOD);

void main() {
  setUpFakePathProvider();

  final Map<String, String> authHeaders1 = {'authorization': 'Bearer 12345'};
  final Map<String, String> authHeaders2 = {'authorization': 'Bearer 67890'};

  List<Typical> generate(List<String> data) => <Typical>[]..addAll(data.map((e) => Typical()..data = e));

  Logger.root.onRecord.listen((record) {
    print(record.message);
  });

  JsonHttpClient createClient({Function(String url, Object document)? onFetched}) {
    var selectedAuthHeaders = authHeaders1;
    final JsonHttpClient client = JsonHttpClient(
      LoggableHttpClient(Client(), Logger((JsonHttpClient).toString())),
      auth: AuthInfo(() => selectedAuthHeaders, (bool) async {
        selectedAuthHeaders = authHeaders2;
        return true;
      }),
      onFetched: onFetched,
      onError: (e,t)=>Logger.root.severe('Error in JsonHttpClient: $e', e, t)
    );
    client.cache.emptyCache();
    return client;
  }

  test('cache', () async {
    final JsonHttpClient client = createClient();
    final MockWebServer server = new MockWebServer(port: 8082);
    await server.start();

    final String prefix = server.url;

    // The response queue is First In First Out
    // 1 not cached
    server.enqueue(body: '[{ "data": "$TYPICAL_DATA1"}]');
    // 1 cached + 1 not cached
    server.enqueue(body: '[{ "data": "$TYPICAL_DATA1"}, { "data": "$TYPICAL_DATA2"}]');
    // 1 cached + 1 cached
    server.enqueue(body: '[{ "data": "$TYPICAL_DATA1"}, { "data": "$TYPICAL_DATA2"}]');

    var s = fetchTypicals(client, prefix).listen((event) {
      expect(event, equals(generate([TYPICAL_DATA1])));
    });
    await s.asFuture();
    s.cancel();

    var count = 0;
    s = fetchTypicals(client, prefix).listen((event) {
      if (count == 0)
        expect(event, equals(generate([TYPICAL_DATA1]))); // 1 cached
      else if (count == 1) expect(event, equals(generate([TYPICAL_DATA1, TYPICAL_DATA2]))); // 1 cached + 1 not cached
      count++;
    });
    await s.asFuture();
    s.cancel();
    expect(count, equals(2));

    count = 0;
    s = fetchTypicals(client, prefix).listen((event) {
      expect(event, equals(generate([TYPICAL_DATA1, TYPICAL_DATA2]))); // 1 cached + 1 cached
      count++;
    });
    await s.asFuture();
    s.cancel();
    // stream should produce only one event - list from the cache
    // and list from online should be skipped because it's equals to cache
    expect(count, equals(1));

    /// all requests sent with header {'authorization': 'Bearer 12345'}
    var requests = server.requestCount;
    for (int i = 0; i < requests; i++)
      expect(server.takeRequest().headers['authorization'], authHeaders1['authorization']);

    // emulate refreshToken
    server.enqueue(httpCode: 401);
    // 1 cached + 1 cached
    server.enqueue(body: '[{ "data": "$TYPICAL_DATA1"}, { "data": "$TYPICAL_DATA2"}]');

    count = 0;
    s = fetchTypicals(client, prefix).listen((event) {
      expect(event, equals(generate([TYPICAL_DATA1, TYPICAL_DATA2]))); // 1 cached + 1 cached
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

    await server.shutdown();
  });

  test('get', () async {
    final JsonHttpClient client = createClient();
    final MockWebServer server = new MockWebServer(port: 8082);
    await server.start();
    final String prefix = server.url;

    // The response queue is First In First Out
    // 1 not cached
    server.enqueue(body: '[{ "data": "$TYPICAL_DATA1"}]');

    List<Typical> r = await _TypicalFetcher(client).get(prefix + GET_TYPICALS_METHOD);

    expect(r, equals(generate([TYPICAL_DATA1])));
    server.takeRequest(); // just remove first request

    // emulate refreshToken
    server.enqueue(httpCode: 401);
    // 1 cached + 1 cached
    server.enqueue(body: '[{ "data": "$TYPICAL_DATA1"}, { "data": "$TYPICAL_DATA2"}]');

    r = await _TypicalFetcher(client).get(prefix + GET_TYPICALS_METHOD);

    // return two cached arrays because of resubmit
    expect(r, equals(generate([TYPICAL_DATA1, TYPICAL_DATA2])));

    // 401 response rerquested with authHeaders1
    expect(server.takeRequest().headers['authorization'], authHeaders1['authorization']);
    // headers after 'refreshToken' contains authHeaders2
    expect(server.takeRequest().headers['authorization'], authHeaders2['authorization']);

    await server.shutdown();
  });

  test('post', () async {
    final JsonHttpClient client = createClient();
    final MockWebServer server = new MockWebServer(port: 8082);
    await server.start();
    final String prefix = server.url;

    // The response queue is First In First Out
    // 1 not cached
    server.enqueue(body: '[{ "data": "$TYPICAL_DATA1"}]');

    String postData = json.encode({'command': 'get_list'});

    var parsed = json.decode((await client.post(prefix + GET_TYPICALS_METHOD, postData)).body);
    List<Typical> r = parsed.map<Typical>((json) => Typical.fromMap(json)).toList();

    expect(r, equals(generate([TYPICAL_DATA1])));
    expect(server.takeRequest().body, postData);

    // emulate refreshToken
    server.enqueue(httpCode: 401);
    // 1 cached + 1 cached
    server.enqueue(body: '[{ "data": "$TYPICAL_DATA1"}, { "data": "$TYPICAL_DATA2"}]');

    parsed = json.decode((await client.post(prefix + GET_TYPICALS_METHOD, postData)).body);
    r = parsed.map<Typical>((json) => Typical.fromMap(json)).toList();

    // return two cached arrays because of resubmit
    expect(r, equals(generate([TYPICAL_DATA1, TYPICAL_DATA2])));

    // 401 response rerquested with authHeaders1
    expect(server.takeRequest().headers['authorization'], authHeaders1['authorization']);
    // headers after 'refreshToken' contains authHeaders2
    expect(server.takeRequest().headers['authorization'], authHeaders2['authorization']);

    await server.shutdown();
  });

  test('put', () async {
    final JsonHttpClient client = createClient();
    final MockWebServer server = new MockWebServer(port: 8082);
    await server.start();
    final String prefix = server.url;

    // The response queue is First In First Out
    // 1 not cached
    server.enqueue(body: '[{ "data": "$TYPICAL_DATA1"}]');

    String postData = json.encode({'command': 'get_list'});

    var parsed = json.decode((await client.put(prefix + GET_TYPICALS_METHOD, postData)).body);
    List<Typical> r = parsed.map<Typical>((json) => Typical.fromMap(json)).toList();

    expect(r, equals(generate([TYPICAL_DATA1])));
    expect(server.takeRequest().body, postData);

    // emulate refreshToken
    server.enqueue(httpCode: 401);
    // 1 cached + 1 cached
    server.enqueue(body: '[{ "data": "$TYPICAL_DATA1"}, { "data": "$TYPICAL_DATA2"}]');

    parsed = json.decode((await client.put(prefix + GET_TYPICALS_METHOD, postData)).body);
    r = parsed.map<Typical>((json) => Typical.fromMap(json)).toList();

    // return two cached arrays because of resubmit
    expect(r, equals(generate([TYPICAL_DATA1, TYPICAL_DATA2])));

    // 401 response rerquested with authHeaders1
    expect(server.takeRequest().headers['authorization'], authHeaders1['authorization']);
    // headers after 'refreshToken' contains authHeaders2
    expect(server.takeRequest().headers['authorization'], authHeaders2['authorization']);

    await server.shutdown();
  });

  test('delete', () async {
    final JsonHttpClient client = createClient();
    final MockWebServer server = new MockWebServer(port: 8082);
    await server.start();
    final String prefix = server.url;

    // The response queue is First In First Out
    // 1 not cached
    server.enqueue(body: '[{ "data": "$TYPICAL_DATA1"}]');

    String postData = json.encode({'command': 'get_list'});

    var parsed = json.decode((await client.put(prefix + GET_TYPICALS_METHOD, postData)).body);
    List<Typical> r = parsed.map<Typical>((json) => Typical.fromMap(json)).toList();

    expect(r, equals(generate([TYPICAL_DATA1])));
    expect(server.takeRequest().body, postData);

    // emulate refreshToken
    server.enqueue(httpCode: 401);
    // 1 cached + 1 cached
    server.enqueue(body: '[{ "data": "$TYPICAL_DATA1"}, { "data": "$TYPICAL_DATA2"}]');

    parsed = json.decode((await client.put(prefix + GET_TYPICALS_METHOD, postData)).body);
    r = parsed.map<Typical>((json) => Typical.fromMap(json)).toList();

    // return two cached arrays because of resubmit
    expect(r, equals(generate([TYPICAL_DATA1, TYPICAL_DATA2])));

    // 401 response rerquested with authHeaders1
    expect(server.takeRequest().headers['authorization'], authHeaders1['authorization']);
    // headers after 'refreshToken' contains authHeaders2
    expect(server.takeRequest().headers['authorization'], authHeaders2['authorization']);

    await server.shutdown();
  });

  test('patch', () async {
    final JsonHttpClient client = createClient();
    final MockWebServer server = new MockWebServer(port: 8082);
    await server.start();
    final String prefix = server.url;

    // The response queue is First In First Out
    // 1 not cached
    server.enqueue(body: '[{ "data": "$TYPICAL_DATA1"}]');

    String postData = json.encode({'command': 'get_list'});

    var parsed = json.decode((await client.patch(prefix + GET_TYPICALS_METHOD, postData)).body);
    List<Typical> r = parsed.map<Typical>((json) => Typical.fromMap(json)).toList();

    expect(r, equals(generate([TYPICAL_DATA1])));
    expect(server.takeRequest().body, postData);

    // emulate refreshToken
    server.enqueue(httpCode: 401);
    // 1 cached + 1 cached
    server.enqueue(body: '[{ "data": "$TYPICAL_DATA1"}, { "data": "$TYPICAL_DATA2"}]');

    parsed = json.decode((await client.patch(prefix + GET_TYPICALS_METHOD, postData)).body);
    r = parsed.map<Typical>((json) => Typical.fromMap(json)).toList();

    // return two cached arrays because of resubmit
    expect(r, equals(generate([TYPICAL_DATA1, TYPICAL_DATA2])));

    // 401 response rerquested with authHeaders1
    expect(server.takeRequest().headers['authorization'], authHeaders1['authorization']);
    // headers after 'refreshToken' contains authHeaders2
    expect(server.takeRequest().headers['authorization'], authHeaders2['authorization']);

    await server.shutdown();
  });

  test('errors', () async {
    final JsonHttpClient client = createClient();
    final MockWebServer server = new MockWebServer(port: 8082);
    await server.start();

    final String prefix = server.url;

    // put error
    server.enqueue(body: '[{ "data": "$TYPICAL_DATA1"}');
    // remove error
    server.enqueue(body: '[{ "data": "$TYPICAL_DATA1"}]');
    // put error again
    server.enqueue(body: '[{ "data": "$TYPICAL_DATA1"}');

    var error;

    fetch() async {
      var s = fetchTypicals(client, prefix).listen((event) {
        expect(event, equals(generate([TYPICAL_DATA1])));
      });

      try {
        await s.asFuture();
        s.cancel();
      } catch (e) {
        assert(true, e is JsonFetcherException);
        error = (e as JsonFetcherException).error;
      }
    }

    error = null;
    await fetch();
    if (error is! FormatException)
      fail('Exception should be thrown because of FormatException in the non-cached data');

    error = null;
    await fetch();
    if (error != null) fail('Exception should\'t be thrown because of FormatException in the cached data');

    error = null;
    await fetch();
    if (error is! FormatException)
      fail('Exception should be thrown because of FormatException in the non-cached data');

    // emulate 404
    server.enqueue(httpCode: 404);
    error = false;
    await fetch();
    if (error is! HttpException) fail('Exception should be thrown because of HttpException');

    await server.shutdown();
  });

  test('on_fetched', () async {
    String? fUrl;
    Object? fDocument;
    int fCalls = 0;
    var error;

    drop() {
      error = null;
      fUrl = null;
      fDocument = null;
      fCalls = 0;
    }

    done(String url, Object document) {
      fUrl = url;
      fDocument = document;
      fCalls++;
    }

    final JsonHttpClient client = createClient(onFetched: done);
    final MockWebServer server = new MockWebServer(port: 8082);
    await server.start();

    final String prefix = server.url;

    // put error
    server.enqueue(body: '[{ "data": "$TYPICAL_DATA1"}');
    // remove error
    server.enqueue(body: '[{ "data": "$TYPICAL_DATA1"}]');
    // same document
    server.enqueue(body: '[{ "data": "$TYPICAL_DATA1"}]');
    // put error again
    server.enqueue(body: '[{ "data": "$TYPICAL_DATA1"}');

    fetch() async {
      var s = fetchTypicals(client, prefix).listen((event) {
        expect(event, equals(generate([TYPICAL_DATA1])));
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
    await fetch();
    if (error is! FormatException)
      fail('Exception should be thrown because of FormatException in the non-cached data');
    if (fCalls > 0)
      fail('onFetch(calls: $fCalls) should\'t be call because of FormatException in the non-cached data');

    drop();
    await fetch();
    if (error != null) fail('Exception should\'t be thrown because of FormatException in the cached data only');
    if (fCalls != 1)
      fail('onFetch(calls: $fCalls) should be called once because of FormatException in the cached data only');

    drop();
    await fetch();
    if (error != null) fail('Exception should\'t be thrown because of no exceptions');
    if (fCalls > 0)
      fail('onFetch(calls: $fCalls) should\'t be called because document has not changed');

    drop();
    await fetch();
    if (error is! FormatException)
      fail('Exception should be thrown because of FormatException in the non-cached data');
    if (fCalls > 0)
      fail('onFetch(calls: $fCalls) should\'t be call because of FormatException in the non-cached data');

    // emulate 404
    server.enqueue(httpCode: 404);
    drop();
    await fetch();
    if (error is! HttpException) fail('Exception should be thrown because of HttpException');
    if (fCalls > 0)
      fail('onFetch(calls: $fCalls) should\'t be call because  of HttpException');

    await server.shutdown();
  });
}
