import 'dart:async';

import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import 'benchmark.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cache benchmark',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Cache benchmark'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late ValueNotifier<bool> started;
  final stopwatch = Stopwatch();
  late Timer timer;
  late ValueNotifier<int> minutes;
  late ValueNotifier<int> seconds;
  Stream<String>? benchmark;
  String? lastBenchmark;

  @override
  void initState() {
    started = ValueNotifier(false);
    seconds = ValueNotifier(0);
    minutes = ValueNotifier(0);
    super.initState();
    start();
  }

  @override
  void dispose() {
    started.dispose();
    minutes.dispose();
    seconds.dispose();
    timer.cancel();
    super.dispose();
  }

  void start() {
    if (started.value) return;

    started.value = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        stopwatch
          ..start()
          ..reset();
        minutes.value = 0;
        seconds.value = 0;
        timer = Timer.periodic(const Duration(seconds: 1), (_) {
          final duration = stopwatch.elapsed;
          minutes.value = duration.inMinutes;
          seconds.value = duration.inSeconds.remainder(60);
        });
        benchmark = runBenchmark();
        setState(() {});
      } catch (_) {
        stop();
      }
    });
  }

  void stop() {
    benchmark = null;
    started.value = false;
    stopwatch.stop();
    timer.cancel();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Text(widget.title),
            ),
            ValueListenableBuilder(
              valueListenable: minutes,
              builder: (_, int value, __) {
                return AnimatedFlipCounter(
                  textStyle: const TextStyle(color: Colors.white),
                  duration: const Duration(milliseconds: 100),
                  value: value,
                );
              },
            ),
            const Text(':', style: TextStyle(color: Colors.white)),
            ValueListenableBuilder(
              valueListenable: seconds,
              builder: (_, int value, __) {
                return AnimatedFlipCounter(
                  textStyle: const TextStyle(color: Colors.white),
                  wholeDigits: 2,
                  duration: const Duration(milliseconds: 100),
                  value: value,
                );
              },
            ),
          ],
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.max,
        children: <Widget>[
          Expanded(
            child: Scrollbar(
              thumbVisibility: true,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                primary: true,
                child: Center(
                  child: StreamBuilder(
                    stream: benchmark,
                    builder: (_, snapshot) {
                      if (snapshot.connectionState == ConnectionState.done) {
                        WidgetsBinding.instance.addPostFrameCallback((_) => stop());
                      }

                      final result = snapshot.data?.toString() ?? snapshot.error?.toString();
                      if (result != null) {
                        lastBenchmark = result;
                        return SelectableText(result);
                      }
                      return const CircularProgressIndicator();
                    },
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: ValueListenableBuilder(
                valueListenable: started,
                builder: (_, bool startedValue, __) {
                  return Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: !startedValue ? start : null,
                          child: const Text('Restart'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: !startedValue && lastBenchmark != null ? share : null,
                        child: const Icon(Icons.ios_share),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  void share() {
    String text = '''
### ${defaultTargetPlatform.name}:

```
${lastBenchmark!.trim()}
```
    
    ''';
    Share.share(text);
  }
}
