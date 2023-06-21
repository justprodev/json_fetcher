// Copyright (c) 2020, alex@justprodev.com.
// All rights reserved. Use of this source code is governed by a
// MIT License that can be found in the LICENSE file.


import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart';
import 'package:json_fetcher/json_fetcher.dart';
import 'package:json_fetcher/standard_fetchers.dart';
import 'package:mock_web_server/mock_web_server.dart';

import 'fake_path_provider.dart';

void main() {
  setUpFakePathProvider();
  late JsonHttpClient client;
  late MockWebServer server;

  setUp(() async {
    server = MockWebServer(port: 8082);
    await server.start();
    client = JsonHttpClient(Client());
  });

  tearDown(() async {
    await server.shutdown();
    await client.cache.emptyCache();
  });

  test('plain', () async {
    server.enqueue(body: 'true');

    await for(final ok in PlainFetcher<bool>(client).fetch(server.url)) {
      assert(ok, true);
    }
  });
}
