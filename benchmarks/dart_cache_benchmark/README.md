Mac:
```
dart_cache_benchmark % dart bin/dart_cache_benchmark.dart
Key value size: 27.0 KB

HttpHiveCache:
Seq put 10000 keys: 1870 ms
Seq get 10000 keys: 1220 ms
Random seq get 1000 keys: 124 ms
Random seq put 1000 keys: 202 ms
Burst put 10000 keys: 2615 ms
Burst get 10000 keys: 1278 ms
Random burst get 1000 keys: 125 ms
Random burst put 1000 keys: 172 ms
Seq delete 10000 keys: 3732 ms
Burst delete 10000 keys: 169 ms
Empty cache: 4 ms
Crc32 valid: true
Main thread latency (94002 ops): 1.0 ms

HttpFilesCache:
Seq put 10000 keys: 1956 ms
Seq get 10000 keys: 467 ms
Random seq get 1000 keys: 43 ms
Random seq put 1000 keys: 275 ms
Burst put 10000 keys: 2617 ms
Burst get 10000 keys: 484 ms
Random burst get 1000 keys: 45 ms
Random burst put 1000 keys: 289 ms
Seq delete 10000 keys: 623 ms
Burst delete 10000 keys: 1786 ms
Empty cache: 0 ms
Crc32 valid: true
Main thread latency (94002 ops): 0.125 ms
```

Linux:
```
/dart_cache_benchmark$ dart bin/dart_cache_benchmark.dart
Key value size: 27.0 KB

HttpHiveCache:
Seq put 10000 keys: 3658 ms
Seq get 10000 keys: 1831 ms
Random seq get 1000 keys: 158 ms
Random seq put 1000 keys: 239 ms
Burst put 10000 keys: 4554 ms
Burst get 10000 keys: 1915 ms
Random burst get 1000 keys: 186 ms
Random burst put 1000 keys: 244 ms
Seq delete 10000 keys: 11081 ms
Burst delete 10000 keys: 430 ms
Empty cache: 41 ms
Crc32 valid: true
Main thread latency (94002 ops): 1.5 ms

HttpFilesCache:
Seq put 10000 keys: 1788 ms
Seq get 10000 keys: 526 ms
Random seq get 1000 keys: 46 ms
Random seq put 1000 keys: 215 ms
Burst put 10000 keys: 2205 ms
Burst get 10000 keys: 590 ms
Random burst get 1000 keys: 52 ms
Random burst put 1000 keys: 207 ms
Seq delete 10000 keys: 382 ms
Burst delete 10000 keys: 244 ms
Empty cache: 5 ms
Crc32 valid: true
Main thread latency (94002 ops): 0.875 ms
```

Windows:
```
\dart_cache_benchmark> dart .\bin\dart_cache_benchmark.dart
Key value size: 27.0 KB

HttpHiveCache:
Seq put 10000 keys: 984 ms
Seq get 10000 keys: 881 ms
Random seq get 1000 keys: 92 ms
Random seq put 1000 keys: 96 ms
Burst put 10000 keys: 1588 ms
Burst get 10000 keys: 924 ms
Random burst get 1000 keys: 96 ms
Random burst put 1000 keys: 101 ms
Seq delete 10000 keys: 3288 ms
Burst delete 10000 keys: 225 ms
Empty cache: 21 ms
Crc32 valid: true
Main thread latency (94002 ops): 1.375 ms

HttpFilesCache:
Seq put 10000 keys: 11595 ms
Seq get 10000 keys: 928 ms
Random seq get 1000 keys: 90 ms
Random seq put 1000 keys: 1103 ms
Burst put 10000 keys: 5394 ms
Burst get 10000 keys: 1436 ms
Random burst get 1000 keys: 32 ms
Random burst put 1000 keys: 183 ms
Seq delete 10000 keys: 1560 ms
Burst delete 10000 keys: 1073 ms
Empty cache: 10 ms
Crc32 valid: true
Main thread latency (94002 ops): 2.125 ms
```