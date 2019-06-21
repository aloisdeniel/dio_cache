import '../cache_response.dart';
import 'cache_store.dart';

/// A store that keeps responses into a simple [Map] in memory.
/// 
/// This store should be used carefully, and 
class MemoryCacheStore extends CacheStore {
  final Map<CachePriority, List<CacheResponse>> _responses = {};

  MemoryCacheStore();

  @override
  Future<void> clean(CachePriority priorityOrBelow) {
    for (var i = 0; i <= priorityOrBelow.index; i++) {
      _responses.remove(CachePriority.values[i]);
    }
    return Future.value();
  }

  @override
  Future<CacheResponse> get(String method, String url) {
    return Future.value(_responses.entries.expand((x) => x.value).firstWhere((x) => x.url == url && x.method == method, orElse: () => null));
  }

  @override
  Future<void> set(CacheResponse response) async {
    
    await this.delete(response.method, response.url);

    final withPriority = _responses.putIfAbsent(response.priority, () => <CacheResponse>[]);
    withPriority.add(response);
  }

  @override
  Future<void> updateExpiry(String method, String url, DateTime newExpiry) {
     _responses.entries.forEach((entry) {
      final index = entry.value.indexWhere((x) => x.url == url && x.method == method);
      if(index >= 0) {
        entry.value[index] = entry.value[index].copyWith(expiry: newExpiry);
      }
    });

    return Future.value();
  }

  @override
  Future<void> delete(String method, String url) {
    _responses.entries.forEach((entry) {
      entry.value.removeWhere((x) => x.url == url && x.method == method);
    });
    return Future.value();
  }
}