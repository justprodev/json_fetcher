// Copyright (c) 2020-2022, alex@justprodev.com.
// All rights reserved. Use of this source code is governed by a
// MIT License that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io' show HttpHeaders, HttpException;

import 'package:http/http.dart' as http;

import 'auth_info.dart';
import 'cache/json_hive_cache.dart';
import 'json_fetcher_exception.dart';
import 'json_cache.dart';
import 'json_http_fetcher.dart';

enum _HttpAction { get, post, put, delete }

/// Client especially for fetching json from host(s)
/// [cache] can be used to directly control the cache (i.e. [JsonCache.emptyCache]/[JsonCache.evict])
class JsonHttpClient {
  final http.Client _client;
  final AuthInfo? auth;
  final Function(Object error, StackTrace trace)? onError;

  /// cache manager used by [JsonHttpFetcher]
  late JsonCache _cache = JsonHiveCache((url, headers) async {
    final response = await get(url, headers: headers);
    return response.body;
  });

  JsonHttpClient(this._client, {this.auth, this.onError});

  Future<http.Response> post(String url, String json, {Map<String,String>? headers, skipCheckingExpiration: false}) async {
    return await _callHttpAction(_HttpAction.post, url, json, headers: headers, skipCheckingExpiration: skipCheckingExpiration);
  }

  Future<http.Response> put(String url, String json, {Map<String,String>? headers, skipCheckingExpiration: false}) async {
    return await _callHttpAction(_HttpAction.put, url, json, headers: headers, skipCheckingExpiration: skipCheckingExpiration);
  }

  Future<http.Response> get(String url, {Map<String,String>? headers, skipCheckingExpiration: false}) async {
    return await _callHttpAction(_HttpAction.get, url, null, headers: headers, skipCheckingExpiration: skipCheckingExpiration);
  }

  Future<http.Response> delete(String url, {Map<String,String>? headers, skipCheckingExpiration: false}) async {
    return await _callHttpAction(_HttpAction.delete, url, null, headers: headers, skipCheckingExpiration: skipCheckingExpiration);
  }

  void logout() => auth?.onExpire.call(true);

  JsonCache get cache => _cache;

  Future<http.Response> _callHttpAction(
      _HttpAction actionType,
      String url, String? json,
      {Map<String,String>? headers, skipCheckingExpiration: false}
  ) async {
    late Future<http.Response> Function() action;

    Future<http.Response> makeRequest() async {
      final Map<String, String> h = {"Content-Type": "application/json"};
      final authHeaders = auth?.headers();
      if(authHeaders!=null) h.addAll(authHeaders);
      if(headers!=null) h.addAll(headers);

      final response;
      switch(actionType) {
        case _HttpAction.get: response = await _client.get(Uri.parse(url), headers: h); break;
        case _HttpAction.post: response = await _client.post(Uri.parse(url), body: json, headers: h); break;
        case _HttpAction.put: response = await _client.put(Uri.parse(url), body: json, headers: h); break;
        case _HttpAction.delete: response = await _client.delete(Uri.parse(url), body: json, headers: h); break;
      }
      return response;
    }

    action = () async {
      http.Response? response;
      try {
        response = await makeRequest();
        final String contentType = response.headers[HttpHeaders.contentTypeHeader] ?? "application/json";
        if(!contentType.contains("charset")) response.headers[HttpHeaders.contentTypeHeader] = contentType + ";charset=utf-8";
        if (response.statusCode < 200 || response.statusCode >= 400) {
          /// for 401 error we silently invoke onExpire handler
          if (response.statusCode==401 && auth!=null && !skipCheckingExpiration) {
            final refreshed = await _onExpire();                // refresh auth data
            if(refreshed) {
              return await action();                                           // resubmit latest call & return here because error handled inside action (thrown, etc)
            } else {
              // logout
              await auth!.onExpire.call(true);
            }
          } else {
            throw HttpException('', uri: response.request?.url);
          }
        }
        return response;
      } catch(e, trace) {
        String message = 'Error while ${actionType.name} $url ${json!=null?'($json)':''}';
        if(response!=null) message += ': code=${response.statusCode} body=${response.body}';
        final error = JsonFetcherException(url, message, e, response: response, trace: trace);
        onError?.call(error, trace);
        throw error;
      }
    };

    return await action();
  }

  /// process onExpire calls in one place
  /// to make additional routing, to prevent extra calls and etc
  Future<bool> _onExpire() {
    // any case
    if(auth == null) return Future.value(false);

    // when we already waiting onExpire() call, then don't create new one,
    // instead we will return the same call
    final oldCall = _onExpireFuture;
    if(oldCall != null) return oldCall;

    // create only if not exists
    final newCall = auth!.onExpire.call(false);
    // inform everyone that we are ready for a new call, when old is complete
    newCall.whenComplete(() => _onExpireFuture = null);
    _onExpireFuture = newCall;
    return newCall;
  }

  Future<bool>? _onExpireFuture;
}


