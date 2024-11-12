// Created by alex@justprodev.com on 27.08.2024.

import 'package:flutter/material.dart';

import '../model/comment.dart';
import '../model/movie.dart';
import 'feed_page_view.dart';
import 'widgets/comment_view.dart';
import 'widgets/movie_view.dart';

class App extends StatelessWidget {
  const App({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Json Fetcher Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: false,
      ),
      home: DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            title: const TabBar(
              tabs: <Widget>[
                Tab(text: 'Comments (simple)'),
                Tab(text: 'Movies (isolated ~25 MB)'),
              ],
            ),
          ),
          body: const TabBarView(
            children: <Widget>[
              FeedPageView<Comment>(
                itemBuilder: _commentsBuilder,
                sourceCodeUrl: 'https://github.com/justprodev/json_fetcher/blob/master/example/flutter_json_fetcher_example/lib/repositories/comments_repository.dart',
              ),
              FeedPageView<Movie>(
                itemBuilder: _moviesBuilder,
                sourceCodeUrl: 'https://github.com/justprodev/json_fetcher/blob/master/example/flutter_json_fetcher_example/lib/repositories/movies_repository.dart',
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _commentsBuilder(int index, Comment item) => CommentView(index: index, comment: item);

  static Widget _moviesBuilder(int index, Movie item) => MovieView(index: index, movie: item);
}
