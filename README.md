![test on release](https://github.com/justprodev/json_fetcher/actions/workflows/release.yaml/badge.svg)
[![codecov](https://codecov.io/gh/justprodev/json_fetcher/graph/badge.svg?token=2EOK5RXNB4)](https://codecov.io/gh/justprodev/json_fetcher)

## Motivation

Imagine a user launching an app for the second time and seeing a skeletal loading screen or progress bar,
especially in parts of the UI where the data doesn't change often. This is not so good UX.

To fix this, we can load the data from the cache in the first step and then update the data in the second step.

We don't target to minimize query to the server, but to minimize the time to show the data to the user.

## How it works

If the data has changed (new data has arrived from the network), it will be updated in the second step.
That's why we use ```Stream<T>``` instead of ```Future<T>```. The stream's subscriber will get two snapshots.

If the data hasn't changed, the stream's subscriber will get one snapshot

If there is no cached copy, the stream's subscriber will get one snapshot.

## Cache

The cache data is managed by implementations of [HttpCache](https://github.com/justprodev/json_fetcher/tree/master/lib/src/http_cache.dart).

### dart:io (mobile/desktop)

[HttpFilesCache](https://github.com/justprodev/json_fetcher/tree/master/lib/src/cache/http_files_cache/http_files_cache.dart) stores data in files.
It uses long living `Isolate` to work synchronously with the file system. This increases the speed of the cache.

### Web

[HttpHiveCache](https://github.com/justprodev/json_fetcher/tree/master/lib/src/cache/http_hive_cache/http_hive_cache.dart) uses pure dart version of the [hive](https://github.com/isar/hive/tree/legacy),
which is not related to Isar. Not bad for working as Key-Value storage.

## Usage

### pubspec.yaml

```yaml
json_fetcher:
  git:
    url: https://github.com/justprodev/json_fetcher.git
    ref: 2.0.0-rc.12 # control the version, please
```

### Code

```dart
import 'dart:io';

import 'package:dart_json_fetcher_example/model/post.dart';
import 'package:http/http.dart';
import 'package:json_fetcher/json_fetcher.dart';
import 'package:json_fetcher/standard_fetchers.dart';

void main() async {
  final client = JsonHttpClient(Client(), createCache('temp'));
  final postsStream = JsonFetcher<List<Post>>(
    client,
    (json) => (json as List).map((e) => Post.fromJson(e as Map<String, dynamic>)).toList(),
  ).fetch('https://jsonplaceholder.typicode.com/posts');

  await for (final posts in postsStream) {
    for (final post in posts) {
      print(post);
    }
  }

  exit(0);
}
```

More examples can be found in the [examples](https://github.com/justprodev/json_fetcher/tree/master/examples) directory.
