// Created by alex@justprodev.com on 06.08.2024.

import 'package:json_fetcher/src/util/future.dart';
import 'package:test/test.dart';

void main() {
  test('future catchErrors', () async {
    final future = Future.value(42);
    expect(await future.catchErrors(null), 42);
    expect(await future.catchErrors((e) => 0), 42);
    expect(await future.catchErrors((e) => throw 'error'), 42);
    expect(await future.catchErrors((e) => throw 42), 42);

    final future2 = Future.error('error');
    try {
      await future2.catchErrors(null);
      fail('should throw');
    } catch (e) {
      expect(e, 'error');
    }

    Object? err;
    StackTrace? trace;
    await future2.catchErrors((e, t) {
      err = e;
      trace = t;
    });
    expect(err, 'error');
    expect(trace, isA<StackTrace>());
  });
}
