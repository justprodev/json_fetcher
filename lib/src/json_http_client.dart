// Copyright (c) 2020, alex@justprodev.com.
// All rights reserved. Use of this source code is governed by a
// MIT License that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io' show HttpHeaders, HttpException;

import 'package:http/http.dart' as http;
import 'package:json_fetcher/src/util/http.dart';

import 'auth_info.dart';
import 'cache/json_hive_cache.dart';
import 'json_cache.dart';
import 'json_fetcher_exception.dart';
import 'json_http_fetcher.dart';

/// Client especially for fetching json from host(s)
class JsonHttpClient {
  /// delegated [http.Client] which will be used for all requests
  final http.Client _client;
  final AuthInfo? auth;

  // register all errors, include parse errors in a fetchers
  final Function(Object error, StackTrace? trace)? onError;

  /// called when new document came from network and parsed
  final Function(String url, Object document)? onFetched;

  /// cache manager used by [JsonHttpFetcher]
  late final JsonCache _cache = JsonHiveCache((url, headers) async {
    final response = await get(url, headers: headers);
    return response.body;
  }, onError);

  JsonHttpClient(this._client, {this.auth, this.onError, this.onFetched});

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

  void logout() => auth?.onExpire.call(true);

  /// can be used to directly control the cache (i.e. [JsonCache.emptyCache]/[JsonCache.evict])
  JsonCache get cache => _cache;

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
        final authHeaders = auth?.headers(url);
        if (authHeaders != null) request.headers.addAll(authHeaders);
        return await _client.send(request).then(http.Response.fromStream);
      } else {
        final Map<String, String> h = {"Content-Type": "application/json"};
        final authHeaders = auth?.headers(url);
        if (authHeaders != null) h.addAll(authHeaders);
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
          if (response.statusCode == 401 && auth != null && !skipCheckingExpiration) {
            final refreshed = await _onExpire(); // refresh auth data
            if (refreshed) {
              return await action(); // resubmit latest call & return here because error handled inside action (thrown, etc)
            } else {
              // logout
              await auth!.onExpire.call(true);
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
    // any case
    if (auth == null) return Future.value(false);

    // when we already waiting onExpire() call, then don't create new one,
    // instead we will return the same call
    final oldCall = _onExpireFuture;
    if (oldCall != null) return oldCall;

    // create only if not exists
    final newCall = auth!.onExpire.call(false);
    // inform everyone that we are ready for a new call, when old is complete
    newCall.whenComplete(() => _onExpireFuture = null);
    _onExpireFuture = newCall;
    return newCall;
  }

  Future<bool>? _onExpireFuture;
}
