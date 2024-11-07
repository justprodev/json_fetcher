// Created by alex@justprodev.com on 27.08.2024.

import 'package:json_fetcher/json_fetcher.dart';
import 'package:json_fetcher/standard_fetchers.dart';

import '../model/comment.dart';
import 'base_repository.dart';

class CommentsRepository extends BaseRepository<Comment> {
  const CommentsRepository(
    JsonHttpClient client,
  ) : super(client: client, url: 'https://jsonplaceholder.typicode.com/comments');

  @override
  Stream<List<Comment>> getItems() {
    return JsonFetcher(
      client,
      (json) => (json as List).map((e) => Comment.fromJson(e as Map<String, dynamic>)).toList(),
    ).fetch(url);
  }
}
