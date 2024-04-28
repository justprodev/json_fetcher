// Created by alex@justprodev.com on 28.04.2024.

import 'package:http/http.dart';
import 'package:json_fetcher/loggable_http_client.dart';
import 'package:json_fetcher/src/auth_info.dart';
import 'package:json_fetcher/src/json_http_client.dart';
import 'package:logging/logging.dart';

const authHeaders1 = {'authorization': 'Bearer 12345'};
const authHeaders2 = {'authorization': 'Bearer 67890'};

Future<JsonHttpClient> createClient({
  Function(String url, Object document)? onFetched,
  LoggableHttpClientConfig? config,
}) async {
  var selectedAuthHeaders = authHeaders1;
  config ??= LoggableHttpClientConfig.full();
  final JsonHttpClient client = JsonHttpClient(
      LoggableHttpClient(Client(), Logger((JsonHttpClient).toString()), config: config),
      auth: AuthInfo((_) => selectedAuthHeaders, (_) async {
        selectedAuthHeaders = authHeaders2;
        return true;
      }),
      onFetched: onFetched,
      onError: (e, t) => Logger.root.severe('Error in JsonHttpClient: $e', e, t));
  await client.cache.emptyCache();
  return client;
}
