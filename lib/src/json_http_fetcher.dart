// Copyright (c) 2020-2022, alex@justprodev.com.
// All rights reserved. Use of this source code is governed by a
// MIT License that can be found in the LICENSE file.

import 'dart:async';

import 'package:json_fetcher/json_fetcher.dart';
import 'package:meta/meta.dart';

///
///
///
abstract class JsonHttpFetcher<T> {
  final JsonHttpClient _client;

  JsonHttpFetcher(this._client);

  /// implement me: returns object parsed from json
  @protected
  Future<T> parse(String source);

  /// by default, if cached version is available then errors will not be pushed to stream
  /// [nocache] skip cached version
  Stream<T> fetch(String url, {nocache: false}) {
    StreamController<T> controller = StreamController();

    controller.onListen = () {
      StreamSubscription<String> subscription = _client.cache.get(url, nocache: nocache).listen(null,
          onError: controller.addError, // Avoid Zone error replacement.
          onDone: null);

      JsonFetcherException? error;
      T? document;
      int passes = 0;

      subscription.onData((String jsonString) async {
        subscription.pause();

        // drop error
        error = null;
        document = null;

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
        if(error != null) {
          controller.addError(error!, error!.trace);
        } else if(passes>1 && document != null) {
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
  Future<T> get(String url, {Map<String,String>? headers}) async {
    final String jsonString = (await _client.get(url, headers: headers)).body;
    return await parse(jsonString);
  }
}
