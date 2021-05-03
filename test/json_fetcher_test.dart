// Copyright (c) 2020, alex@justprodev.com.
// All rights reserved. Use of this source code is governed by a
// MIT License that can be found in the LICENSE file.

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:json_fetcher/json_fetcher.dart';
import 'package:mock_web_server/mock_web_server.dart';

final GET_TYPICALS_METHOD = "gettypicals"+DateTime.now().millisecond.toString();
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
      identical(this, other) ||
      other is Typical &&
          runtimeType == other.runtimeType &&
          data == other.data;

  // needed just for test
  @override
  int get hashCode => data.hashCode;
}

class _TypicalFetcher extends HttpJsonFetcher<List<Typical>> {
  /// compute json parsing in separated thread
  @override
  Future<List<Typical>> parse(String source) => compute(_parseTypicals, source);

  static List<Typical> _parseTypicals(String source) {
    final parsed = json.decode(source);
    return parsed.map<Typical>((json) => Typical.fromMap(json)).toList();
  }
}

Stream<List<Typical>> fetchTypicals(String prefix) => _TypicalFetcher().fetch(prefix+GET_TYPICALS_METHOD);

void main() {
  test('integration test of the cache (client + parser + cache)',() async {
    MockWebServer server = new MockWebServer(port: 8082);
    await server.start();

    final String prefix = server.url;

    // The response queue is First In First Out
    // 1 not cached
    server.enqueue(body: '[{ "data": "$TYPICAL_DATA1"}]');
    // 1 cached + 1 not cached
    server.enqueue(body: '[{ "data": "$TYPICAL_DATA1"}, { "data": "$TYPICAL_DATA2"}]');
    // 1 cached + 1 cached
    server.enqueue(body: '[{ "data": "$TYPICAL_DATA1"}, { "data": "$TYPICAL_DATA2"}]');

    List<Typical> generate(List<String> data) => <Typical>[]..addAll(data.map((e) => Typical()..data = e));

    var s = fetchTypicals(prefix).listen((event) {
      expect(event, equals(generate([TYPICAL_DATA1])));
    });
    await s.asFuture();s.cancel();

    var count = 1;
    s = fetchTypicals(prefix).listen((event) {
      if(count == 1) expect(event, equals(generate([TYPICAL_DATA1])));  // 1 cached
      else if(count == 2) expect(
          event, equals(generate([TYPICAL_DATA1, TYPICAL_DATA2])));    // 1 cached + 1 not cached
      count++;
    });
    await s.asFuture();s.cancel();

    count = 0;
    s = fetchTypicals(prefix).listen((event) {
      expect(event, equals(generate([TYPICAL_DATA1, TYPICAL_DATA2])));    // 1 cached + 1 cached
      count++;
    });
    await s.asFuture();s.cancel();
    // stream should produce only one event - list from the cache
    // and list from online should be skipped because it's equals to cache
    expect(count, equals(1));
  });
}
