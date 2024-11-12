// Created by alex@justprodev.com on 12.11.2024.

import 'dart:async';
import 'dart:isolate';

FutureOr<R> run<R>(FutureOr<R> Function() computation, {String? debugName}) {
  return Isolate.run(computation);
}