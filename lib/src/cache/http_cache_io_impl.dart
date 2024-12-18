// Created by alex@justprodev.com on 05.08.2024.

import 'dart:async';

import '../http_cache.dart';
import 'http_files_cache/http_files_cache.dart';

HttpCache createCache([FutureOr<String>? path]) {
  assert(path != null, 'Path must be provided for IO cache');
  return HttpFilesCache(path!);
}
