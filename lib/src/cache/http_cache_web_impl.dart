// Created by alex@justprodev.com on 05.08.2024.

import 'package:json_fetcher/src/cache/http_hive_cache/http_hive_cache.dart';

import '../http_cache.dart';

HttpCache createCache([String? path]) => HttpHiveCache(null);
