import 'dart:async';
import 'dart:typed_data';

import 'package:json_fetcher/json_fetcher.dart';

import 'utils/base_cache_count_wrapper.dart';
import 'utils/crc32.dart';

Stream<String> runBenchmark(List<BaseCache> caches) async* {
  final value = List.generate(1024, (i) {
    return 'lorem ipsum dolor sit amet';
  }).join('\n');

  yield 'Key value size: ${(value.length / 1024).toStringAsFixed(1)} KB\n\n';

  final keys = List.generate(10000, (index) => index.toString());
  final values = Map.fromEntries(keys.map((key) => MapEntry(key, value)));

  for (final originalCache in caches) {
    final cache = BaseCacheBenchmarkWrapper(originalCache);
    final stopwatch = Stopwatch()..start();
    final timer = Timer.periodic(Duration(milliseconds: 8), (_) {});
    await for (final s in _runBenchmark(cache, values)) {
      yield s;
    }
    yield 'Main thread latency (${cache.counter} ops): ${stopwatch.elapsedMilliseconds / 8 - timer.tick} ms\n\n';
    stopwatch.stop();
    timer.cancel();
  }
}

Stream<String> _runBenchmark(BaseCache cache, Map<String, String> values) async* {
  yield '$cache:\n';

  int crc1 = 0;
  for (final e in values.entries) {
    crc1 += Crc32.compute(Uint8List.fromList((e.key + e.value).codeUnits));
  }

  await cache.emptyCache();

  final stopwatch = Stopwatch()..start();

  // seq operations

  for (final e in values.entries) {
    await cache.put(e.key, e.value);
  }
  yield 'Seq put ${values.keys.length} keys: ${stopwatch.elapsed.inMilliseconds} ms\n';

  stopwatch.reset();

  for (final key in values.keys) {
    await cache.get(key);
  }
  yield 'Seq get ${values.keys.length} keys: ${stopwatch.elapsed.inMilliseconds} ms\n';

  final shuffledKeys = (List<String>.from(values.keys)..shuffle()).take(1000).toList();

  stopwatch.reset();

  for (final key in shuffledKeys) {
    await cache.get(key);
  }
  yield 'Random seq get ${shuffledKeys.length} keys: ${stopwatch.elapsed.inMilliseconds} ms\n';

  stopwatch.reset();

  for (final key in shuffledKeys) {
    await cache.put(key, values[key]!);
  }
  yield 'Random seq put ${shuffledKeys.length} keys: ${stopwatch.elapsed.inMilliseconds} ms\n';

  // burst operations

  await Future.wait(values.entries.map((e) => cache.put(e.key, e.value)));
  yield 'Burst put ${values.keys.length} keys: ${stopwatch.elapsed.inMilliseconds} ms\n';

  stopwatch.reset();

  await Future.wait(values.keys.map((key) => cache.get(key)));
  yield 'Burst get ${values.keys.length} keys: ${stopwatch.elapsed.inMilliseconds} ms\n';

  stopwatch.reset();

  await Future.wait(shuffledKeys.map((key) => cache.get(key)));
  yield 'Random burst get ${shuffledKeys.length} keys: ${stopwatch.elapsed.inMilliseconds} ms\n';

  stopwatch.reset();

  await Future.wait(shuffledKeys.map((key) => cache.put(key, values[key]!)));
  yield 'Random burst put ${shuffledKeys.length} keys: ${stopwatch.elapsed.inMilliseconds} ms\n';

  stopwatch
    ..stop()
    ..reset();

  int crc2 = 0;
  for (final key in values.keys) {
    final value = await cache.get(key);
    crc2 += Crc32.compute(Uint8List.fromList((key + value!).codeUnits));
  }

  stopwatch.start();

  for (final key in values.keys) {
    await cache.delete(key);
  }
  yield 'Seq delete ${values.keys.length} keys: ${stopwatch.elapsed.inMilliseconds} ms\n';

  stopwatch
    ..stop()
    ..reset();

  for (final key in values.keys) {
    await cache.put(key, values[key]!);
  }

  stopwatch.start();

  await Future.wait(values.keys.map((key) => cache.delete(key)));
  yield 'Burst delete ${values.keys.length} keys: ${stopwatch.elapsed.inMilliseconds} ms\n';

  stopwatch
    ..stop()
    ..reset();

  for (final key in values.keys) {
    await cache.put(key, values[key]!);
  }

  stopwatch.start();

  await cache.emptyCache();

  yield 'Empty cache: ${stopwatch.elapsed.inMilliseconds} ms\n';

  stopwatch
    ..stop()
    ..reset();

  yield 'Crc32 valid: ${crc1 == crc2}\n';
}
