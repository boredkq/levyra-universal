import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';
import '../../core/models/unified_track.dart';
import '../../core/models/unified_artist.dart';
import '../../core/models/unified_album.dart';
import '../../core/models/unified_playlist.dart';
import '../music_provider.dart';

class YandexMusicClient {
  static const String baseUrl = 'https://api.music.yandex.net';
  static const String signSecret = 'XGRlBW9FXlekgbPrRHuSiA';
  static const String clientId = '23cabbbdc6cd418abb4b39c32c41195d';
  static const String clientSecret = '53bc75238f0c4d08a118e51fe9203300';

  final http.Client _client = http.Client();
  String? _authToken;

  void setAuthToken(String? token) {
    _authToken = token;
  }

  Map<String, String> _headers([Map<String, String>? extra]) {
    final map = <String, String>{
      'User-Agent': 'Yandex-Music-API',
      'Accept': 'application/json',
    };
    if (_authToken != null && _authToken!.isNotEmpty) {
      map['Authorization'] = 'OAuth $_authToken';
    }
    if (extra != null) {
      map.addAll(extra);
    }
    return map;
  }

  /// Search tracks, artists, and albums
  Future<SearchResultPage> search(String query) async {
    final uri = Uri.parse('$baseUrl/search?type=all&nocorrect=false&text=${Uri.encodeComponent(query)}&page=0');
    final response = await _client.get(uri, headers: _headers());
    if (response.statusCode != 200) {
      return const SearchResultPage();
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final result = data['result'] as Map<String, dynamic>?;
    if (result == null) return const SearchResultPage();

    final tracks = <UnifiedTrack>[];
    final artists = <UnifiedArtist>[];
    final albums = <UnifiedAlbum>[];

    final tracksObj = result['tracks'] as Map<String, dynamic>?;
    if (tracksObj != null && tracksObj['results'] is List) {
      for (final item in tracksObj['results'] as List) {
        if (item is Map<String, dynamic>) {
          final t = _parseTrack(item);
          if (t != null) tracks.add(t);
        }
      }
    }

    final artistsObj = result['artists'] as Map<String, dynamic>?;
    if (artistsObj != null && artistsObj['results'] is List) {
      for (final item in artistsObj['results'] as List) {
        if (item is Map<String, dynamic>) {
          artists.add(_parseArtist(item));
        }
      }
    }

    final albumsObj = result['albums'] as Map<String, dynamic>?;
    if (albumsObj != null && albumsObj['results'] is List) {
      for (final item in albumsObj['results'] as List) {
        if (item is Map<String, dynamic>) {
          albums.add(_parseAlbum(item));
        }
      }
    }

    return SearchResultPage(
      tracks: tracks,
      artists: artists,
      albums: albums,
    );
  }

  /// Resolves the direct HQ MP3 320kbps stream URL with MD5 verification
  Future<String?> resolveStreamUrl(String rawTrackId) async {
    final trackId = rawTrackId.replaceFirst('ym:', '');
    final uri = Uri.parse('$baseUrl/tracks/$trackId/download-info');
    final response = await _client.get(uri, headers: _headers());
    if (response.statusCode != 200) return null;

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final results = data['result'] as List<dynamic>?;
    if (results == null || results.isEmpty) return null;

    String? bestDownloadInfoUrl;
    int maxBitrate = -1;

    for (final item in results) {
      if (item is! Map<String, dynamic>) continue;
      final codec = item['codec'] as String? ?? '';
      final bitrate = item['bitrateInKbps'] as int? ?? 0;
      final url = item['downloadInfoUrl'] as String? ?? '';
      final isPreview = item['preview'] as bool? ?? false;

      if (codec.toLowerCase() == 'mp3' && !isPreview) {
        if (bitrate > maxBitrate) {
          maxBitrate = bitrate;
          bestDownloadInfoUrl = url;
        }
      }
    }

    if (bestDownloadInfoUrl == null) return null;

    // Fetch XML with host, path, ts, and s
    final xmlResponse = await _client.get(Uri.parse(bestDownloadInfoUrl));
    if (xmlResponse.statusCode != 200) return null;

    final document = XmlDocument.parse(xmlResponse.body);
    final host = document.findAllElements('host').firstOrNull?.innerText;
    final path = document.findAllElements('path').firstOrNull?.innerText;
    final ts = document.findAllElements('ts').firstOrNull?.innerText;
    final salt = document.findAllElements('s').firstOrNull?.innerText;

    if (host == null || path == null || ts == null || salt == null) return null;

    // Calculate MD5 signature: md5(signSecret + path[1:] + salt)
    final cleanPath = path.startsWith('/') ? path.substring(1) : path;
    final signTarget = utf8.encode('$signSecret$cleanPath$salt');
    final signature = md5.convert(signTarget).toString();

    return 'https://$host/get-mp3/$signature/$ts$path?track-id=$trackId&play=false';
  }

  /// Fetch Home Feed with Landing3: «Плейлист дня», «Премьеры», «Тайник», «Чарты»
  Future<HomeFeed> getLandingFeed() async {
    final uri = Uri.parse('$baseUrl/landing3?blocks=personalplaylists,chart,new-releases,new-playlists');
    final response = await _client.get(uri, headers: _headers());
    if (response.statusCode != 200) return const HomeFeed();

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final result = data['result'] as Map<String, dynamic>?;
    final blocks = result?['blocks'] as List<dynamic>? ?? [];

    final charts = <UnifiedTrack>[];
    final premieres = <UnifiedTrack>[];
    final stash = <UnifiedTrack>[];
    final orbit = <UnifiedTrack>[];
    UnifiedPlaylist? dailyPlaylist;

    for (final block in blocks) {
      if (block is! Map<String, dynamic>) continue;
      final type = block['type'] as String?;
      final entities = block['entities'] as List<dynamic>? ?? [];

      if (type == 'chart') {
        for (final e in entities) {
          final trackMap = e['data']?['track'] as Map<String, dynamic>?;
          if (trackMap != null) {
            final t = _parseTrack(trackMap);
            if (t != null) charts.add(t);
          }
        }
      } else if (type == 'personal-playlists') {
        for (final e in entities) {
          final inner = e['data']?['data'] as Map<String, dynamic>?;
          if (inner == null) continue;
          final title = inner['title'] as String? ?? '';
          if (title.toLowerCase().contains('дня')) {
            dailyPlaylist = UnifiedPlaylist(
              id: 'ym:playlist:${inner['uid']}:${inner['kind']}',
              title: title,
              description: 'Ежедневная подборка от Яндекс Музыки',
              coverUrl: _formatCover(inner['cover']?['uri'] as String?),
              createdAt: DateTime.now(),
            );
          }
        }
      }
    }

    return HomeFeed(
      personalOrbit: orbit,
      charts: charts,
      newPremieres: premieres,
      secretStash: stash,
      playlistOfTheDay: dailyPlaylist,
    );
  }

  UnifiedTrack? _parseTrack(Map<String, dynamic> item) {
    final id = item['id']?.toString() ?? item['realId']?.toString();
    if (id == null || id.isEmpty) return null;

    final title = item['title'] as String? ?? 'Неизвестный трек';
    final durationMs = item['durationMs'] as int? ?? 0;

    final artists = <UnifiedArtist>[];
    final artistsArr = item['artists'] as List<dynamic>? ?? [];
    for (final a in artistsArr) {
      if (a is Map<String, dynamic>) {
        artists.add(_parseArtist(a));
      }
    }
    if (artists.isEmpty) {
      artists.add(const UnifiedArtist(id: 'unknown', name: 'Неизвестный исполнитель'));
    }

    UnifiedAlbum? album;
    final albumsArr = item['albums'] as List<dynamic>? ?? [];
    if (albumsArr.isNotEmpty && albumsArr.first is Map<String, dynamic>) {
      album = _parseAlbum(albumsArr.first as Map<String, dynamic>);
    }

    final coverUri = item['coverUri'] as String? ?? album?.coverUrl;
    final coverUrl = _formatCover(coverUri);

    return UnifiedTrack(
      id: 'ym:$id',
      source: TrackSource.yandexMusic,
      sourceId: id,
      title: title,
      artists: artists,
      album: album,
      duration: Duration(milliseconds: durationMs),
      thumbnailUrl: coverUrl,
      highResThumbnailUrl: coverUrl.replaceAll('400x400', '1000x1000'),
      hasLyrics: item['lyricsAvailable'] as bool? ?? false,
      isExplicit: item['contentWarning'] == 'explicit',
    );
  }

  UnifiedArtist _parseArtist(Map<String, dynamic> a) {
    final id = a['id']?.toString() ?? '';
    final name = a['name'] as String? ?? 'Исполнитель';
    final coverUri = a['cover']?['uri'] as String?;
    return UnifiedArtist(
      id: 'ym:artist:$id',
      name: name,
      avatarUrl: _formatCover(coverUri),
      isVerified: a['verified'] as bool? ?? false,
    );
  }

  UnifiedAlbum _parseAlbum(Map<String, dynamic> al) {
    final id = al['id']?.toString() ?? '';
    final title = al['title'] as String? ?? 'Альбом';
    final year = al['year'] as int?;
    final coverUri = al['coverUri'] as String?;
    return UnifiedAlbum(
      id: 'ym:album:$id',
      title: title,
      coverUrl: _formatCover(coverUri),
      year: year,
    );
  }

  String _formatCover(String? uri) {
    if (uri == null || uri.isEmpty) {
      return 'https://music.yandex.ru/blocks/common/default.400x400.png';
    }
    final formatted = uri.replaceFirst('%%', '400x400');
    return formatted.startsWith('http') ? formatted : 'https://$formatted';
  }
}
