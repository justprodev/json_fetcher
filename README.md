![test on release](https://github.com/justprodev/json_fetcher/actions/workflows/release.yaml/badge.svg)
[![codecov](https://codecov.io/gh/justprodev/json_fetcher/graph/badge.svg?token=2EOK5RXNB4)](https://codecov.io/gh/justprodev/json_fetcher)

## Motivation

Imagine a user launching an app for the second time and seeing a skeletal loading screen or progress bar, especially in parts of the UI where the data doesn't change often. This is bad UX.

To fix this, we can load the data from the cache in the first step and then update the data in the second step. This library provides a convenient method for doing this.

## Cache

Currently, at low level a cached data are managed by [hive](https://github.com/isar/hive/tree/legacy) - old version not related to Isar.
Just because `hive` works well with `key-value data` on mobile/desktop/web (despite many criticism on it).

If the data has changed (new data has arrived from the network), it will be updated in the second step.
That's why we use ```Stream<T>``` instead of ```Future<T>```. The stream's subscriber will get two snapshots.

If the data hasn't changed, the stream's subscriber will get one snapshot

If there is no cached copy, the stream's subscriber will get one snapshot.

## Example

```dart
/// you can use freezed in real scenario
class Typical {
  String? data;

  static Typical fromJson(Map<String, dynamic> map) {
    Typical typical = Typical();
    typical.data = map['data'];
    return typical;
  }
}

class _TypicalFetcher extends JsonHttpFetcher<List<Typical>> {
  _TypicalFetcher(JsonHttpClient client) : super(client);

  List<Typical> parse(String source) => _parseTypicals(source)

  /// to parse big and complex json data in isolate
  //@override
  //Future<List<Typical>> parse(String source) => compute(_parseTypicals, source);

  static List<Typical> _parseTypicals(String source) {
    final parsed = json.decode(source);
    return parsed.map<Typical>((json) => Typical.fromMap(json)).toList();
  }
}

Stream<List<Typical>> fetchTypicals(JsonHttpClient client, String url) => _TypicalFetcher(client).fetch(url);
```

More examples coming soon
