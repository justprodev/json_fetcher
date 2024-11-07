// Copyright (c) 2020, alex@justprodev.com.
// All rights reserved. Use of this source code is governed by a
// MIT License that can be found in the LICENSE file.

// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Created by alex@justprodev.com on 31.01.2024.

import 'package:http/http.dart';

extension BaseClientExt on Client {
  /// Sends a non-streaming [Request] and returns a non-streaming [Response].
  /// This is a stripped down copy of the private method [BaseClient._sendUnstreamed]
  Future<Response> sendUnstreamed(
    String method,
    Uri url,
    Map<String, String>? headers, [
    String? body,
  ]) async {
    final request = Request(method, url);

    if (headers != null) request.headers.addAll(headers);
    if (body != null) request.body = body;

    return Response.fromStream(await send(request));
  }
}

abstract interface class HttpHeaders {
  static const contentTypeHeader = "content-type";
}