// Copyright (c) 2020, alex@justprodev.com.
// All rights reserved. Use of this source code is governed by a
// MIT License that can be found in the LICENSE file.

// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Created by alex@justprodev.com on 31.01.2024.

import 'dart:convert';

import 'package:http/http.dart';

extension BaseClientExt on Client {
  /// This is a copy of private method of [BaseClient._sendUnstreamed]
  /// Sends a non-streaming [Request] and returns a non-streaming [Response].
  Future<Response> sendUnstreamed(
      String method, Uri url, Map<String, String>? headers,
      [Object? body, Encoding? encoding]) async {
    var request = Request(method, url);

    if (headers != null) request.headers.addAll(headers);
    if (encoding != null) request.encoding = encoding;
    if (body != null) {
      if (body is String) {
        request.body = body;
      } else if (body is List) {
        request.bodyBytes = body.cast<int>();
      } else if (body is Map) {
        request.bodyFields = body.cast<String, String>();
      } else {
        throw ArgumentError('Invalid request body "$body".');
      }
    }

    return Response.fromStream(await send(request));
  }
}