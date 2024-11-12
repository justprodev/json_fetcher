[![pub package](https://img.shields.io/pub/v/json_fetcher.svg)](https://pub.dev/packages/json_fetcher)
[![codecov](https://codecov.io/gh/justprodev/json_fetcher/graph/badge.svg?token=2EOK5RXNB4)](https://codecov.io/gh/justprodev/json_fetcher)

## Motivation

Imagine a user launching the app for the second time and seeing a skeletal loading screen or progress bar,
especially in parts of the UI where the data doesn't change often. This is not a good UX.

To fix this, we can load the data from the cache in the first step, and then update the data in the second step.

*We don't aim to minimize requests to the server, but to minimize the time it takes to display the data to the user.*

## Using

```dart
import 'package:http/http.dart' as http;
import 'package:json_fetcher/json_fetcher.dart';
import 'package:path_provider/path_provider.dart';

Future<String> get cachePath => getApplicationCacheDirectory().then((dir) => dir.path);
final client = JsonHttpClient(http.Client(), createCache(cachePath));
final postsStream = JsonFetcher<Model>>(
  client,
  (json) => Model.fromJson(json),
).fetch('https://example.com/get-json');
```

> [!TIP]
> Examples can be found in the [example](https://github.com/justprodev/json_fetcher/tree/master/example) directory:
> - [Flutter example](https://github.com/justprodev/json_fetcher/tree/master/example/flutter_json_fetcher_example)
> - [Pure Dart example](https://github.com/justprodev/json_fetcher/tree/master/example/flutter_json_fetcher_example)
> - [Flutter example deployed to the web](https://justprodev.com/demo/json_fetcher_flutter/)


## Configuration

At the first step you should create [JsonHttpClient](https://github.com/justprodev/json_fetcher/blob/master/lib/src/json_http_client.dart):

```dart
final jsonClient = JsonHttpClient(httpClient, cache);
```

### HttpClient

This package uses standard Dart [http](https://pub.dev/packages/http) package.

Basicaly, is enough to use [Client()](https://pub.dev/documentation/http/latest/http/Client-class.html) for creating raw client:

```dart
final jsonClient = JsonHttpClient(Client(), cache);
```

So, you can [configure client](https://pub.dev/packages/http#2-configure-the-http-client) more precisely before creating [JsonHttpClient](https://github.com/justprodev/json_fetcher/blob/master/lib/src/json_http_client.dart) itself.

```dart
Client httpClient() {
  if (Platform.isAndroid) {
    final engine = CronetEngine.build(
        cacheMode: CacheMode.memory,
        cacheMaxSize: 1000000);
    return CronetClient.fromCronetEngine(engine);
  }
  if (Platform.isIOS || Platform.isMacOS) {
    final config = URLSessionConfiguration.ephemeralSessionConfiguration()
      ..cache = URLCache.withCapacity(memoryCapacity: 1000000);
    return CupertinoClient.fromSessionConfiguration(config);
  }
  return IOClient();
}

final jsonClient = JsonHttpClient(httpClient(), cache);
```

> [!TIP]
> The package contains convenitent client-wrapper with logging capabitility [LoggableHttpClient](https://github.com/justprodev/json_fetcher/blob/master/lib/loggable_http_client.dart),
> see [Flutter example](https://github.com/justprodev/json_fetcher/tree/master/example/flutter_json_fetcher_example) as use case.


### Cache

For creating `cache` just use convenient function `createCache(path)`.

> [!NOTE]
> `path` can be `String` of `Future<String>`
>
> `Future<String>` variant is very useful for creating a client somewhere in `DI` at app startup, to prevent unneded waiting.

In Flutter Android/iOS app you can create client that caches data in standard cache directory with following snippet:

```dart
import 'package:path_provider/path_provider.dart';

Future<String> get path => getApplicationCacheDirectory().then((value) => value.path);

final jsonClient = JsonHttpClient(httpClient(), createCache(path));
```

> [!TIP]
> Package exposes interface [HttpCache](https://github.com/justprodev/json_fetcher/blob/master/lib/src/http_cache.dart), that can be implemented to use your own cache.

## How it works

If the data has changed (new data has arrived from the network), it will be updated in the second step.
That's why we use ```Stream<T>``` instead of ```Future<T>```. The stream's subscriber will get two snapshots.

If the data hasn't changed, the stream's subscriber will get one snapshot

If there is no cached copy, the stream's subscriber will get one snapshot.

### Cache

The cache data is managed by implementations of [HttpCache](https://github.com/justprodev/json_fetcher/tree/master/lib/src/http_cache.dart).

#### dart:io (mobile/desktop)

[HttpFilesCache](https://github.com/justprodev/json_fetcher/tree/master/lib/src/cache/http_files_cache/http_files_cache.dart) stores data in files.
Performance improved by using concurrent IO with synchronization by keys.

#### Web

[HttpWebCache](https://github.com/justprodev/json_fetcher/tree/master/lib/src/cache/http_web_cache/http_web_cache.dart) stores data in [IndexedDB](https://developer.mozilla.org/en-US/docs/Web/API/IndexedDB_API).
It uses [package:web](https://pub.dev/packages/web) from Dart team.

