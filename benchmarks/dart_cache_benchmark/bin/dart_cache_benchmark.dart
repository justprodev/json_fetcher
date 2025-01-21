import 'dart:io';

import 'package:dart_cache_benchmark/benchmark.dart';
import 'package:dart_cache_benchmark/http_hive_cache.dart';
// ignore_for_file: implementation_imports
import 'package:json_fetcher/src/cache/http_files_cache/http_files_cache.dart';

void main() async {
  await for (final s in runBenchmark([HttpHiveCache('temp'), HttpFilesCache('temp')])) {
    stdout.write(s);
  }
}
