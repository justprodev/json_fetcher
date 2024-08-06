```
dart_cache_benchmark % dart bin/dart_cache_benchmark.dart
Key value size: 27.0 KB

HttpHiveCache:
Seq put 10000 keys: 1870 ms
Seq peek 10000 keys: 1220 ms
Random seq peek 1000 keys: 124 ms
Random seq put 1000 keys: 202 ms
Burst put 10000 keys: 2615 ms
Burst peek 10000 keys: 1278 ms
Random burst peek 1000 keys: 125 ms
Random burst put 1000 keys: 172 ms
Seq delete 10000 keys: 3732 ms
Burst delete 10000 keys: 169 ms
Empty cache: 4 ms
Crc32 valid: true
Main thread latency (94002 ops): 1.0 ms

HttpFilesCache:
Seq put 10000 keys: 1956 ms
Seq peek 10000 keys: 467 ms
Random seq peek 1000 keys: 43 ms
Random seq put 1000 keys: 275 ms
Burst put 10000 keys: 2617 ms
Burst peek 10000 keys: 484 ms
Random burst peek 1000 keys: 45 ms
Random burst put 1000 keys: 289 ms
Seq delete 10000 keys: 623 ms
Burst delete 10000 keys: 1786 ms
Empty cache: 0 ms
Crc32 valid: true
Main thread latency (94002 ops): 0.125 ms
```
