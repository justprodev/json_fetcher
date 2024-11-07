// Created by alex@justprodev.com on 27.08.2024.

import 'dart:async';

import 'package:http/http.dart';
import 'package:json_fetcher/json_fetcher.dart';
import 'package:json_fetcher/loggable_http_client.dart';
import 'package:logging/logging.dart';

JsonHttpClient createClient([FutureOr<String>? path]) {
  return JsonHttpClient(
    LoggableHttpClient(
      Client(),
      Logger.root,
      config: const LoggableHttpClientConfig(),
    ),
    createCache(path),
  );
}
