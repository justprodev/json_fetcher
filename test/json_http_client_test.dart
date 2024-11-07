// Copyright (c) 2020, alex@justprodev.com.
// All rights reserved. Use of this source code is governed by a
// MIT License that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart';
import 'package:http/testing.dart';
import 'package:http_parser/http_parser.dart';
import 'package:json_fetcher/loggable_http_client.dart';
import 'package:logging/logging.dart';
import 'package:test/test.dart';
import 'package:json_fetcher/json_fetcher.dart';

import 'utils/create_client.dart';
import 'utils/fake_cache.dart';
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

  group('errors', errorsGroup);

  group('logout', () {
    test('manual', () async {
      bool loggedOut = false;
      final client = await createClient(
        onExpire: (bool logout) async {
          loggedOut = logout;
          return false;
        },
      );
      client.logout();
      expect(loggedOut, true);
    });

    test('auto', () async {
      final loggedOut = <bool>[];
      final client = await createClient(
        rawClient: MockClient((request) {
          return Future.value(Response('', 401, headers: {}));
        }),
        onExpire: (bool logout) async {
          loggedOut.add(logout);
          return false;
        },
      );

      try {
        await client.get(prefix);
      } on JsonFetcherException catch (e) {
        expect(e.statusCode, 401);
      }

      expect(loggedOut[0], false);
      expect(loggedOut[1], true);
    });
  });

  test('upload', () async {
    BaseRequest? request;

    final client = await createClient(
      rawClient: MockClient.streaming((r, _) {
        request = r;
        return Future.value(StreamedResponse(Stream.value([]), 200, headers: {}));
      }),
    );

    await client.postUpload(
      prefix,
      [
        MultipartFile.fromBytes('file', [1, 2, 3], filename: 'file.jpg', contentType: MediaType('image', 'jpeg')),
      ],
      fields: {'field': 'value'},
    );

    expect(request, isA<MultipartRequest>());
    final body = request as MultipartRequest;
    expect(body.files.length, 1);
    expect(body.files[0].filename, 'file.jpg');
    expect(body.files[0].field, 'file');
    expect(body.files[0].contentType.mimeType, 'image/jpeg');
    expect(body.fields['field'], 'value');
  });

  test('close', () async {
    final delegate = TestCloseClient();
    final client = LoggableHttpClient(delegate, Logger.root);
    expect(delegate.closed, false);
    client.close();
    expect(delegate.closed, true);
  });
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
  expect(request.headers[HttpHeaders.contentTypeHeader], startsWith('application/json'));
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

errorsGroup() {
  (Object, StackTrace)? error;
  Future<JsonHttpClient> createErrorClient(Client rawClient) async {
    error = null;
    return JsonHttpClient(
      rawClient,
      FakeCache(),
      onError: (e, t) => error = (e, t!),
    );
  }

  test('status code', () async {
    final client = await createErrorClient(
      MockClient((_) => Future.value(Response('error', 500))),
    );
    JsonFetcherException? exception;
    try {
      await client.get(prefix);
    } on JsonFetcherException catch (e) {
      exception = e;
    }
    expect(exception!.statusCode, 500);
    expect(exception.body, 'error');
    expect(error!.$1, exception);
    expect(error!.$2, exception.trace!);
  });

  test('not reachable', () async {
    final fastClient = await createErrorClient(
      MockClient((request) {
        throw SocketException('test');
      }),
    );
    JsonFetcherException? exception;
    try {
      await fastClient.get(prefix);
    } on JsonFetcherException catch (e) {
      exception = e;
    }
    expect(exception!.notReachable, true);
    expect(error!.$1, exception);
    expect(error!.$2, exception.trace!);
  });

  test('default onError', () async {
    LogRecord? record;
    final client = JsonHttpClient(MockClient((_) => throw Exception('test')), FakeCache());
    final subs = Logger.root.onRecord.listen((r) => record = r);
    try {
      await client.get(prefix);
    } catch (e) {
      // ignore
    }
    expect(record!.level, Level.SEVERE);
    expect(record!.error, isA<JsonFetcherException>());
    subs.cancel();
  });
}

class TestCloseClient extends MockClient {
  bool closed = false;

  TestCloseClient() : super((_) async => Future.value(Response('', 200)));

  @override
  close() => closed = true;
}
