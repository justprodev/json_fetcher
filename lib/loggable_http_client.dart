// Copyright (c) 2020, alex@justprodev.com.
// All rights reserved. Use of this source code is governed by a
// MIT License that can be found in the LICENSE file.
import 'dart:convert';
import 'dart:isolate';

import 'dart:io' show HttpHeaders;

import 'package:http/http.dart';
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';

@visibleForTesting
const longBodyLength = 100000; // 100kB
@visibleForTesting
const longJsonFieldLength = 10000; // 10kB
@visibleForTesting
const normalJsonFieldLength = 1000; // 1kB

@visibleForTesting
const threeDotsString = '...';

/// utility for logging HTTP requests/responses
class LoggableHttpClient extends BaseClient {
  final Client _delegate;
  final Logger _logger;
  final LoggableHttpClientConfig config;

  LoggableHttpClient(this._delegate, this._logger, {this.config = const LoggableHttpClientConfig()});

  @override
  void close() {
    _delegate.close();
  }

  @override
  Future<StreamedResponse> send(BaseRequest request) async {
    String s = "${request.method} ${request.url} -->";
    s += "\nheader: ${config.hideAuthorization ? _hideAuthorization(request.headers) : request.headers}";
    if (config.logInputBody && request is Request && request.body.isNotEmpty) {
      s += "\nbody: ${await _smartCut(request.headers[HttpHeaders.contentTypeHeader], request.body)}";
    }
    _logger.info(s);

    final response = await _delegate.send(request);
    s = "${request.method} ${request.url} <-- ${response.statusCode}";
    s += "\nheader: ${config.hideAuthorization ? _hideAuthorization(response.headers) : response.headers}";

    // Simple request
    if (request is Request || request is MultipartRequest) {
      final List<int> bytes = await response.stream.toBytes();
      if (config.logOutputBody || response.statusCode >= 400) {
        s += "\nbody: ${await _smartCut(request.headers[HttpHeaders.contentTypeHeader], utf8.decode(bytes))}";
      }
      _logger.info(s);

      return StreamedResponse(ByteStream.fromBytes(bytes), response.statusCode,
          contentLength: response.contentLength,
          request: request,
          headers: response.headers,
          isRedirect: response.isRedirect,
          persistentConnection: response.persistentConnection,
          reasonPhrase: response.reasonPhrase);
    }

    _logger.info(s);

    return response;
  }

  Map<String, String> _hideAuthorization(Map<String, String> headers) {
    final entries = headers.entries.map(
      (e) => e.key.toLowerCase() == 'authorization' ? MapEntry(e.key, threeDotsString) : e,
    );
    return Map.fromEntries(entries);
  }

  // cut a body if necessary (cut a long json values or full body)
  Future<String> _smartCut(String? contentType, String body) async {
    if (config.cutLongBody && body.length > longBodyLength) {
      if (contentType?.contains('/json') == true) {
        return Isolate.run(() => _smartCutJson(body));
      } else {
        return "${body.substring(0, longBodyLength)}$threeDotsString";
      }
    } else {
      return body;
    }
  }

  static String _smartCutJson(String body) {
    return body.replaceAllMapped(
      RegExp(r'"[^"]+"'),
      (match) {
        final field = match.group(0) ?? '';
        if (field.length > longJsonFieldLength) {
          return '${field.substring(0, normalJsonFieldLength ~/ 2)}$threeDotsString${field.substring(field.length - normalJsonFieldLength ~/ 2)}';
        } else {
          return field;
        }
      },
    );
  }
}

/// Configure "What to log" in [LoggableHttpClient]
/// input - is look from server side
class LoggableHttpClientConfig {
  final bool logInputBody;
  final bool logOutputBody;
  final bool hideAuthorization;
  final bool cutLongBody;

  const LoggableHttpClientConfig({
    this.logInputBody = true,
    this.logOutputBody = false,
    this.hideAuthorization = true,
    this.cutLongBody = true,
  });

  factory LoggableHttpClientConfig.full() => const LoggableHttpClientConfig(
      logInputBody: true, logOutputBody: true, hideAuthorization: false, cutLongBody: false);
}
