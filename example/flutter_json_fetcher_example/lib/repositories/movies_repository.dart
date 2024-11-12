// Created by alex@justprodev.com on 27.08.2024.

import 'package:json_fetcher/json_fetcher.dart';
import 'package:json_fetcher/standard_fetchers.dart';

import '../model/movie.dart';
import 'base_repository.dart';

// see release_web.sh
const _moviesUrl = 'https://justprodev.com/demo/json_fetcher_flutter/movies.json';

class MoviesRepository extends BaseRepository<Movie> {
  const MoviesRepository(
    JsonHttpClient client,
  ) : super(client: client, url: _moviesUrl);

  @override
  Stream<List<Movie>> getItems() {
    return IsolatedJsonFetcher(
      client,
      (json) => (json as List).map((e) => Movie.fromJson(e as Map<String, dynamic>)).toList().reversed.toList(),
    ).fetch(url);
  }
}
