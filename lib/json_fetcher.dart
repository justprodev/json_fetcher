// Copyright (c) 2020, alex@justprodev.com.
// All rights reserved. Use of this source code is governed by a
// MIT License that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';

import 'cache/hive.dart';

///
/// Universal fetcher for JSON by HTTP
///
abstract class HttpJsonFetcher<T> {
  final JsonHttpClient _client;
  int _step = 0;

  HttpJsonFetcher(this._client);

  /// implement me: returns object parsed from json
  Future<T> parse(String source);

  /// set [allowErrorWhenCacheExists] to true if you want to see network errors always
  /// by default, if cached version is available then errors will not be pushed to stream
  /// [nocache] skip cached version
  Stream<T> fetch(String url, {allowErrorWhenCacheExists: false, nocache: false}) {
    StreamController<T> controller = StreamController();

    controller.onListen = () {
      StreamSubscription<String> subscription = _client._fetch(url, allowErrorWhenCacheExists: allowErrorWhenCacheExists, nocache: nocache).listen(null,
          onError: controller.addError, // Avoid Zone error replacement.
          onDone: controller.close);
      FutureOr<Null> add(T value) {
        controller.add(value);
      }

      final addError = controller.addError;
      final resume = subscription.resume;
      subscription.onData((String jsonString) {
        Future<T> newValue;
        try {
          newValue = _parse(url, jsonString);
        } catch (e, s) {
          if(_step>0) controller.addError(e, s); // add errors only when data came from Internet
          return;
        }
        subscription.pause();
        newValue.then(add, onError: addError).whenComplete(resume);
      });
      controller.onCancel = subscription.cancel;
      controller
        ..onPause = subscription.pause
        ..onResume = resume;
    };
    return controller.stream;
  }

  /// just get without caching
  Future<T> get(String url, {Map<String,String>? headers}) async {
    final String jsonString = (await _client.get(url, headers: headers, throwError: true)).body;
    return await _parse(url, jsonString);
  }

  Future<T> _parse(String url, String source) async {
    final o = await parse(source);
    if(_step>0) _client._fetchHandler?.call(url, o);
    _step++;
    return o;
  }
}

enum _HTTP_ACTION { get, post, put, delete }

/// Used when [JsonHttpClient] operates with services which are needs authentication
class AuthInfo {
  /// provide permanent headers across [JsonHttpClient]
  final Map<String,String>? Function() headers;
  /// Will be called for 401 error ([authHeaders] will be removed from the header immediately),
  /// `isRepeat`==true means that handler was called  at second, because a new auth data is wrong (refreshToken can't succeeded or etc),
  ///  and We probably should redirect to login page
  /// returns: true if toke is refreshed
  final Future<bool> Function(bool logout) onExpire;

  AuthInfo(this.headers, this.onExpire);
}

/// Client especially for fetching json from host(s)
/// [cache] can be used to directly control the cache (i.e. [JsonCache.emptyCache]/[JsonCache.evict])
class JsonHttpClient {
  final http.Client _client;
  final AuthInfo? auth;
  /// cache manager used by [HttpJsonFetcher]
  late JsonCache _cache = JsonHiveCache(this);

  static final _log = Logger((JsonHttpClient).toString());

  Function(String url, dynamic document)? _fetchHandler;

  JsonHttpClient(this._client, {this.auth});

  /// [handler] will be called when [HttpJsonFetcher] completes parsing an document
  /// which was fetched from [url] from network (not from cache!)
  /// Please be sure, that handler works fast as possible (do heavy operations async)
  void setFetchHandler(Function(String url, dynamic document) handler) {
    _fetchHandler = handler;
  }

  /// [throwError] if true then http error will be thrown as [HttpClientException]
  Future<http.Response> post(String url, String json, {Map<String,String>? headers, throwError: true, skipCheckingExpiration: false}) async {
    return await _callHttpAction(_HTTP_ACTION.post, url, json, headers: headers, throwError: throwError, skipCheckingExpiration: skipCheckingExpiration);
  }

  Future<http.Response> put(String url, String json, {Map<String,String>? headers, throwError: true, skipCheckingExpiration: false}) async {
    return await _callHttpAction(_HTTP_ACTION.put, url, json, headers: headers, throwError: throwError, skipCheckingExpiration: skipCheckingExpiration);
  }

  Future<http.Response> get(String url, {Map<String,String>? headers, throwError: true, skipCheckingExpiration: false}) async {
    return await _callHttpAction(_HTTP_ACTION.get, url, null, headers: headers, throwError: throwError, skipCheckingExpiration: skipCheckingExpiration);
  }

  Future<http.Response> delete(String url, {Map<String,String>? headers, throwError: true, skipCheckingExpiration: false}) async {
    return await _callHttpAction(_HTTP_ACTION.delete, url, null, headers: headers, throwError: throwError, skipCheckingExpiration: skipCheckingExpiration);
  }

  void logout() => auth?.onExpire.call(true);

  JsonCache get cache => _cache;

  // private:
  Stream<String> _fetch(String url, {allowErrorWhenCacheExists = false, nocache = false}) {
    var controller = StreamController<String>();
    bool hasData = false;

    _cache.get(url, headers: auth?.headers(), nocache: nocache).listen(
        (String s) { controller.add(s); hasData = true; },
        onError: (e) {
          if(allowErrorWhenCacheExists || !hasData) controller.addError(e);
          _log.severe("Error while fetching $url", e);
        },
        onDone: () { controller.close(); }
    );

    return controller.stream;
  }

  Future<http.Response> _callHttpAction(
      _HTTP_ACTION actionType,
      String url, String? json,
      {Map<String,String>? headers, throwError: true, skipCheckingExpiration: false}
  ) async {
    late Future<http.Response> Function() action;

    Future<http.Response> makeRequest() {
      final Map<String, String> h = {"Content-Type": "application/json"};
      final authHeaders = auth!.headers();
      if(authHeaders!=null) h.addAll(authHeaders);
      if(headers!=null) h.addAll(headers);

      switch(actionType) {
        case _HTTP_ACTION.get: return _client.get(Uri.parse(url), headers: h);
        case _HTTP_ACTION.post: return _client.post(Uri.parse(url), body: json, headers: h);
        case _HTTP_ACTION.put: return _client.put(Uri.parse(url), body: json, headers: h);
        case _HTTP_ACTION.delete: return _client.delete(Uri.parse(url), body: json, headers: h);
      }
    }

    action = () async {
      var response = await makeRequest();
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
        }
        if(throwError) throw HttpClientException(response.reasonPhrase ?? "", response);
      }
      return response;
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

class HttpClientException implements HttpException {
  final http.Response response;
  final String message;

  HttpClientException(this.message, this.response);

  String toString() {
    return message + " (" + response.statusCode.toString() +")";
  }

  @override
  Uri? get uri => response.request?.url;
}

/// always download file (after returning it from memory or cache firstly)
/// very simple interface
abstract class JsonCache {
  /// get file.
  /// probably stream will be closed after receiving file from the network
  Stream<String> get(String url, {Map<String, String>? headers, nocache: false});
  /// force remove file from the cache
  Future<void> evict(key);
  /// empty the cache entirely
  Future<void> emptyCache();
}
