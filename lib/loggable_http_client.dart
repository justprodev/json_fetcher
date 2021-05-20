/// Created by alex@justprodev.com on 20.05.2021.
import 'dart:convert';

import 'package:http/http.dart';
import 'package:logging/logging.dart';

/// Created by alex@justprodev.com on 20.05.2021.

/// utility for logging HTTP requests/responses
class LoggableHttpClient extends BaseClient {
  final Client _delegate;
  final Logger _logger;

  LoggableHttpClient(this._delegate, this._logger);

  @override
  void close() {
    _delegate.close();
  }

  @override
  Future<StreamedResponse> send(BaseRequest request) async {
    String s = "${request.method} ${request.url} -->";
    s += "\nheader: ${request.headers}";
    if(request is Request && request.body.length>0) {
      s += "\nbody: ${request.body}";
    }
    _logger.info(s);
    final response =  await _delegate.send(request);
    s = "${request.method} ${request.url} <--";
    s += "\nheader: ${response.headers}";

    // Simple request
    if(request is Request) {
      final List<int> bytes = await response.stream.toBytes();
      s += "\nbody: ${await utf8.decode(bytes)}";
      _logger.info(s);

      return StreamedResponse(
          ByteStream.fromBytes(bytes),
          response.statusCode,
          contentLength: response.contentLength,
          request: request,
          headers: response.headers,
          isRedirect: response.isRedirect,
          persistentConnection: response.persistentConnection,
          reasonPhrase: response.reasonPhrase
      );
    }

    _logger.info(s);

    return response;
  }
}

