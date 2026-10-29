import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/models/unified_track.dart';
import '../../core/models/unified_artist.dart';
import '../../core/models/audio_stream_descriptor.dart';
import '../music_provider.dart';

class SoundCloudClient {
  static const String apiBase = 'https://api-v2.soundcloud.com';
  final http.Client _client = http.Client();

  String? _cachedClientId;
  DateTime? _clientIdExpiresAt;

  Future<String> getClientId() async {
    if (_cachedClientId != null &&
        _clientIdExpiresAt != null &&
        DateTime.now().isBefore(_clientIdExpiresAt!)) {
      return _cachedClientId!;
    }

    try {
      final homeResp = await _client.get(
        Uri.parse('https://soundcloud.com'),
        headers: {'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36'},
      );

      final scriptMatches = RegExp(r'<script[^>]+src="([^">]+\.js)"').allMatches(homeResp.body);
      final scriptUrls = scriptMatches.map((m) => m.group(1)!).toList().reversed;

      for (final sUrl in scriptUrls) {
        try {
          final jsResp = await _client.get(
            Uri.parse(sUrl),
            headers: {'User-Agent': 'Mozilla/5.0'},
          ).timeout(const Duration(seconds: 4));

          final match = RegExp(r'client_id[:=]\s*["\']([a-zA-Z0-9]{32})["\']').firstMatch(jsResp.body);
          if (match != null) {
            _cachedClientId = match.group(1);
            _clientIdExpiresAt = DateTime.now().add(const Duration(hours: 6));
            return _cachedClientId!;
          }
        } catch (_) {}
      }
    } catch (_) {}

    // Fallback to latest known client_id if scraping is blocked
    return _cachedClientId ?? 'ZeISTkUY1Q4so1FsHJKZaJo898iWk0d3';
  }

  Future<SearchResultPage> search(String query, {int limit = 20}) async {
    final clientId = await getClientId();
    final uri = Uri.parse('$apiBase/search/tracks?q=${Uri.encodeComponent(query)}&client_id=$clientId&limit=$limit');

    try {
      final resp = await _client.get(uri);
      if (resp.statusCode != 200) return const SearchResultPage();

      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final collection = data['collection'] as List<dynamic>? ?? [];

      final tracks = <UnifiedTrack>[];
      for (final item in collection) {
        if (item is! Map<String, dynamic>) continue;
        final id = item['id']?.toString() ?? '';
        final title = item['title'] as String? ?? 'Untitled';
        final durationMs = (item['duration'] as num?)?.toInt() ?? 0;
        final artworkUrl = item['artwork_url'] as String? ??
            item['user']?['avatar_url'] as String? ??
            '';
        final highResArtwork = artworkUrl.isNotEmpty
            ? artworkUrl.replaceAll('large.jpg', 't500x500.jpg')
            : '';

        final user = item['user'] as Map<String, dynamic>? ?? {};
        final artist = UnifiedArtist(
          id: user['id']?.toString() ?? '',
          name: user['username'] as String? ?? 'SoundCloud Artist',
          thumbnailUrl: user['avatar_url'] as String?,
          isVerified: user['verified'] as bool? ?? false,
        );

        tracks.add(UnifiedTrack(
          id: 'sc:$id',
          source: TrackSource.soundcloud,
          sourceId: id,
          title: title,
          artists: [artist],
          durationMs: durationMs,
          thumbnailUrl: artworkUrl,
          highResThumbnailUrl: highResArtwork,
        ));
      }

      return SearchResultPage(tracks: tracks);
    } catch (_) {
      return const SearchResultPage();
    }
  }

  Future<AudioStreamDescriptor?> resolveStream(String trackId) async {
    final clientId = await getClientId();
    final cleanId = trackId.replaceFirst('sc:', '');
    final uri = Uri.parse('$apiBase/tracks/$cleanId?client_id=$clientId');

    try {
      final resp = await _client.get(uri);
      if (resp.statusCode != 200) return null;

      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final media = data['media'] as Map<String, dynamic>?;
      final transcodings = media?['transcodings'] as List<dynamic>? ?? [];

      // Prefer progressive mp3 first, then HLS opus/mp3
      String? streamAuthUrl;
      bool isHls = false;
      AudioCodec codec = AudioCodec.mp3;
      int bitrate = 128;

      for (final t in transcodings) {
        if (t is! Map<String, dynamic>) continue;
        final format = t['format'] as Map<String, dynamic>? ?? {};
        final protocol = format['protocol'] as String? ?? '';
        final mimeType = format['mime_type'] as String? ?? '';
        final url = t['url'] as String? ?? '';

        if (protocol == 'progressive' && mimeType.contains('audio/mpeg')) {
          streamAuthUrl = url;
          isHls = false;
          codec = AudioCodec.mp3;
          bitrate = 128;
          break;
        } else if (protocol == 'hls' && mimeType.contains('opus') && streamAuthUrl == null) {
          streamAuthUrl = url;
          isHls = true;
          codec = AudioCodec.opus;
          bitrate = 160;
        }
      }

      if (streamAuthUrl == null) return null;

      // Exchange transcoding URL for the actual streaming URL
      final authResp = await _client.get(Uri.parse('$streamAuthUrl?client_id=$clientId'));
      if (authResp.statusCode != 200) return null;

      final authData = jsonDecode(authResp.body) as Map<String, dynamic>;
      final directStreamUrl = authData['url'] as String?;

      if (directStreamUrl == null) return null;

      return AudioStreamDescriptor(
        streamUrl: directStreamUrl,
        codec: codec,
        bitrateKbps: bitrate,
        isHls: isHls,
      );
    } catch (_) {
      return null;
    }
  }
}