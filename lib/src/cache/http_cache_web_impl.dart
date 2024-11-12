// Created by alex@justprodev.com on 05.08.2024.

import 'dart:async';

import '../http_cache.dart';
import 'http_web_cache/http_web_cache.dart';

HttpCache createCache([FutureOr<String>? path]) => HttpWebCache();
