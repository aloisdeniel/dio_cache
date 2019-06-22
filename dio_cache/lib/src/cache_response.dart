import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:meta/meta.dart';

import 'result.dart';

enum CachePriority {
  low,
  normal,
  high,
}

class CacheResponse {
  final String url;
  final String method;
  final DateTime expiry;
  final DateTime downloadedAt;
  final String eTag;
  final CachePriority priority;
  final List<int> content;

  CacheResponse(
      {@required this.url,
      @required this.expiry,
      @required this.method,
      @required this.priority,
      @required this.downloadedAt,
      @required this.eTag,
      @required this.content});

  static Future<CacheResponse> fromResponse(
      Response response, DateTime expiry, CachePriority priority) async {
    final content = await _serializeData(response.request.responseType, response.data);
    return CacheResponse(
      url: response.request.uri.toString(),
      method: response.request.method,
      content: content,
      eTag: response.headers["ETag"]?.first,
      expiry: expiry,
      priority: priority,
      downloadedAt: DateTime.now(),
    );
  }

  factory CacheResponse.fromError(DioError error) {
    return CacheResponse.fromRequestOptions(error.request);
  }

  factory CacheResponse.fromRequestOptions(RequestOptions request) {
    return request.extra["cache_response"];
  }

  CacheResponse copyWith({
    List<int> content,
    DateTime downloadedAt,
    String eTag,
    DateTime expiry,
    CachePriority priority,
    int statusCode,
    String method,
    String url,
  }) => CacheResponse(
    method: method ?? this.method,
    content: content ?? this.content,
    downloadedAt: downloadedAt ?? this.downloadedAt,
    eTag: eTag ?? this.eTag,
    expiry: expiry ?? this.expiry,
    priority: priority?? this.priority,
    url: url ?? this.url,
  );

  void updateRequest(RequestOptions options, bool addModifiedHeaders) {
    if(addModifiedHeaders) {
      options.headers["If-Modified-Since"] = this.downloadedAt;
      if (this.eTag != null) {
        options.headers["ETag"] = this.eTag;
      }
    }

    options.extra["cache_response"] = this;
  }

  Response toResponse(RequestOptions options) {
    return Response(
      extra: {}
        ..addAll(options.extra)
        ..addAll(CacheResult.cached(this).toExtra()), 
      data: _deserializeData(options.responseType),
      headers: DioHttpHeaders(),
      statusCode: HttpStatus.notModified,
      request: options,
    );
  }

  static Future<List<int>> _serializeData(ResponseType type, dynamic data) async {
     if(type == ResponseType.bytes){
      return data;
    }
    if(type == ResponseType.stream) {
      return (await (data as Stream<List<int>>).toList()).expand((x) => x);
    }

    if(type == ResponseType.plain) {
      return utf8.encode(data);
    }

    if(type == ResponseType.json) {
      return utf8.encode(jsonEncode(data));
    }

    throw new UnsupportedError("Not supported ResponseType : $type. Please file an issue on repository to add compatibility");
  }

  dynamic _deserializeData(ResponseType type) {
    if(type == ResponseType.bytes){
      return this.content;
    }
    if(type == ResponseType.stream) {
      return Stream<List<int>>.fromIterable([this.content]);
    }

    final text = utf8.decode(this.content);

    if(type == ResponseType.plain) {
      return text;
    }

    if(type == ResponseType.json) {
      return jsonDecode(text);
    }

    throw new UnsupportedError("Not supported ResponseType : $type. Please file an issue on repository to add compatibility");
  }
}
