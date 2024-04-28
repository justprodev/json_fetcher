// Created by alex@justprodev.com on 28.04.2024.

import 'package:flutter_test/flutter_test.dart';
import 'package:mock_web_server/mock_web_server.dart';

late MockWebServer server;

String get prefix => server.url;

setUpMockWebServer() {
  setUp(() async {
    server = MockWebServer(port: 8082);
    await server.start();
  });

  tearDown(() async {
    await server.shutdown();
  });
}