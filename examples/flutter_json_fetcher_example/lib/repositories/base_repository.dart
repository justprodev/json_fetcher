// Created by alex@justprodev.com on 27.08.2024.

import 'package:flutter/foundation.dart';
import 'package:json_fetcher/json_fetcher.dart';

abstract class BaseRepository<Item> {
  final JsonHttpClient client;
  final String url;

  const BaseRepository({required this.client, required this.url});

  Stream<List<Item>> getItems();

  @nonVirtual
  Future<void> clearCache() => client.cache.evict(url);
}
