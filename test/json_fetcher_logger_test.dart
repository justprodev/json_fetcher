// Copyright (c) 2020, alex@justprodev.com.
// All rights reserved. Use of this source code is governed by a
// MIT License that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:json_fetcher/json_fetcher.dart';
import 'package:json_fetcher/loggable_http_client.dart';
import 'package:logging/logging.dart';

import 'utils/create_client.dart';
import 'utils/fake_path_provider.dart';
import 'utils/mock_web_server.dart';

void main() {
  setUpFakePathProvider();
  setUpMockWebServer();

  final r = Random();
  String bigString() => List.generate(longJsonFieldLength, (index) => r.nextBool() ? 'A' : 'B').join('');
  List<String> bigArray() => List.generate(longBodyLength ~/ longJsonFieldLength, (index) => '"${bigString()}"');

  test('cut big json body', () async {
    final client = await createClient(config: const LoggableHttpClientConfig(cutLongBody: true));
    final String bigJson = '{ "data": [${bigArray().join(',')}] }';

    // post big json
    server.enqueue(body: 'test response body');
    final subs = Logger.root.onRecord.listen((record) {
      int i = record.message.indexOf('{ "data');
      if (i > 0) {
        final Map big = json.decode(bigJson);
        final Map cut = json.decode(record.message.substring(i));

        expect(cut['data'].length == big['data'].length, true);

        var j = 0;
        for (final String fCut in cut['data']) {
          final fBig = big['data'][j++];
          final subs = fCut.split('...');
          expect(fBig.startsWith(subs[0]), true);
          expect(fBig.endsWith(subs[1]), true);
          expect(fBig.length > fCut.length, true);
        }
      }
    });
    await client.post('${prefix}a', bigJson, headers: {'Content-Type': 'application/json'});
    await subs.cancel();
  });

  test('cut big plain body', () async {
    final client = await createClient(config: const LoggableHttpClientConfig(cutLongBody: true));
    final String bigPlain = bigArray().join(',');

    // post big plain
    server.enqueue(body: bigPlain);
    final subs = Logger.root.onRecord.listen((record) {
      final ss = record.message.split('body: ');
      if (ss.length > 1) {
        final String cut = ss[1];

        final subs = cut.split('...');
        expect(bigPlain.startsWith(subs[0]), true);
        expect(bigPlain.length > cut.length, true);
      }
    });
    await client.get('${prefix}a');

    await subs.cancel();
  });

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

  test('hide auth', () async {
    await testAuth(false);
  });

  test('show auth', () async {
    await testAuth(true);
  });

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

  test('log input body', () async {
    await testBody(true, true);
  });

  test('no log input body', () async {
    await testBody(true, false);
  });

  test('log output body', () async {
    await testBody(false, true);
  });

  test('no log output body', () async {
    await testBody(false, false);
  });
}
