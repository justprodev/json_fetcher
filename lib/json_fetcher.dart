// Copyright (c) 2020, alex@justprodev.com.
// All rights reserved. Use of this source code is governed by a
// MIT License that can be found in the LICENSE file.

import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';

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
  final Future<void> Function(bool isRepeat) onExpire;

  AuthInfo(this.headers, this.onExpire);
}

/// Client especially for fetching json from host(s)
/// [cache] can be used to directly control the cache (i.e. [JsonCache.emptyCache]/[JsonCache.evict])
class JsonHttpClient {
  final http.Client _client;
  final AuthInfo? auth;
  /// cache manager used by [HttpJsonFetcher]
  late JsonCache _cache = _JsonHiveCache(this);

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
  Future<http.Response> post(String url, String json, {Map<String,String>? headers, throwError: true}) async {
    return await _callHttpAction(_HTTP_ACTION.post, url, json, headers: headers, throwError: throwError);
  }

  Future<http.Response> put(String url, String json, {Map<String,String>? headers, throwError: true}) async {
    return await _callHttpAction(_HTTP_ACTION.put, url, json, headers: headers, throwError: throwError);
  }

  Future<http.Response> get(String url, {Map<String,String>? headers, throwError: true}) async {
    return await _callHttpAction(_HTTP_ACTION.get, url, null, headers: headers, throwError: throwError);
  }

  Future<http.Response> delete(String url, {Map<String,String>? headers, throwError: true}) async {
    return await _callHttpAction(_HTTP_ACTION.delete, url, null, headers: headers, throwError: throwError);
  }

  void logout() => auth?.onExpire.call(true);

  JsonCache get cache => _cache;

  // private:
  Stream<String> _fetch(String url, {allowErrorWhenCacheExists = false, nocache = false}) {
    var controller = StreamController<String>();
    bool hasData = false;
    late Function(bool allowCloseStream) action;
    bool isOnExpireCalled = false;

    action = (allowCloseStream) => _cache.get(url, headers: auth?.headers(), nocache: nocache).listen((String s) { controller.add(s); hasData = true; },
        onError: (e) {
          /// for 401 error we invoke onExpire handler
          if (e is HttpException && e.message.contains('401') && auth != null) {
            if(!isOnExpireCalled) {
              allowCloseStream = false;   // block closing stream

              auth?.onExpire.call(false).then((_) {
                action(true);
              }); // refresh auth data and resubmit latest call

              isOnExpireCalled = true;
            } else {
              auth?.onExpire.call(true);                 // just inform because is second attempt
              allowCloseStream = true;               // allow closing anyway
            }
          }
          if(allowErrorWhenCacheExists || !hasData) controller.addError(e);
          _log.severe("Error while fetching $url", e);
        }, onDone: () { if(allowCloseStream) controller.close(); });

    action(true);

    return controller.stream;
  }

  Future<http.Response> _callHttpAction(_HTTP_ACTION actionType, String url, String? json, {Map<String,String>? headers, throwError: true}) async {
    late Future<http.Response> Function(bool isOnExpireCalled) action;

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

    action = (isOnExpireCalled) async {
      var response = await makeRequest();
      final String contentType = response.headers[HttpHeaders.contentTypeHeader] ?? "application/json";
      if(!contentType.contains("charset")) response.headers[HttpHeaders.contentTypeHeader] = contentType + ";charset=utf-8";
      if (response.statusCode < 200 || response.statusCode >= 400) {
        /// for 401 error we silently invoke onExpire handler
        if (response.statusCode==401 && auth != null) {
          await auth!.onExpire.call(isOnExpireCalled);         // refresh auth data
          if(!isOnExpireCalled) {
            return await action(true);                     // resubmit latest call & return here because error handled inside action (thrown, etc)
          }
        }
        if(throwError) throw HttpClientException(response.reasonPhrase ?? "", response);
      }
      return response;
    };

    return await action(false);
  }
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
abstract class JsonCache {
  Stream<String> get(String url, {Map<String, String>? headers, nocache: false});
  Future<void> evict(key);
  Future<void> emptyCache();
}

class _JsonHiveCache implements JsonCache {
  final JsonHttpClient client;

  static late Logger _log = Logger((_JsonHiveCache).toString());

  late final Map<String, StreamController<String>> _downloads = HashMap();
  late final LazyBox _cache;

  bool _isInit = false;

  _JsonHiveCache(this.client);

  Future<void> _init() async {
    await Hive.initFlutter();
    _cache = await Hive.openLazyBox('__hive_json_hive_cache');
    _isInit = true;
  }

  /// [nocache] skips cache before getting the file - i.e.get from Internet then cache it
  Stream<String> get(String url, {Map<String, String>? headers, nocache: false}) {
    StreamController<String>? oldController = _downloads[url];

    if(oldController!=null && !oldController.isClosed) oldController.close(); // prev download started, drop it

    StreamController<String> controller = StreamController();
    _downloads[url] = controller;

    void _getValue() async {
      try {
        if(!_isInit) await _init();

        String? cachedString;

        if(!nocache) {
          cachedString = await _cache.get(url);
          if(cachedString!=null && !controller.isClosed) {
            controller.add(cachedString);
          }
        }

        //print("download $url start");
        final onlineString = await _download(url, authHeaders: headers);
        //print("download $url stop");
        if (!controller.isClosed) {
          if(onlineString != cachedString) // skip if a data the same
            controller.add(onlineString);
        } // online
      } catch (e, trace) {
        _log.severe("Failed to download file from $url", e, trace);
        if(!controller.isClosed) controller.addError(e);
      } finally {
        if(!controller.isClosed) await controller.close();
        _downloads.remove(url);
      }
    }

    _getValue();

    return controller.stream;
  }

  Future<String> _download(String url, {Map<String, String>? authHeaders}) async {
    final String value = (await client.get(url)).body;
    await _cache.put(url, value);
    return value;
  }

  Future<void> evict(key) => _cache.delete(key);
  Future<void> emptyCache() => _cache.clear();
}