// Copyright (c) 2020, alex@justprodev.com.
// All rights reserved. Use of this source code is governed by a
// MIT License that can be found in the LICENSE file.

/// Tools to easily work with JSON services / data over HTTP.
/// 1. http client wrapper [HttpClient]
/// 2. json fetcher [HttpJsonFetcher]
/// 3. cache [JsonCacheManager]

import 'package:meta/meta.dart';
import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';

///
/// Universal fetcher for JSON by HTTP
///
abstract class HttpJsonFetcher<T> {
  int _step = 0;
  /// implement me: returns object parsed from json
  Future<T> parse(String source);

  /// set [allowErrorWhenCacheExists] to true if you want to see network errors always
  /// by default, if cached version is available then errors will not be pushed to stream
  Stream<T> fetch(String url, {allowErrorWhenCacheExists: false, nocache: false}) {
    StreamController<T> controller = StreamController();

    controller.onListen = () {
      StreamSubscription<String> subscription = HttpClient._fetch(url, allowErrorWhenCacheExists: allowErrorWhenCacheExists, nocache: nocache).listen(null,
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

  Future<T> _parse(String url, String source) async {
    final o = await parse(source);
    if(_step>0) HttpClient._fetchHandler?.call(url, o);
    _step++;
    return o;
  }
}

///
/// Universal fetcher for JSON by HTTP (no cache)
///
abstract class HttpJsonGetter<T> {
  /// implement me: returns object parsed from json
  Future<T> parse(String source);

  Future<T> get(String url) => HttpClient.get(url).then((s)=>parse(s.body));
}

class HttpClient {
  static http.Client _client = http.Client();
  static final _log = Logger((HttpClient).toString());
  /// permanent headers across client
  static Map<String,String> _headers = Map();
  static Function()? _onBearerExpire;
  static Function(String url, dynamic document)? _fetchHandler;

  /// Let's set the [bearer] that was obtained anywhere
  /// "Authorization: Bearer [bearer]" will be added permanently to headers
  /// [onBearerExpire] will be called for 401 error (bearer will be removed from the header immediately)
  static void setAuth(String bearer, Function onBearerExpire) {
    _headers["Authorization"] = "Bearer " + bearer;
    _onBearerExpire = () {
      _headers.remove("Authorization");
      onBearerExpire();
    };
  }

  /// [handler] will be called when [HttpJsonFetcher] completes parsing an document
  /// which was fetched from [url] from network (not from cache!)
  /// Please be sure, that handler works fast as possible (do heavy operations async)
  static void setFetchHandler(Function(String url, dynamic document) handler) {
    _fetchHandler = handler;
  }

  static Stream<String> _fetch(String url, {allowErrorWhenCacheExists = false, nocache = false}) {
    var controller = StreamController<String>();
    bool hasData = false;
    JsonCacheManager().readAsString(url, headers: _headers, nocache: nocache).listen((String s) { controller.add(s); hasData = true; },
        onError: (e) {
          /// for 401 error we silently invoke onExpire handler
          if (e is HttpException && e.message.contains('401') &&
              _onBearerExpire != null) _onBearerExpire?.call();
          if(allowErrorWhenCacheExists || !hasData) controller.addError(e);
          _log.severe("Error while fetching $url", e);
        }, onDone: () => controller.close());

    return controller.stream;
  }

  /// [throwError] if true then http error will be thrown as [HttpClientException]
  static Future<http.Response> post(String url, String json, {Map<String,String>? headers, throwError: false}) async {
    Map<String, String> h = {"Content-Type": "application/json"};
    h.addAll(_headers);
    if(headers!=null) h.addAll(headers);
    var response = await _client.post(Uri.parse(url), body: json, headers: h);
    final String contentType = response.headers[HttpHeaders.contentTypeHeader] ?? "application/json";
    if(!contentType.contains("charset")) response.headers[HttpHeaders.contentTypeHeader] = contentType + ";charset=utf-8";
    if (response.statusCode < 200 || response.statusCode >= 400) {
      if(response.statusCode == 401) { if(_onBearerExpire!=null) _onBearerExpire?.call(); throw "$url: Пользователь не авторизован"; }
      if(throwError) throw HttpClientException("", response);
    }
    return response;
  }

  static Future<http.Response> put(String url, String json, {Map<String,String>? headers}) async {
    Map<String, String> h = {"Content-Type": "application/json"};
    h.addAll(_headers);
    if(headers!=null) h.addAll(headers);
    var response = await _client.put(Uri.parse(url), body: json, headers: h);
    final String contentType = response.headers[HttpHeaders.contentTypeHeader] ?? "application/json";
    if(!contentType.contains("charset")) response.headers[HttpHeaders.contentTypeHeader] = contentType + ";charset=utf-8";
    if(response.statusCode == 401) { if(_onBearerExpire!=null) _onBearerExpire?.call(); throw "$url: Пользователь не авторизован"; }
    return response;
  }

  /// get request without caching (unlike [_fetch])
  static Future<http.Response> get(String url) async {
    Map<String, String> h = {"Content-Type": "application/json"};
    h.addAll(_headers);
    var response = await _client.get(Uri.parse(url), headers: h);
    final String contentType = response.headers[HttpHeaders.contentTypeHeader] ?? "application/json";
    if(!contentType.contains("charset")) response.headers[HttpHeaders.contentTypeHeader] = contentType + ";charset=utf-8";
    if (response.statusCode < 200 || response.statusCode >= 400) {
      if(response.statusCode == 401) { if(_onBearerExpire!=null) _onBearerExpire?.call(); throw "$url: Пользователь не авторизован"; }
      throw HttpClientException("", response);
    }
    return response;
  }

  static Future<http.Response> delete(String url) async {
    var response = await _client.delete(Uri.parse(url), headers: _headers);
    if (response.statusCode < 200 || response.statusCode >= 400) {
      if(response.statusCode == 401) { if(_onBearerExpire!=null) _onBearerExpire?.call(); throw "$url: Пользователь не авторизован"; }
      throw HttpClientException("", response);
    }
    return response;
  }

  static void logout() => _onBearerExpire?.call();

  @visibleForTesting
  static void setClient(http.Client client) { _client = client; }
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

/// [BaseCacheManager] variant that always download file (after returning it from memory or cache firstly)
class JsonCacheManager {
  static final String _key = (JsonCacheManager).toString();
  static JsonCacheManager? _instance;

  Map<String, StreamController<String>> _downloads = HashMap();
  final _log = Logger(_key);
  CacheManager _cache;

  factory JsonCacheManager() {
    if (_instance == null) {
      final cache = CacheManager(
        Config(
          _key,
          stalePeriod: const Duration(days: 30),
          maxNrOfCacheObjects: 100,
          fileService: HttpFileService(httpClient: HttpClient._client),
        ),
      );
      _instance = JsonCacheManager._internal(cache);
    }
    return _instance!;
  }

  JsonCacheManager._internal(this._cache);

  /// [nocache] skips cache before getting the file - i.e.get from Internet then cache it
  Stream<String> readAsString(String url, {Map<String, String>? headers, nocache: false}) {
    StreamController<String>? oldController = _downloads[url];

    if(oldController!=null && !oldController.isClosed) oldController.close(); // prev download started, drop it

    StreamController<String> controller = StreamController();
    _downloads[url] = controller;

    void _getFile() async {
      try {
        FileInfo? f;
        String? cachedString;

        if(!nocache) {
          f = await _cache.getFileFromCache(url);
          if (f != null) if (!controller.isClosed) controller.add(
              cachedString = await f.file.readAsString()); // cache
        }

        //print("download $url start");
        var webFile = await _cache.downloadFile(url, authHeaders: headers, force: true);
        //print("download $url stop");
        if (webFile != null && !controller.isClosed) {
          final String onlineString = await webFile.file.readAsString();
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

    _getFile();

    return controller.stream;
  }

  Future<void> removeFile(key) => _cache.removeFile(key);
  Future<void> emptyCache() => _cache.emptyCache();
}