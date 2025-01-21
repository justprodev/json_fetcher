// Created by alex@justprodev.com on 21.01.2025.

import 'package:dart_cache_benchmark/http_hive_cache.dart';
import 'package:json_fetcher/json_fetcher.dart';
// ignore_for_file: implementation_imports
import 'package:json_fetcher/src/cache/http_files_cache/http_files_cache.dart';
import 'package:path_provider/path_provider.dart';

Future<List<HttpCache>> getCaches() async {
  final path = await getApplicationCacheDirectory();

  return [
    HttpHiveCache(path.path),
    HttpFilesCache(path.path),
  ];
}