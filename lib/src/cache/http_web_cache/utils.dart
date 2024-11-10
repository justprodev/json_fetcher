//

import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart';

extension IDBRequestExtension on IDBRequest {
  /// converts IDBRequest result to Future
  Future<T> asFuture<T extends JSAny?>() {
    final completer = Completer<T>();
    onsuccess = (Event e) {
      print(e);
      completer.complete(result as T);
    }.toJS;
    onerror = (Event e) {
      print(error!);
      completer.completeError(error!);
    }.toJS;
    return completer.future;
  }
}

