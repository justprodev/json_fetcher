// Created by alex@justprodev.com on 28.04.2024.

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:json_fetcher/src/json_http_client.dart';
import 'package:json_fetcher/src/json_http_fetcher.dart';

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

class TypicalFetcher extends JsonHttpFetcher<List<Typical>> {
  const TypicalFetcher(JsonHttpClient client) : super(client);

  /// compute json parsing in separated thread
  @override
  Future<List<Typical>> parse(String source) => compute(_parseTypicals, source);

  static List<Typical> _parseTypicals(String source) {
    final parsed = json.decode(source);
    return parsed.map<Typical>((json) => Typical.fromMap(json)).toList();
  }
}

Stream<List<Typical>> fetchTypicals(
  JsonHttpClient client,
  String prefix, {
  allowErrorWhenCacheExists = false,
  String? body,
  usePost = false,
  Map<String, String>? headers,
}) {
  return TypicalFetcher(client).fetch(
    prefix + getTypicalsMethod,
    allowErrorWhenCacheExists: allowErrorWhenCacheExists,
    usePost: usePost,
    body: body,
    headers: headers,
  );
}

List<Typical> generateTypicals(List<String> data) => <Typical>[...data.map((e) => Typical()..data = e)];
