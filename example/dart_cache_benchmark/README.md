dart_cache_benchmark % dart bin/dart_cache_benchmark.dart

Key value size: 27.0 KB

HttpHiveCache:
Put 10000 keys: 1975 ms
Peek 10000 keys: 1253 ms
crc32: 28265458430000
Random peek 1000 keys: 119 ms
Random put 1000 keys: 192 ms
crc32: 28265458430000
Delete 10000 keys: 2806 ms
Empty cache: 4 ms


HttpFilesCache:
Put 10000 keys: 2016 ms
Peek 10000 keys: 433 ms
crc32: 28265458430000
Random peek 1000 keys: 43 ms
Random put 1000 keys: 290 ms
crc32: 28265458430000
Delete 10000 keys: 556 ms
Empty cache: 0 ms