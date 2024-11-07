// Created by alex@justprodev.com on 07.11.2024.

import 'package:http/http.dart' show ClientException;

bool isNotReachable(Object? error) => error is ClientException;