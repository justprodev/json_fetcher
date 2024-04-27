// Copyright (c) 2020, alex@justprodev.com.
// All rights reserved. Use of this source code is governed by a
// MIT License that can be found in the LICENSE file.

import 'dart:async';
import 'package:meta/meta.dart';
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
  }) {
    StreamController<T> controller = StreamController();

    controller.onListen = () {
      JsonFetcherException? error;
      T? document;
      int passes = 0;

      final subscription = _client.cache.get(url, nocache: nocache, headers: headers, cacheUrl: cacheUrl).listen(null,
          // Avoid Zone error replacement.
          onError: (e, t) => {if (document == null || allowErrorWhenCacheExists) controller.addError(e, t)},
          onDone: null);

      subscription.onData((String jsonString) async {
        subscription.pause();

        // drop error
        error = null;

        try {
          passes++;
          document = await parse(jsonString);
          controller.add(document!);
        } catch (e, t) {
          // to skip the immediately adding an errors to the controller
          error = JsonFetcherException(url, e.toString(), e, trace: t);
        } finally {
          subscription.resume();
        }
      });

      subscription.onDone(() {
        // Add errors only when data came from Internet (latest 'parse')
        // Is important, because cache can be corrupted and we will be break here
        // because of that We adding error to controller only when all data processed
        if (error != null) {
          // throw errors only if we have no any valid document
          if (document == null || allowErrorWhenCacheExists) {
            controller.addError(error!, error!.trace);
            _client.onError?.call(error!, error!.trace!);
          }
        } else if (passes > 1 && document != null) {
          // We have document from network
          _client.onFetched?.call(url, document!);
        }
        controller.close();
      });

      controller
        ..onCancel = subscription.cancel
        ..onPause = subscription.pause
        ..onResume = subscription.resume;
    };
    return controller.stream;
  }

  /// just get without caching
  Future<T> get(String url, {Map<String, String>? headers}) async {
    final String jsonString = (await _client.get(url, headers: headers)).body;
    return await parse(jsonString);
  }
}
