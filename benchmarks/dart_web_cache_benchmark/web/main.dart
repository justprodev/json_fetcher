// Created by alex@justprodev.com on 09.11.2024.

import 'dart:async';
import 'dart:js_interop';

import 'package:dart_cache_benchmark/benchmark.dart';
import 'package:dart_cache_benchmark/http_hive_cache.dart';

// ignore: depend_on_referenced_packages
import 'package:json_fetcher/src/cache/http_web_cache/http_web_cache.dart';
import 'package:web/web.dart';

void main() async {
  final caches = [
    HttpHiveCache(null),
    HttpWebCache(),
  ];

  document.querySelector('div')!.innerHTML = '''
  <h1 id="elapsed"></h1>
  <pre></pre>
'''.toJS;

  final elapsed = document.querySelector('#elapsed') as HTMLHeadingElement;
  final output = document.querySelector('pre') as HTMLDivElement;

  final stopwatch = Stopwatch()..start();
  final timer = Timer.periodic(Duration(milliseconds: 8), (_) {
    elapsed.text = 'Elapsed: ${stopwatch.elapsed.inMinutes}:${(stopwatch.elapsed.inSeconds % 60).toString().padLeft(2, '0')}';
  });

  String result = '';
  await for (final s in runBenchmark(caches)) {
    result += s;
    output.text = result;
  }

  stopwatch.stop();
  timer.cancel();
}
