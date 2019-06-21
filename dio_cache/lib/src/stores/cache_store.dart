import 'package:dio/dio.dart';

import '../cache_response.dart';

abstract class CacheStore {
  const CacheStore();
  Future<CacheResponse> get(String method, String url);
  Future<void> set(CacheResponse response);
  Future<void> updateExpiry(String method, String url, DateTime newExpiry);
  Future<void> delete(String method, String url);
  Future<void> clean(CachePriority priorityOrBelow);
  Future<void> invalidate(String method, String url) => this.updateExpiry(method, url,  DateTime.fromMillisecondsSinceEpoch(0));
}