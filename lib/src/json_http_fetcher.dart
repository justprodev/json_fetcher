// Copyright (c) 2020, alex@justprodev.com.
// All rights reserved. Use of this source code is governed by a
// MIT License that can be found in the LICENSE file.

import 'dart:async';
import 'package:meta/meta.dart';
import 'json_cache.dart';
import 'json_fetcher_exception.dart';
import 'json_http_client.dart';

///
///
///
abstract class JsonHttpFetcher<T> {
  final JsonHttpClient _client;

  const JsonHttpFetcher(this._client);

  /// implement me: returns object parsed from json
  @protected
  FutureOr<T> parse(String source);

  /// by default, if cached version is available then errors will not be pushed to stream
  /// [nocache] skip cached version
  /// [allowErrorWhenCacheExists] throw errors even if cache is exists
  /// if [cacheUrl] is specified, then content will be cached under it
  Stream<T> fetch(
    String url, {
    nocache = false,
    allowErrorWhenCacheExists = false,
    Map<String, String>? headers,
    String? cacheUrl,
    String? body,
    bool usePost = false,
  }) async* {
    final String key;

    if (body != null) {
      assert(cacheUrl == null, 'cacheUrl could not be used with body');
      key = _client.cache.buildKey(url, body: body);
    } else {
      key = _client.cache.buildKey(cacheUrl ?? url);
    }

    JsonFetcherException? error;
    final cachedString = await _client.cache.peek(key);
    T? cachedDocument;

    if (cachedString != null && !nocache) {
      try {
        cachedDocument = await parse(cachedString);
        yield cachedDocument!;
      } catch (e, t) {
        error = JsonFetcherException(url, e.toString(), e, trace: t);
      }
    }

    try {
      final onlineString = await _sendRequest(url, headers: headers, body: body, usePost: usePost);
      await _client.cache.put(key, onlineString);

      if (cachedString != onlineString) {
        final document = await parse(onlineString);
        // drop error because we have valid document
        error = null;
        yield document;
        _client.onFetched?.call(url, document!);
      }
    } catch (e, t) {
      error = JsonFetcherException(url, e.toString(), e, trace: t);
    }

    if (error != null) {
      // throw errors only if we have no valid document from cache
      // or we have to throw errors even if cache is exists
      if (cachedDocument == null || allowErrorWhenCacheExists) {
        _client.onError?.call(error, error.trace);
        yield* Stream.error(error);
      }
    }
  }

  /// just get without caching
  Future<T> get(
    String url, {
    Map<String, String>? headers,
    String? body,
    bool usePost = false,
  }) async {
    final String jsonString = await _sendRequest(url, headers: headers, body: body, usePost: usePost);
    return await parse(jsonString);
  }

  /// returns body of the response
  Future<String> _sendRequest(
    String url, {
    Map<String, String>? headers,
    required String? body,
    required bool usePost,
  }) async {
    final r = usePost ? _client.post(url, body!, headers: headers) : _client.get(url, headers: headers, json: body);
    return (await r).body;
  }
}
