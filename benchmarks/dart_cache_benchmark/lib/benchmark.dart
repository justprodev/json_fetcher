import 'dart:async';
import 'dart:typed_data';

import 'package:json_fetcher/json_fetcher.dart';

import 'utils/crc32.dart';

Future<String> runBenchmark(List<BaseCache> caches) async {
  final value = List.generate(1024, (i) {
    return 'lorem ipsum dolor sit amet';
  }).join('\n');

  String results = '\nKey value size: ${(value.length / 1024).toStringAsFixed(1)} KB\n\n';

  final keys = List.generate(10000, (index) => index.toString());
  final values = Map.fromEntries(keys.map((key) => MapEntry(key, value)));

  for (final cache in caches) {
    final stopwatch = Stopwatch()..start();
    final timer = Timer.periodic(Duration(milliseconds: 8), (_) {});
    results += await _runBenchmark(cache, values);
    results += 'Main thread latency: ${stopwatch.elapsedMilliseconds / 8 - timer.tick} ms\n\n';
    results += '\n\n';
    stopwatch.stop();
    timer.cancel();
  }

  return results;
}

Future<String> _runBenchmark(BaseCache cache, Map<String, String> values) async {
  String result = '${cache.runtimeType}:\n';

  await cache.emptyCache();

  final stopwatch = Stopwatch()..start();

  for (final key in values.keys) {
    await cache.put(key, values[key]!);
  }

  result += 'Put ${values.keys.length} keys: ${stopwatch.elapsed.inMilliseconds} ms\n';

  stopwatch.reset();

  for (final key in values.keys) {
    await cache.peek(key);
  }

  result += 'Peek ${values.keys.length} keys: ${stopwatch.elapsed.inMilliseconds} ms\n';

  stopwatch
    ..stop()
    ..reset();

  int crc = 0;
  for (final key in values.keys) {
    final s = await cache.peek(key);
    crc += Crc32.compute(Uint8List.fromList(s!.codeUnits));
  }
  result += 'crc32: $crc\n';

  final shuffledKeys = (List<String>.from(values.keys)..shuffle()).take(1000).toList();

  stopwatch.start();

  for (final key in shuffledKeys) {
    await cache.peek(key);
  }

  result += 'Random peek ${shuffledKeys.length} keys: ${stopwatch.elapsed.inMilliseconds} ms\n';

  stopwatch.reset();

  for (final key in shuffledKeys) {
    await cache.put(key, values[key]!);
  }

  result += 'Random put ${shuffledKeys.length} keys: ${stopwatch.elapsed.inMilliseconds} ms\n';

  stopwatch
    ..stop()
    ..reset();

  crc = 0;
  for (final key in values.keys) {
    final s = await cache.peek(key);
    crc += Crc32.compute(Uint8List.fromList(s!.codeUnits));
  }
  result += 'crc32: $crc\n';

  stopwatch.start();

  for (final key in values.keys) {
    await cache.delete(key);
  }

  result += 'Delete ${values.keys.length} keys: ${stopwatch.elapsed.inMilliseconds} ms\n';

  stopwatch
    ..stop()
    ..reset();

  for (final key in values.keys) {
    await cache.put(key, values[key]!);
  }

  stopwatch.start();

  await cache.emptyCache();

  result += 'Empty cache: ${stopwatch.elapsed.inMilliseconds} ms\n';

  stopwatch
    ..stop()
    ..reset();

  return result;
}
