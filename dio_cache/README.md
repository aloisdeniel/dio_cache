# dio_cache

A plugin for [dio](https://pub.dev/packages/dio) that caches responses for better optimization and offline data access.

## Usage

```dart
import 'package:dio_cache/dio_cache.dart';
```

#### Basic configuration

```dart
final dio = Dio()
  ..interceptors.add(CacheInterceptor());
```

#### Global caching options

```dart
final dio = Dio()
  ..interceptors.add(CacheInterceptor(
    options: const CacheOptions(
      store: MemoryCacheStore(), // The store used for response cache
      forceUpdate: false, // Forces to update even if cache isn't expired
      forceCache: false, // Forces to use cache, even if expired
      priority: CachePriority.normal, // Setting a priority to clean only several requests
      returnCacheOnError: true, // Returns a cached response on error if available
      isCached: true, // Bypass caching if [false]
      expiry: const Duration(minutes: 1), // The cache expiry, after which a new request is triggered instead of getting the cached response
      keyBuilder: (request) => "${request.method}_${CacheInterceptor.uuid.v5(Uuid.NAMESPACE_URL, request.uri.toString())}" // Builds the unqie key used for indexing a request in cache (this may be useful if arguments aren't passed in query but in body)
    )
  )
);
```

#### Sending a request with options

```dart
final forcedResponse = await dio.get("http://www.flutter.dev", options: Options(
    extra: CacheOptions(
      forceUpdate: true
    ).toExtra(),
  ));
```

#### Cleaning cached values from global store

```dart
interceptor.options.store.clean(CachePriority.low);
```

#### Getting more info about caching status

```dart
final response = await dio.get("http://www.flutter.dev");
final cachedResult = CacheResult.fromExtra(response);
if(cachedResult.isFromCache) {
  print("expiry: ${cachedResult.cache.expiry}, downloadedAt: ${cachedResult.cache.downloadedAt}");
}
```

#### Invalidating a cached value  from global store

```dart
final cachedResult = CacheResult.fromExtra(response);
interceptor.options.store.invalidate(cachedResult.cache.key);
```

#### Logging caching operations

```dart
final dio = Dio()
  ..interceptors.add(CacheInterceptor(logger: Logger("Cache")));
```

## Availables stores

| name | description |
| --- | --- |
| [MemoryCacheStore](https://pub.dartlang.org/documentation/dio_cache/latest/dio_cache/MemoryCacheStore-class.html) | Stores all cached responses in a map in memory |
| [FileCacheStore](https://pub.dartlang.org/documentation/dio_cache/latest/dio_cache/FileCacheStore-class.html) | Stores each request in a dedicated file |
| [BackupCacheStore](https://pub.dartlang.org/documentation/dio_cache/latest/dio_cache/BackupCacheStore-class.html) | Reads values primarly from memory and backup values to specified store (ex: a FileCacheStore) |
| [FilteredCacheStore](https://pub.dartlang.org/documentation/dio_cache/latest/dio_cache/FilteredCacheStore-class.html) | Ignoring responses for save |

## Features and bugs

Please file issues.
