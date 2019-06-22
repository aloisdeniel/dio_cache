
import 'package:dio/dio.dart';

import 'cache_response.dart';

class CacheOptions {
  /// The duration after the cached result of the request 
  /// will be expired.
  final Duration expiry;

  /// The priority of a request will makes it 
  /// easier cleanable by a store if needed.
  final CachePriority priority;

  /// Forces to request a new value, even if an valid 
  /// cache is available.
  final bool forceUpdate;

  /// Forces to return the cached value if available (even
  /// if expired).
  final bool forceCache;

  /// Indicates whether the request should use cache.
  final bool isCached;

  /// If [true], on error, if a value is available in the
  /// store if is returned as a successful response (even
  /// if expired).
  final bool returnCacheOnError;

  const CacheOptions(
      {this.forceUpdate = false,
      this.forceCache = false,
      this.priority = CachePriority.normal,
      this.returnCacheOnError = true,
      this.isCached  = true,
      this.expiry = const Duration(minutes: 1)})
      : assert(forceUpdate != null),
        assert(isCached != null),
        assert(priority != null),
        assert(expiry != null);

  static const extraKey = "cache_interceptor_request";

  factory CacheOptions.fromExtra(RequestOptions request) {
    return request.extra[extraKey];
  }

  Map<String,dynamic> toExtra() {
    return {
      extraKey: this,
    };
  }
}
