// Created by alex@justprodev.com on 05.08.2024.

import 'dart:async';

import 'package:json_fetcher/src/cache/http_hive_cache/http_hive_cache.dart';

import '../http_cache.dart';

HttpCache createCache([FutureOr<String>? path]) => HttpHiveCache(path);
