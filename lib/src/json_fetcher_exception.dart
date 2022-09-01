import 'dart:io' show IOException;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' show ClientException, Response;

/// Created by alex@justprodev.com on 19.06.2022.

class JsonFetcherException {
  final Response? response;
  final String message;
  final Object? error;
  final String url;
  final StackTrace? trace;

  JsonFetcherException(this.url, this.message, this.error, {this.response, this.trace});

  String toString() => '$url: $message (${response?.statusCode??''} ${response?.reasonPhrase??''} $error)';

  int? get statusCode => response?.statusCode;
  String? get body => response?.body;

  bool get notReachable {
    if(response!=null) return false;

    return error is IOException || error is ClientException;
  }
}
