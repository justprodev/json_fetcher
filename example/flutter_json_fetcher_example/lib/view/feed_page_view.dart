// Created by alex@justprodev.com on 28.08.2024.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../repositories/base_repository.dart';
import 'feed_view.dart';

class FeedPageView<Item> extends StatefulWidget {
  final Widget Function(int index, Item) itemBuilder;
  final String sourceCodeUrl;

  const FeedPageView({super.key, required this.itemBuilder, required this.sourceCodeUrl});

  @override
  State<FeedPageView<Item>> createState() => _FeedPageViewState<Item>();
}

class _FeedPageViewState<Item> extends State<FeedPageView<Item>> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  GlobalKey feedKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      body: Stack(
        children: [
          FeedView<Item>(key: feedKey, itemBuilder: widget.itemBuilder),
          Positioned(
            bottom: 8,
            left: 0,
            right: 0,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FloatingActionButton(
                  mini: true,
                  tooltip: 'Refresh',
                  onPressed: () => setState(() => feedKey = GlobalKey()),
                  child: const Icon(Icons.refresh),
                ),
                const SizedBox(width: 16),
                FloatingActionButton(
                  mini: true,
                  backgroundColor: Colors.red.shade900,
                  tooltip: 'Clear cache & Refresh',
                  onPressed: () async {
                    context.read<BaseRepository<Item>>().clearCache();
                    setState(() => feedKey = GlobalKey());
                  },
                  child: const Icon(Icons.delete_forever),
                ),
                const SizedBox(width: 16),
                FloatingActionButton(
                  mini: true,
                  tooltip: 'Source code',
                  backgroundColor: Colors.grey,
                  onPressed: () => launchUrlString(widget.sourceCodeUrl),
                  child: const Icon(Icons.code),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
