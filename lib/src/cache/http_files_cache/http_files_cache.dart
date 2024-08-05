// Created by alex@justprodev.com on 05.08.2024.

import 'dart:async';
import 'dart:io';

import 'package:json_fetcher/src/http_cache.dart';
import 'package:json_fetcher/src/util/fnv1a_hash/fnv1a_hash.dart';
import 'package:meta/meta.dart';

import 'http_files_cache_worker.dart';

@visibleForTesting
const subDirPath = '__http_files_cache';

/// An file-based cache
///
/// 1. Each value is stored in a separate file
/// 2. Using [HttpFilesCacheWorker] to perform IO operations
/// 3. Keys should be numbers, see [createKey]
class HttpFilesCache extends HttpCache {
  // use only one worker for all instances!
  static late final HttpFilesCacheWorker _worker;
  static Completer? _initializing;
  static bool _isInit = false;

  late final String _path;

  HttpFilesCache(String path) {
    /// Using subdirectory to avoid conflicts with other files
    _path = '$path/$subDirPath';

    Future<void> init() async {
      _initializing = Completer();
      try {
        await Directory(_path).create(recursive: true);
        _worker = await HttpFilesCacheWorker.create();
        _isInit = true;
        _initializing?.complete();
        _initializing = null;
      } catch (e) {
        _initializing?.completeError(e);
      }
    }

    // Creating first instance in the app: start initializing process
    if (!_isInit && _initializing == null) init();
  }

  @override
  Future<void> delete(String key) async {
    if (_initializing != null) await _initializing!.future;
    await _worker.run(Job(_path, JobType.delete, key));
  }

  @override
  Future<String?> peek(String key) async {
    if (_initializing != null) await _initializing!.future;
    return (await _worker.run(Job(_path, JobType.peek, key))).value;
  }

  @override
  Future<void> put(String key, String value) async {
    if (_initializing != null) await _initializing!.future;
    await _worker.run(Job(_path, JobType.put, key, value));
  }

  @override
  Future<void> emptyCache() async {
    if (_initializing != null) await _initializing!.future;
    await _worker.run(Job(_path, JobType.emptyCache, null));
  }

  /// This implementation uses FNV-1a hash function of the url + body
  @override
  String createKey(String url, {String? body}) => fastHash('$url${body ?? ''}');
}
