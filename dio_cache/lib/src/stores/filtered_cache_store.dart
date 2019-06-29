import 'package:dio_cache/src/cache_response.dart';
import 'package:meta/meta.dart';

import 'cache_store.dart';

typedef bool CacheResponseFilter(CacheResponse response);

/// A store that will only [set] on [child] responses that matches
/// the given [filter].
/// 
/// All other operations are simply proxies to [child].
class FilteredCacheStore extends CacheStore {

  final CacheStore child;

  final CacheResponseFilter filter;

  const FilteredCacheStore({@required this.child, @required this.filter});

  @override
  Future<void> delete(String key) {
    return child.delete(key);
  }

  @override
  Future<CacheResponse> get(String key) {
    return child.get(key);
  }

  @override
  Future<void> set(CacheResponse response) {
    if(this.filter(response)) {
      return child.set(response);
    }
    return Future.value();
  }

  @override
  Future<void> updateExpiry(String key, DateTime newExpiry) {
    return child.updateExpiry(key, newExpiry);
  }

  @override
  Future<void> clean(CachePriority priorityOrBelow) {
    return child.clean(priorityOrBelow);
  }
}