import 'dart:io';

import 'package:dart_json_fetcher_example/model/photo.dart';
import 'package:http/http.dart';
import 'package:json_fetcher/json_fetcher.dart';
import 'package:json_fetcher/standard_fetchers.dart';

void main() async {
  final client = JsonHttpClient(Client(), createCache('temp'));
  final photosStream = IsolatedJsonFetcher<List<Photo>>(
    client,
    (json) => (json as List).map((e) => Photo.fromJson(e as Map<String, dynamic>)).toList(),
  ).fetch('https://jsonplaceholder.typicode.com/photos');

  await for (final photos in photosStream) {
    for(final photo in photos) {
      print(photo);
    }
  }

  exit(0);
}
