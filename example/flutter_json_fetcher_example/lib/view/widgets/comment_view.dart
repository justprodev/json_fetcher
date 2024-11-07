// Created by alex@justprodev.com on 27.08.2024.

import 'package:flutter/material.dart';

import '../../model/comment.dart';

class CommentView extends StatelessWidget {
  final Comment comment;
  final int index;

  const CommentView({
    super.key,
    required this.index,
    required this.comment,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Comment #${index + 1}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text('Name: ${comment.name}', style: const TextStyle(fontWeight: FontWeight.bold)),
        Text('Email: ${comment.email}', style: const TextStyle(fontStyle: FontStyle.italic)),
        const SizedBox(height: 8),
        Text('${comment.body}'),
      ],
    );
  }
}
