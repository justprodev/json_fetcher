import 'package:flutter/material.dart';

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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Expanded(
              child: FutureBuilder(
                future: runBenchmark(),
                builder: (_, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    return Text(
                      snapshot.data?.toString() ?? snapshot.error.toString(),
                    );
                  }
                  return const Center(child: CircularProgressIndicator());
                },
              ),
            ),
            ElevatedButton(onPressed: ()=>setState((){}), child: Text('Restart')),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

