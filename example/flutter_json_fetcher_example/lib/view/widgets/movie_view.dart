// Created by alex@justprodev.com on 27.08.2024.

import 'package:cached_image/cached_image.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../../model/movie.dart';

class MovieView extends StatelessWidget {
  final Movie movie;
  final int index;

  const MovieView({
    super.key,
    required this.index,
    required this.movie,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    if (size.width > 600) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: showDescription(),
            ),
          ),
          if (movie.thumbnail != null)
            Padding(
              padding: const EdgeInsets.only(left: 16),
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: movie.href != null ? () => launchUrlString('https://en.wikipedia.org/wiki/${movie.href}') : null,
                child: CachedImage.image(
                  movie.thumbnail,
                  fit: BoxFit.cover,
                  height: 200,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
        ],
      );
    } else {
      return Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...showDescription(),
          if (movie.thumbnail != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: movie.href != null ? () => launchUrlString('https://en.wikipedia.org/wiki/${movie.href}') : null,
                child: CachedImage.image(
                  movie.thumbnail,
                  fit: BoxFit.fitHeight,
                  width: double.infinity,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
        ],
      );
    }
  }

  List<Widget> showDescription() {
    return [
      SelectableText('Movie #${index + 1}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: movie.href != null ? () => launchUrlString('https://en.wikipedia.org/wiki/${movie.href}') : null,
        child: Text(
          'Title: ${movie.title ?? ''}',
          style: movie.href != null
              ? const TextStyle(decoration: TextDecoration.underline, color: Colors.deepPurple, fontWeight: FontWeight.bold)
              : null,
        ),
      ),
      SelectableText('Year: ${movie.year ?? ''}'),
      if (movie.genres?.isNotEmpty == true) SelectableText('Genres: ${movie.genres!.join(', ')}'),
      if (movie.cast?.isNotEmpty == true) SelectableText('Cast: ${movie.cast?.join(', ') ?? ''}'),
      if (movie.extract != null) SelectableText('Extract: ${movie.extract}'),
    ];
  }
}
