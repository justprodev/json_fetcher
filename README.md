# json_fetcher

Tools to easily work with JSON services/data over HTTP.

Caching is included out of the box (files are managed by [flutter_cache_manager](https://github.com/Baseflow/flutter_cache_manager)).

## Getting Started

```dart
class Typical {
  String data;

  static Typical fromMap(Map<String, dynamic> map) {
    if (map == null) return null;

    Typical typical = Typical();
    typical.data = map['data'];
    return typical;
  }
}

class _TypicalFetcher extends HttpJsonFetcher<List<Typical>> {
  /// compute json parsing in separated thread
  @override
  Future<List<Typical>> parse(String source) => compute(_parseTypicals, source);

  static List<Typical> _parseTypicals(String source) {
    final parsed = json.decode(source);
    return parsed.map<Typical>((json) => Typical.fromMap(json)).toList();
  }
}

// This is where you always get the online data, but you get the cached data first, if any
Stream<List<Typical>> fetchTypicals() => _TypicalFetcher().fetch("https://host/api/typicals");
```

Also, see [test/json_fetcher_test.dart](test/json_fetcher_test.dart)
