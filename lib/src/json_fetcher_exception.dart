import 'package:http/http.dart' show Response;

import 'util/exception/not_reachable_stub.dart'
    if (dart.library.js_interop) 'util/exception/not_reachable_web.dart'
    if (dart.library.io) 'util/exception/not_reachable_io.dart';

/// Created by alex@justprodev.com on 19.06.2022.

class JsonFetcherException {
  final Response? response;
  final String message;
  final Object? error;
  final String url;
  final StackTrace? trace;

  const JsonFetcherException(this.url, this.message, this.error, {this.response, this.trace});

  @override
  String toString() => '$url: $message (${response?.statusCode ?? ''} ${response?.reasonPhrase ?? ''} $error)';

  int? get statusCode => response?.statusCode;

  String? get body => response?.body;

  bool get notReachable {
    if (response != null) return false;

    return isNotReachable(error);
  }
}
