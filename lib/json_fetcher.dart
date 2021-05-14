// Copyright (c) 2020, alex@justprodev.com.
// All rights reserved. Use of this source code is governed by a
// MIT License that can be found in the LICENSE file.

import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
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

/// Client especially for fetching json from host(s)
/// It controls authentication via [setAuth] and used by [HttpJsonFetcher] to parse/cache json's
/// [cache] can be used to directly control the cache (i.e. [JsonCacheManager.emptyCache]/[JsonCacheManager.removeFile])
class JsonHttpClient {
  final http.Client _client;
  /// cache manager used by [HttpJsonFetcher]
  late JsonCacheManager _cache = JsonCacheManager(_client);

  static final _log = Logger((JsonHttpClient).toString());
  /// permanent headers across client
  Map<String,String> _headers = Map();
  Future<void> Function(bool isRepeat)? _onExpire;
  Function(String url, dynamic document)? _fetchHandler;

  JsonHttpClient(this._client);

  /// Sets the auth headers like "Authorization: Bearer $token" or anythings else
  /// These headers will be include in every call
  ///
  /// [onExpire] will be called for 401 error ([authHeaders] will be removed from the header immediately),
  /// `isRepeat`==true means that handler was called  at second, because a new auth data is wrong (refreshToken can't succeeded or etc),
  ///  and We probably should redirect to login page
  ///
  void setAuth(Map<String, String> authHeaders, Future<void> Function(bool isRepeat) onExpire) {
    _headers.addAll(authHeaders);
    _onExpire = (bool _isRepeat) async {
      authHeaders.keys.forEach((header)=>_headers.remove(header));
      try {
        await onExpire(_isRepeat);
      } catch(e) {
        _log.severe("Error while do onExpire($_isRepeat)", e);
      }
    };
  }

  /// [handler] will be called when [HttpJsonFetcher] completes parsing an document
  /// which was fetched from [url] from network (not from cache!)
  /// Please be sure, that handler works fast as possible (do heavy operations async)
  void setFetchHandler(Function(String url, dynamic document) handler) {
    _fetchHandler = handler;
  }

  /// [throwError] if true then http error will be thrown as [HttpClientException]
  Future<http.Response> post(String url, String json, {Map<String,String>? headers, throwError: false}) async {
    return await _callHttpAction(_HTTP_ACTION.post, url, json, headers: headers, throwError: throwError);
  }

  Future<http.Response> put(String url, String json, {Map<String,String>? headers, throwError: false}) async {
    return await _callHttpAction(_HTTP_ACTION.put, url, json, headers: headers, throwError: throwError);
  }

  Future<http.Response> get(String url, {Map<String,String>? headers, throwError: false}) async {
    return await _callHttpAction(_HTTP_ACTION.get, url, null, headers: headers, throwError: throwError);
  }

  Future<http.Response> delete(String url, {Map<String,String>? headers, throwError: false}) async {
    return await _callHttpAction(_HTTP_ACTION.delete, url, null, headers: headers, throwError: throwError);
  }

  void logout() => _onExpire?.call(true);

  JsonCacheManager get cache => _cache;

  // private:
  Stream<String> _fetch(String url, {allowErrorWhenCacheExists = false, nocache = false}) {
    var controller = StreamController<String>();
    bool hasData = false;
    late Function(bool allowCloseStream) action;
    bool isOnExpireCalled = false;

    action = (allowCloseStream) => _cache.readAsString(url, headers: _headers, nocache: nocache).listen((String s) { controller.add(s); hasData = true; },
        onError: (e) {
          /// for 401 error we invoke onExpire handler
          if (e is HttpException && e.message.contains('401') && _onExpire != null) {
            if(!isOnExpireCalled) {
              allowCloseStream = false;   // block closing stream

              _onExpire?.call(false).then((_) {
                action(true);
              }); // refresh auth data and resubmit latest call

              isOnExpireCalled = true;
            } else {
              _onExpire?.call(true);                 // just inform because is second attempt
              allowCloseStream = true;               // allow closing anyway
            }
          }
          if(allowErrorWhenCacheExists || !hasData) controller.addError(e);
          _log.severe("Error while fetching $url", e);
        }, onDone: () { if(allowCloseStream) controller.close(); });

    action(true);

    return controller.stream;
  }

  Future<http.Response> _callHttpAction(_HTTP_ACTION actionType, String url, String? json, {Map<String,String>? headers, throwError: false}) async {
    late Future<http.Response> Function(bool isOnExpireCalled) action;

    Future<http.Response> makeRequest() {
      final Map<String, String> h = {"Content-Type": "application/json"};
      h.addAll(_headers);
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
        if (response.statusCode==401 && _onExpire != null) {
          await _onExpire?.call(isOnExpireCalled);         // refresh auth data
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

/// [BaseCacheManager] variant that always download file (after returning it from memory or cache firstly)
class JsonCacheManager {
  static late String _key = (JsonCacheManager).toString();
  static late Logger _log = Logger(_key);

  final Map<String, StreamController<String>> _downloads = HashMap();
  final CacheManager _cache;

  factory JsonCacheManager(http.Client client) {
    final cache = CacheManager(
      Config(
        _key,
        stalePeriod: const Duration(days: 30),
        maxNrOfCacheObjects: 100,
        fileService: HttpFileService(httpClient: client),
      ),
    );
    return JsonCacheManager._internal(cache);;
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
        if (!controller.isClosed) {
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