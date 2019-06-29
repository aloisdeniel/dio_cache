import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio_cache/dio_cache.dart';
import 'package:logging/logging.dart';

main() async {
  // Displaying logs
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    print('${record.level.name}: ${record.time}: ${record.message}');
  });

  // Add the interceptor with optional options
  final cacheInterceptor = CacheInterceptor(
    logger: Logger("Cache"),
    options: CacheOptions(
      expiry: const Duration(minutes: 30),
      store: BackupCacheStore(backupStore: FileCacheStore(Directory(".cache"))),
    ),
  );
  final dio = Dio()..interceptors.add(cacheInterceptor);

  // The first request will get data and add it to cache
  final distantResponse = await dio.get("http://www.flutter.dev");
  print(
      "Distant -> statusCode: ${distantResponse.statusCode}, data : ${distantResponse.data.substring(0, 20)}...");

  await Future.delayed(const Duration(seconds: 5));

  // The second request will use the cached value
  final cachedResponse = await dio.get("http://www.flutter.dev");
  print(
      "Cached -> statusCode: ${cachedResponse.statusCode}, data : ${distantResponse.data.substring(0, 20)}...");

  // To get more info about the cache
  final cachedExtra = CacheResult.fromExtra(cachedResponse);
  if (cachedExtra.isFromCache) {
    print(
        "isFromCache: ${cachedExtra.isFromCache}, expiry: ${cachedExtra.cache.expiry}, downloadedAt: ${cachedExtra.cache.downloadedAt}");
  }

  // The new request will get data and add it to cache
  final forcedResponse = await dio.get("http://www.flutter.dev",
      options: Options(
        extra: CacheOptions(forceUpdate: true).toExtra(),
      ));
  print(
      "Forced -> statusCode: ${forcedResponse.statusCode}, data : ${forcedResponse.data.substring(0, 20)}...");

  // To get more info about the cache
  final forcedCachedExtra = CacheResult.fromExtra(forcedResponse);
  print("isFromCache: ${forcedCachedExtra.isFromCache}");

  // To invalidate a cached request
  final key = await cacheInterceptor.options.store.invalidate(cachedExtra.cache.key);
}
