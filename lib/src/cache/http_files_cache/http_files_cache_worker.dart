// Created by alex@justprodev.com on 05.08.2024.

import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'dart:isolate';

import 'package:meta/meta.dart';

/// Isolate worker for cache operations
class HttpFilesCacheWorker {
  final SendPort _commands;

  final _input = HashMap<Job, Completer<String?>>();

  HttpFilesCacheWorker._(ReceivePort responses, this._commands) {
    responses.listen((message) {
      if (message is JobResult) {
        switch (message) {
          case JobValueResult():
            _input[message.job]?.complete(message.value);
          case JobErrorResult():
            _input[message.job]?.completeError(message.error, message.trace);
        }
      }
    });
  }

  /// Send job to worker and wait for response
  @pragma('vm:prefer-inline')
  Future<String?> run(Job job) async {
    final oldJob = _input[job];

    // wait old job and run new job
    if (oldJob != null) {
      await oldJob.future.catchError((_) => null);
      return await run(job);
    }

    final completer = Completer<String?>();
    _input[job] = completer;
    _commands.send(job);
    try {
      // we prefer await here by self, because caller of the run() may not await the result
      // we need to ensure that the job is completed to remove it from the input map
      // to avoid memory leaks, for simplicity, etc
      final result = await completer.future;
      return result;
    } finally {
      _input.remove(job);
    }
  }

  /// Spawn new isolate, setup communication and return worker
  static Future<HttpFilesCacheWorker> create([
    @visibleForTesting
    Future<Isolate> Function(void Function(SendPort), SendPort, {String? debugName}) spawn = Isolate.spawn,
  ]) async {
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
      await spawn(_startWorker, (initPort.sendPort), debugName: 'HttpFilesCacheWorker');
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
          final value = handleJob(message);
          sendPort.send(JobValueResult(message, value));
        } catch (e, trace) {
          sendPort.send(JobErrorResult(message, e, trace));
        }
      }
    });
  }

  /// Process job and return result
  ///
  /// Perform IO operations
  ///
  /// Returns non-null for [GetJob]
  @visibleForTesting
  @pragma('vm:prefer-inline')
  static String? handleJob(Job job) {
    switch (job) {
      case PutJob():
        final file = getFile(job.path, job.key);
        final dir = file.parent;
        if (!dir.existsSync()) dir.createSync();
        final tempFile = File('${dir.path}/.${job.key}');
        tempFile.writeAsStringSync(job.value);
        tempFile.renameSync(file.path);
      case DeleteJob():
        final file = getFile(job.path, job.key);
        if (file.existsSync()) file.deleteSync();
      case GetJob():
        final file = getFile(job.path, job.key);
        if (file.existsSync()) return file.readAsStringSync();
      case EmptyCacheJob():
        final dir = Directory(job.path);
        final tmp = dir.renameSync('${dir.path}.${DateTime.now().microsecondsSinceEpoch}');
        dir.createSync();
        // run removing old cache asynchronously
        tmp.delete(recursive: true);
    }

    return null;
  }
}

/// A job for worker
///
/// See [HttpFilesCacheWorker.handleJob]
sealed class Job {
  /// Path to the cache directory
  final String path;
  final String? key;

  const Job(this.path, [this.key]);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Job && runtimeType == other.runtimeType && path == other.path && key == other.key;

  @override
  int get hashCode => path.hashCode ^ key.hashCode;
}

class GetJob extends Job {
  @override
  String get key => super.key!;

  const GetJob(super.path, String super.key);
}

class PutJob extends GetJob {
  final String value;

  const PutJob(super.path, super.key, this.value);
}

class DeleteJob extends GetJob {
  const DeleteJob(super.path, super.key);
}

class EmptyCacheJob extends Job {
  const EmptyCacheJob(super.path);
}

sealed class JobResult {
  final Job job;

  const JobResult(this.job);
}

class JobValueResult extends JobResult {
  final String? value;

  const JobValueResult(super.job, this.value);
}

class JobErrorResult extends JobResult {
  final Object error;
  final StackTrace trace;

  const JobErrorResult(super.job, this.error, this.trace);
}

@pragma('vm:prefer-inline')
File getFile(String path, String key) {
  final integerKey = int.parse(key);
  final dirPath = '$path/d_${integerKey ~/ 100}';
  return File('$dirPath/$key');
}
