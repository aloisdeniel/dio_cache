
import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

import '../dio_cache.dart';
import 'cache_response.dart';


typedef String CacheKeyBuilder(RequestOptions request);

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

  /// The store used for caching data.
  final CacheStore store;

  // Builds the unqie key used for indexing a request in cache.
  //
  // Defaults to `(request) => "${request.method}_${uuid.v5(Uuid.NAMESPACE_URL, request.uri.toString())}"`
  final CacheKeyBuilder keyBuilder;

  const CacheOptions(
      {this.forceUpdate = false,
      this.forceCache = false,
      this.priority = CachePriority.normal,
      this.returnCacheOnError = true,
      this.isCached  = true,
      this.keyBuilder = defaultCacheKeyBuilder,
      this.store,
      this.expiry = const Duration(minutes: 1)})
      : assert(forceUpdate != null),
        assert(isCached != null),
        assert(priority != null),
        assert(keyBuilder != null),
        assert(expiry != null);

  static const extraKey = "cache_interceptor_request";

  factory CacheOptions.fromExtra(RequestOptions request) {
    return request.extra[extraKey];
  }


  static final uuid = Uuid();

  static String defaultCacheKeyBuilder(RequestOptions request) {
    return "${request.method}_${uuid.v5(Uuid.NAMESPACE_URL, request.uri.toString())}";
  }

  Map<String,dynamic> toExtra() {
    return {
      extraKey: this,
    };
  }

  Options toOptions() {
    return Options(
      extra: this.toExtra()
    );
  }

  Options mergeIn(Options options) {
    return options.merge(
      extra: <String,dynamic>{}
        ..addAll(options.extra ?? {})
        ..addAll(this.toExtra())
    );
  }
}
