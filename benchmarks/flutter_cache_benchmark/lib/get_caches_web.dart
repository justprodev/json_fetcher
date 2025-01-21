// Created by alex@justprodev.com on 21.01.2025.

import 'package:dart_cache_benchmark/http_hive_cache.dart';
import 'package:json_fetcher/json_fetcher.dart';
// ignore_for_file: implementation_imports
import 'package:json_fetcher/src/cache/http_web_cache/http_web_cache.dart';

Future<List<HttpCache>> getCaches() async {
  return [
    HttpHiveCache(null),
    HttpWebCache(),
  ];
}