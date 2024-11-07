// Created by alex@justprodev.com on 27.08.2024.

import 'package:json_fetcher/json_fetcher.dart';
import 'package:json_fetcher/standard_fetchers.dart';

import '../model/movie.dart';
import 'base_repository.dart';

class MoviesRepository extends BaseRepository<Movie> {
  const MoviesRepository(
    JsonHttpClient client,
  ) : super(client: client, url: 'https://raw.githubusercontent.com/prust/wikipedia-movie-data/master/movies.json');

  @override
  Stream<List<Movie>> getItems() {
    return IsolatedJsonFetcher(
      client,
      (json) => (json as List).map((e) => Movie.fromJson(e as Map<String, dynamic>)).toList().reversed.toList(),
    ).fetch(url);
  }
}
