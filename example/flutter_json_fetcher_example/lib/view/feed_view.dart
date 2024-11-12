// Created by alex@justprodev.com on 27.08.2024.

import 'package:flutter/material.dart';
import 'package:flutter_json_fetcher_example/repositories/base_repository.dart';
import 'package:provider/provider.dart';

class FeedView<Item> extends StatelessWidget {
  final Widget Function(int index, Item) itemBuilder;

  const FeedView({super.key, required this.itemBuilder});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: context.read<BaseRepository<Item>>().getItems(),
      builder: (_, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: SelectableText('Error: ${snapshot.error}', textAlign: TextAlign.center),
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final items = snapshot.data!;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemBuilder: (_, index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 32),
              child: itemBuilder(index, items[index]),
            );
          },
          itemCount: items.length,
        );
      },
    );
  }
}
