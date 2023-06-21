// Copyright (c) 2020, alex@justprodev.com.
// All rights reserved. Use of this source code is governed by a
// MIT License that can be found in the LICENSE file.
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart';
import 'package:logging/logging.dart';

const longBodyLength = 100000; // 100kB
const longJsonFieldLength = 10000; // 10kB
const normalJsonFieldLength = 1000; // 1kB

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
    if (config.logInputBody && request is Request && request.body.length > 0) {
      s += "\nbody: ${await _smartCut(request.headers['Content-Type'], request.body)}";
    }
    _logger.info(s);

    final response = await _delegate.send(request);
    s = "${request.method} ${request.url} <-- ${response.statusCode}";
    s += "\nheader: ${config.hideAuthorization ? _hideAuthorization(response.headers) : response.headers}";

    // Simple request
    if (request is Request) {
      final List<int> bytes = await response.stream.toBytes();
      if (config.logOutputBody || response.statusCode>=400)
        s +=
            "\nbody: ${await _smartCut(response.headers['Content-Type'] ?? response.headers['content-type'], utf8.decode(bytes))}";
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
    final entries = headers.entries.map((e) => e.key.toLowerCase() == 'authorization' ? MapEntry(e.key, '...') : e);
    return Map.fromEntries(entries);
  }

  // cut a body if necessary (cut a long json values or full body)
  Future<String> _smartCut(String? contentType, String body) async {
    if (config.cutLongBody && body.length > longBodyLength) {
      if (contentType?.contains('/json') == true) {
        return compute(_smartCutJson, body);
      } else {
        return body.substring(0, longBodyLength) + "...";
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
          return field.substring(0, normalJsonFieldLength ~/ 2) +
              '...' +
              field.substring(field.length - normalJsonFieldLength ~/ 2);
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
    logInputBody: true,
    logOutputBody: true,
    hideAuthorization: false,
    cutLongBody: false
  );
}
