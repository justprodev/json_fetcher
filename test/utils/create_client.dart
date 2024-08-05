// Created by alex@justprodev.com on 28.04.2024.

import 'package:http/http.dart';
import 'package:json_fetcher/loggable_http_client.dart';
import 'package:json_fetcher/src/cache/http_cache_io_impl.dart' as io_cache_impl;
import 'package:json_fetcher/src/http_cache.dart';
import 'package:json_fetcher/src/json_http_client.dart';
import 'package:logging/logging.dart';

const authHeaders1 = {'authorization': 'Bearer 12345'};
const authHeaders2 = {'authorization': 'Bearer 67890'};

Future<JsonHttpClient> createClient({
  Function(String url, Object document)? onFetched,
  LoggableHttpClientConfig? config,
  HttpCache? cache,
  Client? rawClient,
}) async {
  var selectedAuthHeaders = authHeaders1;
  config ??= LoggableHttpClientConfig.full();
  final JsonHttpClient client = JsonHttpClient(
    LoggableHttpClient(rawClient ?? Client(), Logger((JsonHttpClient).toString()), config: config),
    cache ?? io_cache_impl.createCache('temp'),
    globalHeaders: (_) => selectedAuthHeaders,
    onExpire: (_) async {
      selectedAuthHeaders = authHeaders2;
      return true;
    },
    onFetched: onFetched,
    onError: (e, t) => Logger.root.severe('Error in JsonHttpClient: $e', e, t),
  );
  await client.cache.emptyCache();
  return client;
}
