import 'package:flutter/material.dart';
import 'package:flutter_json_fetcher_example/repositories/movies_repository.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';

import 'api/create_client.dart';
import 'model/comment.dart';
import 'model/movie.dart';
import 'repositories/base_repository.dart';
import 'repositories/comments_repository.dart';
import 'utils/path/get_path_web.dart' if (dart.library.io) 'utils/path/get_path_io.dart';
import 'view/app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  Logger.root.onRecord.listen((record) {
    debugPrint('${record.level.name}: ${record.time}: ${record.message}');
  });

  final client = createClient(getPath());

  runApp(
    MultiProvider(
      providers: [
        Provider<BaseRepository<Comment>>(create: (_) => CommentsRepository(client)),
        Provider<BaseRepository<Movie>>(create: (_) => MoviesRepository(client)),
      ],
      child: const App(),
    ),
  );
}
