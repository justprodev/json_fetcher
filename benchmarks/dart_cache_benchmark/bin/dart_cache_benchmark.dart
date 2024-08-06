import 'dart:io';

import 'package:dart_cache_benchmark/benchmark.dart';

// ignore_for_file: implementation_imports
import 'package:json_fetcher/src/cache/http_files_cache/http_files_cache.dart';
import 'package:json_fetcher/src/cache/http_hive_cache/http_hive_cache.dart';

void main() async {
  final temp = 'temp';
  await for (final s in runBenchmark([HttpHiveCache(temp), HttpFilesCache(temp)])) {
    stdout.write(s);
  }

  // just wait for some last operations
  await Future.delayed(Duration(seconds: 1));

  // we should exit manually, because the worker lives forever
  exit(0);
}
