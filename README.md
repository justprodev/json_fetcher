# json_fetcher

Tools to easily work with JSON services/data over HTTP + cache.
This method of caching JSON data results in a smoother UI.

## Cache

At low level a cached data are managed by [hive](https://github.com/hivedb/hive).
But, a data will be always updated at the second step. Thats why we use ```Stream<T>``` instead of ```Future<T>```.

## Getting Started

```dart
class Typical {
  String? data;

  static Typical fromMap(Map<String, dynamic> map) {
    Typical typical = Typical();
    typical.data = map['data'];
    return typical;
  }
}

class _TypicalFetcher extends HttpJsonFetcher<List<Typical>> {
  _TypicalFetcher(JsonHttpClient client) : super(client);

  /// compute json parsing in separated thread
  @override
  Future<List<Typical>> parse(String source) => compute(_parseTypicals, source);

  static List<Typical> _parseTypicals(String source) {
    final parsed = json.decode(source);
    return parsed.map<Typical>((json) => Typical.fromMap(json)).toList();
  }
}

Stream<List<Typical>> fetchTypicals(JsonHttpClient client, String prefix) => _TypicalFetcher(client).fetch(prefix+GET_TYPICALS_METHOD);



```

Also, see [test/json_fetcher_test.dart](test/json_fetcher_test.dart)
