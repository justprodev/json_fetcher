// Copyright (c) 2020, alex@justprodev.com.
// All rights reserved. Use of this source code is governed by a
// MIT License that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:json_fetcher/src/http_logger.dart';
import 'package:test/test.dart';
import 'package:json_fetcher/json_fetcher.dart';
import 'package:json_fetcher/loggable_http_client.dart';
import 'package:logging/logging.dart';

import 'utils/create_client.dart';
import 'utils/mock_web_server.dart';

void main() {
  setUpMockWebServer();

  final r = Random();
  String bigString() => List.generate(longJsonFieldLength, (index) => r.nextBool() ? 'A' : 'B').join('');
  List<String> bigArray() => List.generate(longBodyLength ~/ longJsonFieldLength, (index) => '"${bigString()}"');

  group('long body', () {
    test('cut big json body request', () async {
      final client = await createClient(
        config: const LoggableHttpClientConfig(cutLongBody: true, logInputBody: true, logOutputBody: true),
      );
      final String bigJson = '{ "data": [${bigArray().join(',')}] }';

      // post big json
      server.enqueue(body: bigJson);
      int bodyPresentInLogs = 0;
      final (request, response) = (Completer(), Completer());
      final subs = Logger.root.onRecord.listen((record) {
        int i = record.message.indexOf('{ "data');
        if (i > 0) {
          final Map big = json.decode(bigJson);
          final Map cut = json.decode(record.message.substring(i));

          expect(cut['data'].length == big['data'].length, true);

          var j = 0;
          for (String fCut in cut['data']) {
            final fBig = big['data'][j++];
            final parts = fCut.split(threeDotsString);
            expect(fBig, startsWith(parts[0]));
            expect(fBig, endsWith(parts[1]));
            expect(fBig.length > fCut.length, true);
          }

          bodyPresentInLogs++;
        }
        !request.isCompleted ? request.complete() : response.complete();
      });

      await client.post('${prefix}a', bigJson);

      await response.future; // request & response were logged

      expect(bodyPresentInLogs, 2, reason: 'Body is not fully present in logs');

      await subs.cancel();
    });

    test('cut big plain body request', () async {
      final client = await createClient(
        config: const LoggableHttpClientConfig(cutLongBody: true, logInputBody: true, logOutputBody: true),
      );
      final String bigPlain = bigArray().join(',');

      // post big plain
      server.enqueue(body: bigPlain);
      int bodyPresentInLogs = 0;
      final (request, response) = (Completer(), Completer());
      final subs = Logger.root.onRecord.listen((record) {
        final ss = record.message.split('body: ');
        if (ss.length > 1) {
          expect(ss[1], endsWith(threeDotsString));
          final String cut = ss[1].replaceFirst(threeDotsString, '', ss[1].length - 3);

          expect(bigPlain.startsWith(cut), true);
          expect(bigPlain.length > cut.length, true);
          bodyPresentInLogs++;
        }
        !request.isCompleted ? request.complete() : response.complete();
      });

      await client.post('${prefix}a', bigPlain, headers: {HttpHeaders.contentTypeHeader: 'text/plain'});

      await response.future; // request & response were logged

      expect(bodyPresentInLogs, 2, reason: 'Body is not fully present in logs');

      await subs.cancel();
    });
  });

  test('hide auth', () => testAuth(false));
  test('show auth', () => testAuth(true));

  test('log input body', () => testBody(true, true));
  test('no log input body', () => testBody(true, false));
  test('log output body', () => testBody(false, true));
  test('no log output body', () => testBody(false, false));
}

Future<void> testAuth(bool show) async {
  final client = await createClient(config: LoggableHttpClientConfig(hideAuthorization: !show));

  server.enqueue(body: 'body', headers: {'Content-type': 'application/json', ...authHeaders1});
  final subs = Logger.root.onRecord.listen((record) {
    if (record.message.contains('<--')) return; // skip incoming
    //debugPrint(record.toString());
    final ss = record.message.split('header: ');
    assert(ss.length == 2, 'headers isn\'t present');
    if (ss.length > 1) {
      final Map<String, String> headers = Map.fromEntries(
        ss[1].substring(1, ss[1].length - 1).split(', ').map(
          (e) {
            final entry = e.split(': ');
            return MapEntry(entry[0].toLowerCase(), entry[1]);
          },
        ),
      );
      assert(headers['content-type'] == 'application/json', 'Content-type is broken');
      if (show) {
        assert(headers['authorization'] == authHeaders1.values.first, 'Authorization did not shown');
      } else {
        assert(headers['authorization'] != authHeaders1.values.first, 'Authorization did not hidden');
      }
    }
  });
  await client.get('${prefix}a');
  await subs.cancel();
}

Future<void> testBody(bool input, bool show) async {
  final JsonHttpClient client;
  if (input) {
    client = await createClient(config: LoggableHttpClientConfig(logInputBody: show));
  } else {
    client = await createClient(config: LoggableHttpClientConfig(logOutputBody: show));
  }

  server.enqueue(body: 'body', headers: {'Content-type': 'application/json', ...authHeaders1});
  final subs = Logger.root.onRecord.listen((record) {
    if (input) {
      if (record.message.contains('<--')) return; // skip incoming
    } else {
      if (record.message.contains('-->')) return; // skip outgoing
    }

    //debugPrint(record.toString());
    if (show) {
      assert(record.message.contains('body: body'), 'body isn\'t present');
    } else {
      assert(!record.message.contains('body: body'), 'body is present');
    }
  });
  await client.post('${prefix}a', 'body');

  await subs.cancel();
}
