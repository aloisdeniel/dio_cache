import 'package:dio/dio.dart';

import 'cache_response.dart';

class CacheResult {
  static const extraKey = "cache_interceptor_response";

  final CacheResponse cache;
  bool get isFromCache => cache != null;
  CacheResult.cached(this.cache);
  const CacheResult.empty() : this.cache = null;

  factory CacheResult.fromExtra(Response response) {
    return response.extra[extraKey] ?? const CacheResult.empty();
  }
  Map<String, dynamic> toExtra() => {
        extraKey: this,
      };
}