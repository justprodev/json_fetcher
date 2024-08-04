// Created by alex@justprodev.com on 05.08.2024.

import 'dart:async';
import 'dart:io';

import 'package:json_fetcher/src/http_cache.dart';
import 'package:json_fetcher/src/util/fnv1a_hash/fnv1a_hash.dart';

import 'http_files_cache_worker.dart';

const _subDirPath = '__http_files_cache';

/// An file-based cache
///
/// 1. Each value is stored in a separate file
/// 2. Using [HttpFilesCacheWorker] to perform IO operations
class HttpFilesCache extends HttpCache {
  static late final HttpFilesCacheWorker _worker;
  static Completer? _initializing;
  static bool _isInit = false;

  HttpFilesCache(String path) {
    path = '$path/$_subDirPath';
    Directory(path).createSync(recursive: true);

    Future<void> init() async {
      _initializing = Completer();
      try {
        _worker = await HttpFilesCacheWorker.create(path);
        _isInit = true;
        _initializing?.complete();
        _initializing = null;
      } catch (e) {
        _initializing?.completeError(e);
      }
    }

    if (!_isInit && _initializing == null) init();
  }

  @override
  Future<void> delete(String key) async {
    if (_initializing != null) await _initializing!.future;
    await _worker.run(Job(JobType.delete, key));
  }

  @override
  Future<String?> peek(String key) async {
    if (_initializing != null) await _initializing!.future;
    return (await _worker.run(Job(JobType.peek, key))).value;
  }

  @override
  Future<void> put(String key, String value) async {
    if (_initializing != null) await _initializing!.future;
    await _worker.run(Job(JobType.put, key, value));
  }

  @override
  Future<void> emptyCache() async {
    if (_initializing != null) await _initializing!.future;
    await _worker.run(Job(JobType.emptyCache, null));
  }

  /// Overriding just to prevent possibly using other method in base class
  @override
  String createKey(String url, {String? body}) => fastHash('$url${body ?? ''}');
}