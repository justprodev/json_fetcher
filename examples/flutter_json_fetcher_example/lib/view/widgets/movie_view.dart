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
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Movie #${index + 1}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text('Title: ${movie.title ?? ''}'),
              Text('Year: ${movie.year ?? ''}'),
              if (movie.genres?.isNotEmpty == true) Text('Genres: ${movie.genres!.join(', ')}'),
              if (movie.cast?.isNotEmpty == true) Text('Cast: ${movie.cast?.join(', ') ?? ''}'),
              if (movie.extract != null) Text('Extract: ${movie.extract}'),
            ],
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
  }
}
