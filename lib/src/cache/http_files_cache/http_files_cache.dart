// Created by alex@justprodev.com on 05.08.2024.

import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:json_fetcher/src/http_cache.dart';
import 'package:json_fetcher/src/util/fnv1a_hash/fnv1a_hash.dart';
import 'package:meta/meta.dart';

@visibleForTesting
const subDirPath = '__http_files_cache';

const maxConcurrentJobs = 100;

/// File-based cache
///
/// 1. Keys should be numbers, see [createKey]
/// 2. Each value is stored in a separate file
/// 3. Running IO operations concurrently, but not more than [maxConcurrentJobs].
///    Locking by key: Wait for jobs with same key.
class HttpFilesCache extends HttpCache {
  Completer? _initializing = Completer();

  late final String _path;

  /// **[path] must be writeable**
  HttpFilesCache(FutureOr<String> path) {
    Future<void> init() async {
      try {
        /// Using subdirectory to avoid conflicts with other files
        _path = '${await path}/$subDirPath';
        if (!await Directory(_path).exists()) await Directory(_path).create(recursive: true);

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

    return _runJob(key, () async {
      try {
        await _getFile(key).delete();
      } on PathNotFoundException {
        // ignore
      }
    });
  }

  @override
  Future<String?> get(String key) async {
    if (_initializing != null) await _initializing!.future;

    return _runJob(key, () async {
      try {
        return await _getFile(key).readAsString();
      } on PathNotFoundException {
        return null;
      }
    });
  }

  @override
  Future<void> put(String key, String value) async {
    if (_initializing != null) await _initializing!.future;

    return _runJob(key, () async {
      final file = _getFile(key);
      try {
        await file.writeAsString(value, flush: true);
      } on PathNotFoundException {
        await file.parent.create(recursive: true).then((_) => file.writeAsString(value, flush: true));
      }
    });
  }

  @override
  Future<void> emptyCache() async {
    if (_initializing != null) await _initializing!.future;

    final dir = Directory(_path);
    final tmp = await dir.rename('${dir.path}.${DateTime.now().microsecondsSinceEpoch}');
    await dir.create();
    // don't wait for the old cache to be deleted
    tmp.delete(recursive: true);
  }

  /// This implementation uses FNV-1a hash function of the url + body
  @override
  String createKey(String url, {String? body}) => fastHash('$url${body ?? ''}');

  @pragma('vm:prefer-inline')
  File _getFile(String key) {
    final integerKey = int.parse(key);
    final dirPath = '$_path/d_${integerKey ~/ 100}';
    return File('$dirPath/$key');
  }

  final _jobs = HashMap<String, Future>();

  Future<T> _runJob<T>(String key, Future<T> Function() job) async {
    final Future? jobToWait = _jobs.length >= maxConcurrentJobs ? _jobs.values.first : _jobs[key];

    if (jobToWait != null) {
      await jobToWait;
      return await _runJob(key, job);
    }

    final newJob = job();

    try {
      _jobs[key] = newJob;
      return await newJob;
    } finally {
      _jobs.remove(key);
    }
  }
}
