// Created by alex@justprodev.com on 05.08.2024.

import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:meta/meta.dart';

/// Isolate worker for cache operations
///
/// 1. Using sync file IO
/// 2. Only one job will be processed at a time, other jobs will wait
class HttpFilesCacheWorker {
  final SendPort _commands;
  Completer<Job>? _response;

  HttpFilesCacheWorker._(ReceivePort responses, this._commands) {
    responses.listen((message) {
      if (message is Job) {
        _response?.complete(message);
      } else if (message is RemoteError) {
        _response?.completeError(message);
      }
    });
  }

  /// Send job to worker and wait for response
  @pragma('vm:prefer-inline')
  Future<Job> run(Job job) async {
    // wait previous job to complete
    await _response?.future;

    // prepare new response
    _response = Completer();
    _commands.send(job);
    return _response!.future;
  }

  /// Spawn new isolate, setup communication and return worker
  static Future<HttpFilesCacheWorker> create(String path) async {
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
      await Isolate.spawn(_startWorker, (initPort.sendPort, path), debugName: 'HttpFilesCacheWorker');
    } on Object {
      initPort.close();
      rethrow;
    }

    final (ReceivePort receivePort, SendPort sendPort) = await connection.future;

    return HttpFilesCacheWorker._(receivePort, sendPort);
  }

  static void _startWorker((SendPort sendPort, String path) message) {
    final (sendPort, path) = message;
    final receivePort = ReceivePort();
    sendPort.send(receivePort.sendPort);
    receivePort.listen((message) {
      try {
        final job = message as Job;
        sendPort.send(handleJob(path, job));
      } catch (e, trace) {
        sendPort.send(RemoteError(e.toString(), trace.toString()));
      }
    });
  }

  /// IO operations
  @visibleForTesting
  @pragma('vm:prefer-inline')
  static Job handleJob(String path, Job job) {
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
        final Directory dir = getDirectory(path, key);

        File('${dir.path}/$key').deleteSync();

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

class Job {
  final JobType type;
  final String? key;
  final String? value;

  const Job(this.type, this.key, [this.value]);

  Job withValue(String? value) => Job(type, key, value);
}

enum JobType { put, peek, delete, emptyCache }

@visibleForTesting
@pragma('vm:prefer-inline')
Directory getDirectory(String path, String key) {
  final bKey = int.parse(key);
  return Directory('$path/d_${bKey ~/ 100}');
}
