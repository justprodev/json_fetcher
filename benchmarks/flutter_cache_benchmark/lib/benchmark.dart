import 'dart:async';

import 'package:dart_cache_benchmark/benchmark.dart' as dart_cache_benchmark;
import 'package:flutter_cache_benchmark/get_caches_web.dart'
    if (dart.library.io) 'get_caches_io.dart';

Stream<String> runBenchmark() async* {
  final caches = await getCaches();
  final Stream<String> stream = dart_cache_benchmark.runBenchmark(caches);

  String result = '';

  await for (final s in stream) {
    result += s;
    yield result;
  }
}
