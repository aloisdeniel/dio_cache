import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';

import '../cache_response.dart';
import 'cache_store.dart';

/// A store that save each request result in a dedicated file.
///
/// This is better for large responses that aren't updated too often.
///
/// A database based store is preferable in most cases.
class FileCacheStore extends CacheStore {
  final uuid = Uuid();
  final Map<CachePriority, Directory> directories;

  FileCacheStore(Directory directory)
      : this.directories =
            Map.fromEntries(Iterable.generate(CachePriority.values.length, (i) {
          final priority = CachePriority.values[i];
          return MapEntry(priority,
              Directory(path.join(directory.path, priority.index.toString())));
        }));

  File _findFile(String method, String url) {
    final filename = _fileNameFromUrl(method, url);
    for (var item in directories.entries) {
      final file = File(path.join(item.value.path, filename));
      if (file.existsSync()) {
        return file;
      }
    }

    return null;
  }

  String _fileNameFromUrl(String method, String url) =>
      method + "_" + uuid.v5(Uuid.NAMESPACE_URL, url);

  @override
  Future<void> clean(CachePriority priorityOrBelow) {
    final futures = Iterable.generate(priorityOrBelow.index, (i) {
      final directory = directories[CachePriority.values[i]];
      return directory.delete(recursive: true);
    });

    return Future.wait(futures);
  }

  @override
  Future<void> delete(String method, String url) async {
    final file = await _findFile(method, url);
    if (file != null) {
      await file.delete();
    }
  }

  @override
  Future<CacheResponse> get(String method, String url) async {
    final file = await _findFile(method, url);
    if (file != null) {
      final result = await _deserializeCacheResponse(file);
      return result;
    }
    return null;
  }

  @override
  Future<void> set(CacheResponse response) async {
    await delete(response.method, response.url);
    final filename = _fileNameFromUrl(response.method, response.url);
    final file = File(path.join(directories[response.priority].path, filename));

    if (!file.parent.existsSync()) {
      await file.parent.create(recursive: true);
    }
    final bytes = _serializeCacheResponse(response);
    await file.writeAsBytes(bytes);
  }

  @override
  Future<void> updateExpiry(
      String method, String url, DateTime newExpiry) async {
    final file = await _findFile(method, url);
    if (file != null) {
      final previous = await _deserializeCacheResponse(file);
      final bytes = _serializeCacheResponse(previous.copyWith(expiry: newExpiry));
      await file.writeAsBytes(bytes);
    }
  }
}

List<int> _serializeCacheResponse(CacheResponse response) {
  final encodedUrl = utf8.encode(response.url);
  final encodedEtag = utf8.encode(response.eTag ?? "");
  final encodedExpiry =
      Int32List.fromList([response.expiry.microsecondsSinceEpoch])
          .buffer
          .asInt8List();
  return []
    ..addAll(Int32List.fromList(
            [encodedUrl.length, encodedEtag.length, encodedExpiry.length])
        .buffer
        .asInt8List())
    ..addAll(encodedUrl)
    ..addAll(encodedEtag)
    ..addAll(encodedExpiry)
    ..addAll(response.content);
}

Future<CacheResponse> _deserializeCacheResponse(File file) async {
  
  final data = await file.readAsBytes();

  var i = 4 + 4 + 4;
  final sizes = Int8List.fromList(data.take(i).toList()).buffer.asInt32List();

  var size = sizes[0];
  final decodedUrl = utf8.decode(data.skip(i).take(size).toList());

  i += size;
  size = sizes[1];
  final decodedEtag = utf8.decode(data.skip(i).take(size).toList());

  i += size;
  size = sizes[2];
  final decodedExpiry = Int8List.fromList(data.skip(i).take(size).toList())
      .buffer
      .asInt32List()
      .first;

  i += size;
  size = data.length - i;
  final decodedContent = data.skip(i).take(size).toList();

  return CacheResponse(
    url: decodedUrl,
    eTag: decodedEtag,
    downloadedAt: await file.lastModified(),
    method: path.basename(file.path).split("_")[0],
    priority: CachePriority.values[int.parse(path.basename(file.parent.path))],
    content: decodedContent,
    expiry: DateTime.fromMillisecondsSinceEpoch(decodedExpiry),
  );
}
