*HttpHiveCache here just for comparing. It is not used in the package from version 2.0.3.*


### iOS:
```
Key value size: 27.0 KB

HttpHiveCache:
Seq put 10000 keys: 2214 ms
Seq get 10000 keys: 1642 ms
Random seq get 1000 keys: 163 ms
Random seq put 1000 keys: 208 ms
Burst put 10000 keys: 2705 ms
Burst get 10000 keys: 1704 ms
Random burst get 1000 keys: 169 ms
Random burst put 1000 keys: 196 ms
Seq delete 10000 keys: 3183 ms
Burst delete 10000 keys: 298 ms
Empty cache: 2 ms
Crc32 valid: true
Main thread latency (94002 ops): 0.25 ms

HttpFilesCache:
Seq put 10000 keys: 4840 ms
Seq get 10000 keys: 3197 ms
Random seq get 1000 keys: 284 ms
Random seq put 1000 keys: 334 ms
Burst put 10000 keys: 2989 ms
Burst get 10000 keys: 2236 ms
Random burst get 1000 keys: 89 ms
Random burst put 1000 keys: 154 ms
Seq delete 10000 keys: 1106 ms
Burst delete 10000 keys: 1245 ms
Empty cache: 0 ms
Crc32 valid: true
Main thread latency (94002 ops): 0.5 ms
```

### android:
```
Key value size: 27.0 KB

HttpHiveCache:
Seq put 10000 keys: 9047 ms
Seq get 10000 keys: 7655 ms
Random seq get 1000 keys: 731 ms
Random seq put 1000 keys: 859 ms
Burst put 10000 keys: 11550 ms
Burst get 10000 keys: 7054 ms
Random burst get 1000 keys: 712 ms
Random burst put 1000 keys: 945 ms
Seq delete 10000 keys: 13453 ms
Burst delete 10000 keys: 838 ms
Empty cache: 37 ms
Crc32 valid: true
Main thread latency (94002 ops): 0.75 ms

HttpFilesCache:
Seq put 10000 keys: 9092 ms
Seq get 10000 keys: 3518 ms
Random seq get 1000 keys: 289 ms
Random seq put 1000 keys: 871 ms
Burst put 10000 keys: 11156 ms
Burst get 10000 keys: 10516 ms
Random burst get 1000 keys: 297 ms
Random burst put 1000 keys: 475 ms
Seq delete 10000 keys: 1306 ms
Burst delete 10000 keys: 3275 ms
Empty cache: 0 ms
Crc32 valid: true
Main thread latency (94002 ops): 0.25 ms
```

### Macos
```
Key value size: 27.0 KB

HttpHiveCache:
Seq put 10000 keys: 1848 ms
Seq get 10000 keys: 1221 ms
Random seq get 1000 keys: 122 ms
Random seq put 1000 keys: 181 ms
Burst put 10000 keys: 2520 ms
Burst get 10000 keys: 1271 ms
Random burst get 1000 keys: 127 ms
Random burst put 1000 keys: 178 ms
Seq delete 10000 keys: 2979 ms
Burst delete 10000 keys: 168 ms
Empty cache: 29 ms
Crc32 valid: true
Main thread latency (94002 ops): 0.75 ms

HttpFilesCache:
Seq put 10000 keys: 1999 ms
Seq get 10000 keys: 754 ms
Random seq get 1000 keys: 74 ms
Random seq put 1000 keys: 194 ms
Burst put 10000 keys: 2468 ms
Burst get 10000 keys: 1639 ms
Random burst get 1000 keys: 83 ms
Random burst put 1000 keys: 143 ms
Seq delete 10000 keys: 753 ms
Burst delete 10000 keys: 1189 ms
Empty cache: 0 ms
Crc32 valid: true
Main thread latency (94002 ops): 0.375 ms
```

### Linux
```
Key value size: 27.0 KB

HttpHiveCache:
Seq put 10000 keys: 2897 ms
Seq get 10000 keys: 1812 ms
Random seq get 1000 keys: 164 ms
Random seq put 1000 keys: 229 ms
Burst put 10000 keys: 4608 ms
Burst get 10000 keys: 1907 ms
Random burst get 1000 keys: 171 ms
Random burst put 1000 keys: 243 ms
Seq delete 10000 keys: 10590 ms
Burst delete 10000 keys: 446 ms
Empty cache: 38 ms
Crc32 valid: true
Main thread latency (94002 ops): 1.5 ms

HttpFilesCache:
Seq put 10000 keys: 12733 ms
Seq get 10000 keys: 1439 ms
Random seq get 1000 keys: 148 ms
Random seq put 1000 keys: 1181 ms
Burst put 10000 keys: 5577 ms
Burst get 10000 keys: 3338 ms
Random burst get 1000 keys: 131 ms
Random burst put 1000 keys: 249 ms
Seq delete 10000 keys: 522 ms
Burst delete 10000 keys: 2043 ms
Empty cache: 0 ms
Crc32 valid: true
Main thread latency (94002 ops): 0.875 ms
```

### Windows:
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

### Dart web:
```
Key value size: 27.0 KB

HttpHiveCache:
Seq put 10000 keys: 7879 ms
Seq get 10000 keys: 1747 ms
Random seq get 1000 keys: 186 ms
Random seq put 1000 keys: 813 ms
Burst put 10000 keys: 21344 ms
Burst get 10000 keys: 3120 ms
Random burst get 1000 keys: 144 ms
Random burst put 1000 keys: 861 ms
Seq delete 10000 keys: 2481 ms
Burst delete 10000 keys: 14554 ms
Empty cache: 2459 ms
Crc32 valid: true
Main thread latency (94002 ops): 1.625 ms

HttpWebCache:
Seq put 10000 keys: 6121 ms
Seq get 10000 keys: 1784 ms
Random seq get 1000 keys: 180 ms
Random seq put 1000 keys: 784 ms
Burst put 10000 keys: 20963 ms
Burst get 10000 keys: 2987 ms
Random burst get 1000 keys: 111 ms
Random burst put 1000 keys: 955 ms
Seq delete 10000 keys: 2078 ms
Burst delete 10000 keys: 14561 ms
Empty cache: 2458 ms
Crc32 valid: true
Main thread latency (94002 ops): 0.5 ms
```

### Flutter web:
```
Key value size: 27.0 KB

minified:Fl:
Seq put 10000 keys: 5110 ms
Seq get 10000 keys: 1433 ms
Random seq get 1000 keys: 155 ms
Random seq put 1000 keys: 809 ms
Burst put 10000 keys: 18992 ms
Burst get 10000 keys: 2982 ms
Random burst get 1000 keys: 132 ms
Random burst put 1000 keys: 753 ms
Seq delete 10000 keys: 1433 ms
Burst delete 10000 keys: 11530 ms
Empty cache: 2414 ms
Crc32 valid: true
Main thread latency (94002 ops): 1.375 ms

minified:Fm:
Seq put 10000 keys: 5670 ms
Seq get 10000 keys: 1309 ms
Random seq get 1000 keys: 130 ms
Random seq put 1000 keys: 751 ms
Burst put 10000 keys: 19158 ms
Burst get 10000 keys: 2980 ms
Random burst get 1000 keys: 113 ms
Random burst put 1000 keys: 775 ms
Seq delete 10000 keys: 1268 ms
Burst delete 10000 keys: 12120 ms
Empty cache: 2359 ms
Crc32 valid: true
Main thread latency (94002 ops): 0.5 ms
```
