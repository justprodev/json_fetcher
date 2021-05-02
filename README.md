# json_fetcher

Tools to easily work with JSON services/data over HTTP + cache.
This method of caching JSON data results in a smoother UI.

## Cache

At low level a cached data are managed by [flutter_cache_manager](https://github.com/Baseflow/flutter_cache_manager).
But, a data will be always updated at second step. Thats why the ```Stream<T>``` is used instead of ```Future<T>```.

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

## TODO

Refactor from "one instance using" (i.e. static accessing, etc) 
to many instances with injecting parts in the constructors. 
To possibly testing without MockWebServer and for using with DI.