import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio_cache/src/cache_response.dart';
import 'package:dio_cache/src/stores/memory_cache_store.dart';
import 'package:logging/logging.dart';

import 'options.dart';
import 'result.dart';
import 'helpers/status_code.dart';
import 'stores/cache_store.dart';

class CacheInterceptor extends Interceptor {
  final CacheOptions options;
  final Logger logger;
  final CacheStore _globalStore;

  CacheInterceptor({CacheOptions options, this.logger})
      : this.options = options ?? const CacheOptions(),
        this._globalStore = options.store ?? MemoryCacheStore();

  CacheOptions _optionsForRequest(RequestOptions options) {
    return CacheOptions.fromExtra(options) ?? this.options;
  }

  @override
  onRequest(RequestOptions options) async {
    final extraOptions = _optionsForRequest(options);

    if (!extraOptions.isCached) {
      return await super.onRequest(options);
    }

    final cacheKey = extraOptions.keyBuilder(options);
    assert(cacheKey != null, "The cache key builder produced an empty key");
    final store = extraOptions.store ?? _globalStore;
    final existing = await store.get(cacheKey);

    existing?.updateRequest(options, !extraOptions.forceUpdate);

    if (extraOptions.forceUpdate) {
      logger
          ?.fine("[$cacheKey][${options.uri}] Update forced, cache is ignored");
      return await super.onRequest(options);
    }

    if (existing == null) {
      logger?.fine(
          "[$cacheKey][${options.uri}] No existing cache, starting a new request");
      return await super.onRequest(options);
    }

    if (!extraOptions.forceCache && existing.expiry.isBefore(DateTime.now())) {
      logger?.fine(
          "[$cacheKey][${options.uri}] Cache expired since ${existing.expiry}, starting a new request");
      return await super.onRequest(options);
    }

    return existing.toResponse(options);
  }

  @override
  onError(DioError err) {
    final extraOptions = _optionsForRequest(err.request);
    if (extraOptions.returnCacheOnError) {
      final existing = CacheResponse.fromError(err);
      if (existing != null) {
        final cacheKey = extraOptions.keyBuilder(err.request);
        logger?.warning(
            "[$cacheKey][${err.request.uri}] An error occured, but using an existing cache : ${err.error}");
        return existing;
      }
    }

    return super.onError(err);
  }

  @override
  onResponse(Response response) async {
    final requestExtra = _optionsForRequest(response.request);
    final extras = CacheResult.fromExtra(response);
    final store = requestExtra.store ?? _globalStore;

    // If response is not extracted from cache we save it into the store
    if (!extras.isFromCache && requestExtra.isCached) {
      if (response.statusCode == HttpStatus.notModified) {
        final existing = CacheResponse.fromRequestOptions(response.request);
        return existing.toResponse(response.request);
      }

      if (isValidHttpStatusCode(response.statusCode)) {
        final cacheKey = requestExtra.keyBuilder(response.request);
        final expiry = DateTime.now().add(requestExtra.expiry);
        final newCache = await CacheResponse.fromResponse(
            cacheKey, response, expiry, requestExtra.priority);
        logger?.fine(
            "[$cacheKey][${response.request.uri}] Creating a new cache entry than expires on  $expiry");
        await store.set(newCache);
      }
    }

    return await super.onResponse(response);
  }
}
