import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;

/// Local Streaming HTTP Proxy Server.
/// Enables simultaneous low-latency audio playback and chunked disk caching
/// with full HTTP Range (206 Partial Content) support.
class StreamCacheProxy {
  HttpServer? _server;
  final Directory cacheDir;
  final http.Client _httpClient = http.Client();

  StreamCacheProxy({required this.cacheDir});

  int get port => _server?.port ?? 0;
  String get address => 'http://127.0.0.1:$port';

  Future<void> start() async {
    if (!cacheDir.existsSync()) {
      cacheDir.createSync(recursive: true);
    }
    _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    _server!.listen(_handleRequest);
  }

  Future<void> stop() async {
    await _server?.close(force: true);
    _server = null;
  }

  /// Transforms a remote stream URL into a proxied localhost URL
  String getProxiedUrl(String remoteUrl, String trackId) {
    final encodedRemote = Uri.encodeComponent(remoteUrl);
    final encodedId = Uri.encodeComponent(trackId);
    return '$address/stream?url=$encodedRemote&id=$encodedId';
  }

  Future<void> _handleRequest(HttpRequest request) async {
    final remoteUrl = request.uri.queryParameters['url'];
    final trackId = request.uri.queryParameters['id'] ?? 'unknown';

    if (remoteUrl == null || remoteUrl.isEmpty) {
      request.response.statusCode = HttpStatus.badRequest;
      await request.response.close();
      return;
    }

    final sanitizedId = trackId.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    final cacheFile = File('${cacheDir.path}/$sanitizedId.audio');
    final isFullyCached = cacheFile.existsSync();

    if (isFullyCached) {
      await _serveFromLocalFile(request, cacheFile);
    } else {
      await _pipeAndCache(request, remoteUrl, cacheFile);
    }
  }

  Future<void> _serveFromLocalFile(HttpRequest request, File file) async {
    final fileLength = file.lengthSync();
    final rangeHeader = request.headers.value(HttpHeaders.rangeHeader);

    request.response.headers.set(HttpHeaders.acceptRangesHeader, 'bytes');
    request.response.headers.set(HttpHeaders.contentTypeHeader, 'audio/mpeg');

    if (rangeHeader != null && rangeHeader.startsWith('bytes=')) {
      final parts = rangeHeader.substring(6).split('-');
      final start = int.tryParse(parts[0]) ?? 0;
      final end = parts.length > 1 && parts[1].isNotEmpty
          ? int.tryParse(parts[1]) ?? (fileLength - 1)
          : (fileLength - 1);

      final contentLength = (end - start) + 1;
      request.response.statusCode = HttpStatus.partialContent;
      request.response.headers.set(
        HttpHeaders.contentRangeHeader,
        'bytes $start-$end/$fileLength',
      );
      request.response.headers.set(HttpHeaders.contentLengthHeader, contentLength);

      final stream = file.openRead(start, end + 1);
      await request.response.addStream(stream);
    } else {
      request.response.statusCode = HttpStatus.ok;
      request.response.headers.set(HttpHeaders.contentLengthHeader, fileLength);
      await request.response.addStream(file.openRead());
    }

    await request.response.close();
  }

  Future<void> _pipeAndCache(
    HttpRequest clientRequest,
    String remoteUrl,
    File targetCacheFile,
  ) async {
    try {
      final remoteUri = Uri.parse(remoteUrl);
      final req = http.Request('GET', remoteUri);

      // Forward Range request to remote CDN
      final range = clientRequest.headers.value(HttpHeaders.rangeHeader);
      if (range != null) {
        req.headers[HttpHeaders.rangeHeader] = range;
      }

      final streamedResponse = await _httpClient.send(req);
      clientRequest.response.statusCode = streamedResponse.statusCode;

      streamedResponse.headers.forEach((key, value) {
        if (key.toLowerCase() != 'transfer-encoding') {
          clientRequest.response.headers.set(key, value);
        }
      });

      // Stream to client while appending to partial cache file
      final tempFile = File('${targetCacheFile.path}.tmp');
      final sink = tempFile.openWrite(mode: FileMode.append);

      await for (final chunk in streamedResponse.stream) {
        clientRequest.response.add(chunk);
        sink.add(chunk);
      }

      await sink.flush();
      await sink.close();

      // If full file downloaded, promote from .tmp to final cache
      if (streamedResponse.statusCode == HttpStatus.ok) {
        if (targetCacheFile.existsSync()) targetCacheFile.deleteSync();
        tempFile.renameSync(targetCacheFile.path);
      }

      await clientRequest.response.close();
    } catch (_) {
      try {
        clientRequest.response.statusCode = HttpStatus.badGateway;
        await clientRequest.response.close();
      } catch (_) {}
    }
  }
}
