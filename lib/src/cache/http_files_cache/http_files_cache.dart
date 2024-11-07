// Created by alex@justprodev.com on 05.08.2024.

import 'dart:async';
import 'dart:io';

import 'package:json_fetcher/src/http_cache.dart';
import 'package:json_fetcher/src/util/fnv1a_hash/fnv1a_hash.dart';
import 'package:meta/meta.dart';

import 'http_files_cache_worker.dart';

@visibleForTesting
const subDirPath = '__http_files_cache';

// one worker for all instances!
late final HttpFilesCacheWorker _worker;
bool _workerCreated = false;

/// An file-based cache
///
/// 1. Each value is stored in a separate file
/// 2. Using [HttpFilesCacheWorker] to perform IO operations
/// 3. Keys should be numbers, see [createKey]
class HttpFilesCache extends HttpCache {
  Completer? _initializing = Completer();

  late final String _path;

  /// **[path] must be writeable**
  HttpFilesCache(FutureOr<String> path) {
    Future<void> init() async {
      try {
        /// Using subdirectory to avoid conflicts with other files
        _path = '${await path}/$subDirPath';
        if (!Directory(_path).existsSync()) await Directory(_path).create(recursive: true);

        if (!_workerCreated) {
          _worker = await HttpFilesCacheWorker.create();
          _workerCreated = true;
        }

        _initializing?.complete();
        _initializing = null;
      } catch (e) {
        _initializing?.completeError(e);
      }
    }

    init();
  }

  @override
  Future<void> delete(String key) async {
    if (_initializing != null) await _initializing!.future;
    await _worker.run(DeleteJob(_path, key));
  }

  @override
  Future<String?> get(String key) async {
    if (_initializing != null) await _initializing!.future;
    return await _worker.run(GetJob(_path, key));
  }

  @override
  Future<void> put(String key, String value) async {
    if (_initializing != null) await _initializing!.future;
    await _worker.run(PutJob(_path, key, value));
  }

  @override
  Future<void> emptyCache() async {
    if (_initializing != null) await _initializing!.future;
    await _worker.run(EmptyCacheJob(_path));
  }

  /// This implementation uses FNV-1a hash function of the url + body
  @override
  String createKey(String url, {String? body}) => fastHash('$url${body ?? ''}');
}
