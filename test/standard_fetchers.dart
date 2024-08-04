// Copyright (c) 2020, alex@justprodev.com.
// All rights reserved. Use of this source code is governed by a
// MIT License that can be found in the LICENSE file.


import 'package:test/test.dart';
import 'package:json_fetcher/standard_fetchers.dart';

import 'utils/create_client.dart';
import 'utils/mock_web_server.dart';

void main() {
  setUpMockWebServer();

  test('plain', () async {
    final client = await createClient();
    server.enqueue(body: 'true');

    await for(final ok in PlainFetcher<bool>(client).fetch(server.url)) {
      assert(ok, true);
    }
  });
}
