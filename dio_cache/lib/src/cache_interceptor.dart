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
  final CacheStore store;
  final CacheOptions options;
  final Logger logger;

  CacheInterceptor(
      {CacheStore store, CacheOptions options, this.logger})
      : this.store = store ?? MemoryCacheStore(),
        this.options = options ?? const CacheOptions();

  CacheOptions _optionsForRequest(RequestOptions options) {
    return CacheOptions.fromExtra(options) ?? this.options;
  }

  @override
  onRequest(RequestOptions options) async {
    final extraOptions = _optionsForRequest(options);

    if (!extraOptions.isCached) {
      return await super.onRequest(options);
    }

    final existing =
        await this.store.get(options.method, options.uri.toString());

    existing?.updateRequest(options, !extraOptions.forceUpdate);

    if (extraOptions.forceUpdate) {
      logger?.fine("[${options.uri}] Update forced, cache is ignored");
      return await super.onRequest(options);
    }

    if (existing == null) {
      logger?.fine("[${options.uri}] No existing cache, starting a new request");
      return await super.onRequest(options);
    }

    if (!extraOptions.forceCache && existing.expiry.isBefore(DateTime.now())) {
      logger?.fine(
          "[${options.uri}] Cache expired since ${existing.expiry}, starting a new request");
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
        logger?.warning(
            "[${err.request.uri}] An error occured, but using an existing cache : ${err.error}");
        return existing;
      }
    }

    return super.onError(err);
  }

  @override
  onResponse(Response response) async {
    final requestExtra = _optionsForRequest(response.request);
    final extras = CacheResult.fromExtra(response);

    // If response is not extracted from cache we save it into the store
    if (!extras.isFromCache && requestExtra.isCached) {
      if (response.statusCode == HttpStatus.notModified) {
        final existing = CacheResponse.fromRequestOptions(response.request);
        return existing.toResponse(response.request);
      }

      if (isValidHttpStatusCode(response.statusCode)) {
        final expiry = DateTime.now().add(requestExtra.expiry);
        final newCache = await CacheResponse.fromResponse(
            response, expiry, requestExtra.priority);
        logger?.fine(
            "[${response.request.uri}] Creating a new cache entry than expires on  $expiry");
        await this.store.set(newCache);
      }
    }

    return await super.onResponse(response);
  }
}
