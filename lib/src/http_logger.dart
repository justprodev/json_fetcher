// Created by alex@justprodev.com on 17.08.2024.

import 'dart:convert';
import 'dart:io' show HttpHeaders;
import 'dart:isolate';
import 'dart:typed_data';

import 'package:http/http.dart';
import 'package:logging/logging.dart';

import '../loggable_http_client.dart' show LoggableHttpClientConfig;

const longBodyLength = 100000; // 100kB
const longJsonFieldLength = 10000; // 10kB
const normalJsonFieldLength = 1000; // 1kB
const threeDotsString = '...';

/// Logger for HTTP requests and responses.
/// It logs only headers and body if it is necessary.
/// It can cut long bodies and long json fields.
class HttpLogger {
  final Logger _logger;
  final LoggableHttpClientConfig config;

  const HttpLogger(this._logger, this.config);

  Future<void> logRequest(BaseRequest request) async {
    String s = "${request.method} ${request.url} -->";
    s += "\nheader: ${config.hideAuthorization ? _hideAuthorization(request.headers) : request.headers}";
    if (config.logInputBody && request is Request && request.body.isNotEmpty) {
      s += "\nbody: ${await _smartCut(request.headers[HttpHeaders.contentTypeHeader], request.body)}";
    }
    _logger.info(s);
  }

  Future<void> logResponse(BaseRequest request, BaseResponse response, [Uint8List? bytes]) async {
    String s = "${request.method} ${request.url} <-- ${response.statusCode}";
    s += "\nheader: ${config.hideAuthorization ? _hideAuthorization(response.headers) : response.headers}";

    // need log body
    if (bytes != null) {
        s += "\nbody: ${await _smartCut(request.headers[HttpHeaders.contentTypeHeader], utf8.decode(bytes))}";
    }

    _logger.info(s);
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
