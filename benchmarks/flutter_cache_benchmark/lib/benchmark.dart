import 'dart:async';

import 'package:dart_cache_benchmark/http_hive_cache.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dart_cache_benchmark/benchmark.dart' as dart_cache_benchmark;

// ignore_for_file: implementation_imports
import 'package:json_fetcher/src/cache/http_files_cache/http_files_cache.dart';
import 'package:json_fetcher/src/cache/http_web_cache/http_web_cache.dart';

Stream<String> runBenchmark() async* {
  String result = '';
  final Stream<String> stream;

  if (kIsWeb) {
    stream = dart_cache_benchmark.runBenchmark([
      HttpHiveCache(null),
      HttpWebCache(),
    ]);
  } else {
    final path = await getApplicationCacheDirectory();

    stream = dart_cache_benchmark.runBenchmark([
      HttpHiveCache(path.path),
      HttpFilesCache(path.path),
    ]);
  }

  await for (final s in stream) {
    result += s;
    yield result;
  }
}
