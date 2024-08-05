// Copyright (c) 2020, alex@justprodev.com.
// All rights reserved. Use of this source code is governed by a
// MIT License that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io' show HttpHeaders, HttpException;

import 'package:http/http.dart' as http;
import 'package:json_fetcher/src/util/http.dart';

import 'http_cache.dart';
import 'json_fetcher_exception.dart';
import 'json_http_fetcher.dart';

/// Client especially for fetching json from host(s)
///
/// Example of usage:
/// ```dart
///
/// import 'package:json_fetcher/json_fetcher.dart';
/// import 'package:http/http.dart' as http;
///
/// final client = JsonHttpClient(http.Client(), createCache());
///
/// ```
///
class JsonHttpClient {
  /// delegated [http.Client] which will be used for all requests
  final http.Client _client;

  /// cache manager used by [JsonHttpFetcher]
  /// can be used to directly control the cache (i.e. [HttpCache.emptyCache]/[HttpCache.evict])
  final HttpCache cache;

  // to catch all errors
  final Function(Object error, StackTrace? trace)? onError;

  /// called when new document came from network and parsed
  final Function(String url, Object document)? onFetched;

  /// These headers will be applied to all requests
  ///
  /// [url] requested url
  final Map<String, String> Function(String url)? globalHeaders;

  /// Will be called for 401 error ([authHeaders] will be removed from the header immediately),
  ///
  /// [logout]==true means that handler was called  at second, because a new auth data is wrong,
  ///  and We probably should redirect to login page
  ///
  /// MUST return true if token is refreshed successfully
  final Future<bool> Function(bool logout)? onExpire;

  JsonHttpClient(
    this._client,
    this.cache, {
    this.globalHeaders,
    this.onExpire,
    this.onError,
    this.onFetched,
  });

  Future<http.Response> post(String url, String json, {Map<String, String>? headers, skipCheckingExpiration = false}) =>
      _send('POST', url, json, headers: headers, skipCheckingExpiration: skipCheckingExpiration);

  Future<http.Response> put(String url, String json, {Map<String, String>? headers, skipCheckingExpiration = false}) =>
      _send('PUT', url, json, headers: headers, skipCheckingExpiration: skipCheckingExpiration);

  Future<http.Response> get(String url, {String? json, Map<String, String>? headers, skipCheckingExpiration = false}) =>
      _send('GET', url, json, headers: headers, skipCheckingExpiration: skipCheckingExpiration);

  Future<http.Response> delete(String url, {Map<String, String>? headers, skipCheckingExpiration = false}) =>
      _send('DELETE', url, null, headers: headers, skipCheckingExpiration: skipCheckingExpiration);

  Future<http.Response> patch(String url, String json,
          {Map<String, String>? headers, skipCheckingExpiration = false}) =>
      _send('PATCH', url, json, headers: headers, skipCheckingExpiration: skipCheckingExpiration);

  /// upload files using POST method
  ///
  /// [fields] - additional fields for multipart request
  Future<http.Response> postUpload(String url, List<http.MultipartFile> files,
          {Map<String, String>? headers, skipCheckingExpiration = false, Map<String, String>? fields}) =>
      _send('POST', url, null,
          headers: headers, skipCheckingExpiration: skipCheckingExpiration, files: files, fields: fields);

  /// initiate logout
  void logout() => onExpire?.call(true);

  /// So, basically is just wrapper over [BaseClientExt.sendUnstreamed] which:
  ///
  /// 1. handles auth
  /// 3. handles errors
  Future<http.Response> _send(
    String method,
    String url,
    String? json, {
    Map<String, String>? headers,
    skipCheckingExpiration = false,
    // MultipartRequest
    List<http.MultipartFile>? files,
    Map<String, String>? fields,
  }) async {
    late Future<http.Response> Function() action;

    Future<http.Response> makeRequest() async {
      if (files != null) {
        final request = http.MultipartRequest(method, Uri.parse(url));
        if (fields != null) request.fields.addAll(fields);
        request.headers.addAll(headers ?? {});
        request.files.addAll(files);
        if (globalHeaders != null) request.headers.addAll(globalHeaders!(url));
        return await _client.send(request).then(http.Response.fromStream);
      } else {
        final Map<String, String> h = {"Content-Type": "application/json"};
        if (globalHeaders != null) h.addAll(globalHeaders!(url));
        if (headers != null) h.addAll(headers);
        return _client.sendUnstreamed(method, Uri.parse(url), h, json);
      }
    }

    action = () async {
      http.Response? response;
      try {
        response = await makeRequest();
        final String contentType = response.headers[HttpHeaders.contentTypeHeader] ?? "application/json";
        if (!contentType.contains("charset")) {
          response.headers[HttpHeaders.contentTypeHeader] = "$contentType;charset=utf-8";
        }
        if (response.statusCode < 200 || response.statusCode >= 400) {
          /// for 401 error we silently invoke onExpire handler
          if (response.statusCode == 401 && onExpire != null && !skipCheckingExpiration) {
            final refreshed = await _onExpire(); // refresh auth data
            if (refreshed) {
              return await action(); // resubmit latest call & return here because error handled inside action (thrown, etc)
            } else {
              // logout
              await onExpire!(true);
              throw HttpException('401', uri: response.request?.url);
            }
          } else {
            throw HttpException('', uri: response.request?.url);
          }
        }
        return response;
      } catch (e, trace) {
        String message = 'Error while $method $url';
        if (response != null) message += ': code=${response.statusCode} body=${response.body}';
        final error = JsonFetcherException(url, message, e, response: response, trace: trace);
        onError?.call(error, trace);
        throw error;
      }
    };

    assert(json == null || files == null, 'You can send either json or files, but not both');

    return await action();
  }

  /// process onExpire calls in one place
  /// to make additional routing, to prevent extra calls and etc
  Future<bool> _onExpire() {
    if (onExpire == null) return Future.value(false);

    // when we already waiting onExpire() call, then don't create new one,
    // instead we will return the same call
    final oldCall = _onExpireFuture;
    if (oldCall != null) return oldCall;

    // create only if not exists
    final newCall = onExpire!.call(false);
    // inform everyone that we are ready for a new call, when old is complete
    newCall.whenComplete(() => _onExpireFuture = null);
    _onExpireFuture = newCall;
    return newCall;
  }

  Future<bool>? _onExpireFuture;
}
