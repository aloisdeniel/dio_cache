import 'package:dio/dio.dart';

import '../cache_response.dart';

abstract class CacheStore {
  const CacheStore();
  Future<CacheResponse> get(String key);
  Future<void> set(CacheResponse response);
  Future<void> updateExpiry(String key, DateTime newExpiry);
  Future<void> delete(String key);
  Future<void> clean(CachePriority priorityOrBelow);
  Future<void> invalidate(String key) => this.updateExpiry(key,  DateTime.fromMillisecondsSinceEpoch(0));
}