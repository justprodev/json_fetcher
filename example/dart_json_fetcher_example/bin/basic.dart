import 'dart:io';

import 'package:dart_json_fetcher_example/model/post.dart';
import 'package:http/http.dart';
import 'package:json_fetcher/json_fetcher.dart';
import 'package:json_fetcher/standard_fetchers.dart';

void main() async {
  final client = JsonHttpClient(Client(), createCache('temp'));
  final postsStream = JsonFetcher<List<Post>>(
    client,
    (json) => (json as List).map((e) => Post.fromJson(e as Map<String, dynamic>)).toList(),
  ).fetch('https://jsonplaceholder.typicode.com/posts');

  await for (final posts in postsStream) {
    for (final post in posts) {
      print(post);
    }
  }

  exit(0);
}
