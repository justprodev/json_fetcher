// Created by alex@justprodev.com on 05.08.2024.

import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'dart:isolate';

import 'package:meta/meta.dart';

/// Isolate worker for cache operations
///
/// 1. Using sync file IO
/// 2. Only one job will be processed at a time, other jobs will wait
class HttpFilesCacheWorker {
  final SendPort _commands;

  final _input = HashMap<_JobKey, Completer<Job>>();

  HttpFilesCacheWorker._(ReceivePort responses, this._commands) {
    responses.listen((message) {
      if (message is _JobResult) {
        final key = _JobKey.fromJob(message.job);

        if (message.error == null) {
          _input[key]?.complete(message.job);
        } else {
          _input[key]?.completeError(message.error!, message.trace);
        }
      }
    });
  }

  /// Send job to worker and wait for response
  @pragma('vm:prefer-inline')
  Future<Job> run(Job job) async {
    final key = _JobKey.fromJob(job);
    final current = _input[key];

    // wait current job to complete, ignore the result and errors
    if (current != null) await current.future.whenComplete(Future.value);

    final completer = Completer<Job>();
    _input[key] = completer;
    _commands.send(job);
    try {
      // we prefer await here by self, because caller of the run() may not await the result
      // we need to ensure that the job is completed to remove it from the input map
      // to avoid memory leaks, for simplicity, etc
      final result = await completer.future;
      return result;
    } finally {
      _input.remove(key);
    }
  }

  /// Spawn new isolate, setup communication and return worker
  static Future<HttpFilesCacheWorker> create() async {
    // Create a receive port and add its initial message handler.
    final initPort = RawReceivePort();
    final connection = Completer<(ReceivePort, SendPort)>.sync();
    initPort.handler = (initialMessage) {
      final commandPort = initialMessage as SendPort;
      connection.complete((
        ReceivePort.fromRawReceivePort(initPort),
        commandPort,
      ));
    };
    // Spawn the isolate.
    try {
      await Isolate.spawn(_startWorker, (initPort.sendPort), debugName: 'HttpFilesCacheWorker');
    } on Object {
      initPort.close();
      rethrow;
    }

    final (ReceivePort receivePort, SendPort sendPort) = await connection.future;

    return HttpFilesCacheWorker._(receivePort, sendPort);
  }

  /// 1. Sends its own [SendPort] to the main isolate
  /// 2. Listens for jobs from the main isolate and sends responses
  static void _startWorker(SendPort sendPort) {
    final receivePort = ReceivePort();
    sendPort.send(receivePort.sendPort);
    receivePort.listen((message) {
      if (message is Job) {
        try {
          final result = handleJob(message);
          sendPort.send(_JobResult(result));
        } catch (e, trace) {
          sendPort.send(_JobResult(message, e, trace));
        }
      }
    });
  }

  /// Process job and return result
  ///
  /// Perform IO operations
  @visibleForTesting
  @pragma('vm:prefer-inline')
  static Job handleJob(Job job) {
    final path = job.path;

    switch (job.type) {
      case JobType.put:
        final key = job.key!;
        final Directory dir = getDirectory(path, key);

        if (!dir.existsSync()) dir.createSync();

        final tmp = File('${dir.path}/.$key');

        tmp.writeAsStringSync(job.value!);
        tmp.renameSync('${dir.path}/$key');

        return job.withValue(null);
      case JobType.peek:
        final key = job.key!;
        final Directory dir = getDirectory(path, key);

        final file = File('${dir.path}/$key');
        if (file.existsSync()) {
          return job.withValue(file.readAsStringSync());
        } else {
          return job.withValue(null);
        }
      case JobType.delete:
        final key = job.key!;
        final dir = getDirectory(path, key);
        final file = File('${dir.path}/$key');

        if (file.existsSync()) file.deleteSync();

        return job;
      case JobType.emptyCache:
        final dir = Directory(path);
        final tmp = dir.renameSync('$path.${DateTime.now().microsecondsSinceEpoch}');
        dir.createSync();
        // run removing old cache asynchronously
        tmp.delete(recursive: true);
        return job;
    }
  }
}

/// A job for worker
/// See [HttpFilesCacheWorker.handleJob]
class Job {
  /// Path to the cache directory
  final String path;

  /// Type of job
  final JobType type;

  /// Key for the cache entry
  final String? key;

  /// Value for the cache entry
  final String? value;

  const Job(this.path, this.type, this.key, [this.value]);

  Job withValue(String? value) => Job(path, type, key, value);

  @override
  toString() => 'Job(path: $path, type: $type, key: $key, value: $value)';
}

/// Type of job, corresponds to cache operations
enum JobType { put, peek, delete, emptyCache }

class _JobKey {
  final String path;
  final String? key;
  final JobType type;

  const _JobKey(this.path, this.key, this.type);

  factory _JobKey.fromJob(Job job) => _JobKey(job.path, job.key, job.type);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is _JobKey && other.path == path && other.key == key && other.type == type;
  }

  @override
  int get hashCode => path.hashCode ^ key.hashCode ^ type.hashCode;
}

class _JobResult {
  final Job job;
  final Object? error;
  final StackTrace? trace;

  const _JobResult(this.job, [this.error, this.trace]);
}

@visibleForTesting
@pragma('vm:prefer-inline')
Directory getDirectory(String path, String key) {
  final bKey = int.parse(key);
  return Directory('$path/d_${bKey ~/ 100}');
}
