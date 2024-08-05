```
dart_cache_benchmark % dart compile exe bin/dart_cache_benchmark.dart

dart_cache_benchmark % bin/dart_cache_benchmark.exe

Key value size: 27.0 KB

HttpHiveCache:
Put 10000 keys: 1919 ms
Peek 10000 keys: 1418 ms
crc32: 28265458430000
Random peek 1000 keys: 158 ms
Random put 1000 keys: 191 ms
crc32: 28265458430000
Delete 10000 keys: 2510 ms
Empty cache: 3 ms
Main thread latency: 0.875 ms



HttpFilesCache:
Put 10000 keys: 1849 ms
Peek 10000 keys: 407 ms
crc32: 28265458430000
Random peek 1000 keys: 39 ms
Random put 1000 keys: 257 ms
crc32: 28265458430000
Delete 10000 keys: 533 ms
Empty cache: 2 ms
Main thread latency: 0.25 ms
```
