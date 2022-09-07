// Copyright (c) 2020, alex@justprodev.com.
// All rights reserved. Use of this source code is governed by a
// MIT License that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart';
import 'package:json_fetcher/json_fetcher.dart';
import 'package:json_fetcher/loggable_http_client.dart';
import 'package:logging/logging.dart';
import 'package:mock_web_server/mock_web_server.dart';

import 'fake_path_provider.dart';

void main() {
  setUpFakePathProvider();

  final Map<String,String> authHeaders1 = {'authorization': 'Bearer 12345'};
  final Map<String,String> authHeaders2 = {'authorization': 'Bearer 67890'};

  final r = Random();
  String bigString() => List.generate(longJsonFieldLength, (index) => r.nextBool() ? 'A' : 'B').join('');
  List<String> bigArray() => List.generate(longBodyLength~/longJsonFieldLength, (index) => '"${bigString()}"');

  JsonHttpClient createClient({cutLongBody = false}) {
    var selectedAuthHeaders = authHeaders1;
    final JsonHttpClient client = JsonHttpClient(
        LoggableHttpClient(Client(), Logger((JsonHttpClient).toString()), cutLongBody: cutLongBody),
        auth: AuthInfo(() => selectedAuthHeaders, (bool) async { selectedAuthHeaders = authHeaders2; return true; })
    );
    client.cache.emptyCache();
    return client;
  }

  test('logging big json', () async {
    final JsonHttpClient client = createClient(cutLongBody: true);
    final MockWebServer server = new MockWebServer(port: 8082);
    await server.start();

    final String prefix = server.url;

    final String bigJson = '{ "data": [${bigArray().join(',')}] }';

    // post big json
    server.enqueue(body: 'test response body');
    Logger.root.onRecord.listen((record) {
      int i = record.message.indexOf('{ "data');
      if(i > 0) {
        final Map big = json.decode(bigJson);
        final Map cut = json.decode(record.message.substring(i));

        expect(cut['data'].length == big['data'].length, true);

        var j = 0;
        for(final String fCut in cut['data']) {
          final fBig = big['data'][j++];
          final subs = fCut.split('...');
          expect(fBig.startsWith(subs[0]), true);
          expect(fBig.endsWith(subs[1]), true);
          expect(fBig.length > fCut.length, true);
        }
      }
    });
    await client.post(prefix+'a', bigJson, headers: {'Content-Type': 'application/json'});

    await server.shutdown();
  });

  test('logging plain', () async {
    final JsonHttpClient client = createClient(cutLongBody: true);
    final MockWebServer server = new MockWebServer(port: 8082);
    await server.start();

    final String prefix = server.url;

    final String bigPlain = '${bigArray().join(',')}';

    // post big plain
    server.enqueue(body: bigPlain);
    Logger.root.onRecord.listen((record) {
      final ss = record.message.split('body: ');
      if(ss.length > 2) {
        final String cut = ss[1];

        final subs = cut.split('...');
        expect(bigPlain.startsWith(subs[0]), true);
        expect(bigPlain.length > cut.length, true);
      }
    });
    await client.get(prefix+'a');

    await server.shutdown();
  });
}
