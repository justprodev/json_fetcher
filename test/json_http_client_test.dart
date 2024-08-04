// Copyright (c) 2020, alex@justprodev.com.
// All rights reserved. Use of this source code is governed by a
// MIT License that can be found in the LICENSE file.

import 'dart:convert';

import 'package:test/test.dart';
import 'package:json_fetcher/json_fetcher.dart';

import 'utils/create_client.dart';
import 'utils/mock_web_server.dart';
import 'utils/typicals.dart';

void main() {
  setUpMockWebServer();

  // enable logging HTTP requests
  //Logger.root.onRecord.listen((record) => debugPrint(record.message));

  final body = json.encode({'command': 'get_list'});

  test('get', () => testRequest('GET', null));
  test('get with body', () => testRequest('GET', body));
  test('post', () => testRequest('POST', body));
  test('put', () => testRequest('PUT', body));
  test('delete', () => testRequest('DELETE', null));
  test('patch', () => testRequest('PATCH', body));
}

Future<void> testRequest(String method, String? body) async {
  final JsonHttpClient client = await createClient();

  final headers = {'test': 'test', 'test2': 'test2'};

  Future<String> makeRequest() async {
    switch (method) {
      case 'GET':
        return (await client.get(prefix + getTypicalsMethod, json: body, headers: headers)).body;
      case 'POST':
        return (await client.post(prefix + getTypicalsMethod, body!, headers: headers)).body;
      case 'PUT':
        return (await client.put(prefix + getTypicalsMethod, body!, headers: headers)).body;
      case 'DELETE':
        return (await client.delete(prefix + getTypicalsMethod, headers: headers)).body;
      case 'PATCH':
        return (await client.patch(prefix + getTypicalsMethod, body!, headers: headers)).body;
      default:
        throw Exception('Unknown method: $method');
    }
  }

// The response queue is First In First Out
  server.enqueue(body: '[{ "data": "$typicalData1"}]');

  var parsed = json.decode(await makeRequest());
  List<Typical> r = parsed.map<Typical>((json) => Typical.fromMap(json)).toList();

  expect(r, equals(generateTypicals([typicalData1])));
  var request = server.takeRequest();
  if (body != null) expect(request.body, body);
  expect(request.method, method.toUpperCase());
  expect(request.headers['test'], headers['test']);
  expect(request.headers['test2'], headers['test2']);

  // emulate refreshToken
  server.enqueue(httpCode: 401);
  server.enqueue(body: '[{ "data": "$typicalData1"}, { "data": "$typicalData2"}]');

  parsed = json.decode(await makeRequest());
  r = parsed.map<Typical>((json) => Typical.fromMap(json)).toList();

  expect(r, equals(generateTypicals([typicalData1, typicalData2])));

// 401 response requested with authHeaders1
  expect(server.takeRequest().headers['authorization'], authHeaders1['authorization']);
// headers after 'refreshToken' contains authHeaders2
  expect(server.takeRequest().headers['authorization'], authHeaders2['authorization']);
}
