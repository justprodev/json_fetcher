// Copyright (c) 2020, alex@justprodev.com.
// All rights reserved. Use of this source code is governed by a
// MIT License that can be found in the LICENSE file.

import 'package:http/http.dart';
import 'package:logging/logging.dart';

import 'src/http_logger.dart';

/// [LoggableHttpClient] is a wrapper around [Client] that logs all requests and responses.
///
/// [config] - configure "What to log"
class LoggableHttpClient extends BaseClient {
  final Client _delegate;
  final LoggableHttpClientConfig config;
  late final HttpLogger _httpLogger;

  LoggableHttpClient(this._delegate, Logger _logger, {this.config = const LoggableHttpClientConfig()}) {
    _httpLogger = HttpLogger(_logger, config);
  }

  @override
  void close() => _delegate.close();

  @override
  Future<StreamedResponse> send(BaseRequest request) async {
    _httpLogger.logRequest(request);

    StreamedResponse response = await _delegate.send(request);

    // Simple request & need log body
    if ((request is Request || request is MultipartRequest) && (config.logOutputBody || response.statusCode >= 400)) {
      final bytes = await response.stream.toBytes();
      _httpLogger.logResponse(request, response, bytes);

      // recreate response with new stream, because old stream is already consumed
      response = StreamedResponse(
        ByteStream.fromBytes(bytes),
        response.statusCode,
        contentLength: response.contentLength,
        request: request,
        headers: response.headers,
        isRedirect: response.isRedirect,
        persistentConnection: response.persistentConnection,
        reasonPhrase: response.reasonPhrase,
      );
    } else {
      _httpLogger.logResponse(request, response);
    }

    return response;
  }
}

/// Configure "What to log" in [LoggableHttpClient]
class LoggableHttpClientConfig {
  final bool logInputBody;
  final bool logOutputBody;
  final bool logInputHeaders;
  final bool logOutputHeaders;
  final bool hideAuthorization;
  final bool cutLongBody;

  const LoggableHttpClientConfig({
    this.logInputBody = true,
    this.logOutputBody = false,
    this.hideAuthorization = true,
    this.cutLongBody = true,
    this.logInputHeaders = true,
    this.logOutputHeaders = true,
  });

  factory LoggableHttpClientConfig.full() {
    return const LoggableHttpClientConfig(
      logInputBody: true,
      logOutputBody: true,
      hideAuthorization: false,
      cutLongBody: false,
    );
  }
}
