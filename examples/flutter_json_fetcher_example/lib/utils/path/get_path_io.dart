// Created by alex@justprodev.com on 27.08.2024.

import 'package:path_provider/path_provider.dart';

Future<String> getPath() => getApplicationCacheDirectory().then((value) => value.path);
