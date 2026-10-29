import '../../core/models/unified_track.dart';
import '../../core/models/unified_artist.dart';
import '../../core/models/audio_stream_descriptor.dart';
import '../../core/models/synced_lyrics.dart';
import '../music_provider.dart';
import 'yandex_music_client.dart';

class YandexMusicProvider implements MusicProvider {
  final YandexMusicClient _client;

  YandexMusicProvider([YandexMusicClient? client])
      : _client = client ?? YandexMusicClient();

  @override
  TrackSource get source => TrackSource.yandexMusic;

  @override
  Future<SearchResultPage> search(String query, {int page = 0}) {
    return _client.search(query);
  }

  @override
  Future<AudioStreamDescriptor> getStreamDescriptor(String trackId) async {
    final url = await _client.resolveStreamUrl(trackId);
    if (url == null) {
      throw Exception('Failed to resolve Yandex Music stream URL for $trackId');
    }
    return AudioStreamDescriptor(
      streamUrl: url,
      codec: AudioCodec.mp3,
      bitrateKbps: 320,
      httpHeaders: const {
        'User-Agent': 'Yandex-Music-API',
      },
    );
  }

  @override
  Future<String?> getVideoStreamUrl(String videoId) async {
    // Yandex Music does not host music videos directly; video mode delegates to YouTube
    return null;
  }

  @override
  Future<SyncedLyrics?> getLyrics(String trackId) async {
    // Lyrics resolution handled via Yandex lyrics or fallback to LRCLIB
    return null;
  }

  @override
  Future<ArtistDetails> getArtistDetails(String artistId) async {
    return ArtistDetails(
      artist: UnifiedArtist(id: artistId, name: 'Исполнитель'),
    );
  }

  @override
  Future<HomeFeed> getHomeFeed() {
    return _client.getLandingFeed();
  }

  @override
  Future<List<TrackComment>> getComments(String trackId) async {
    return const [];
  }

  @override
  Future<String?> getMotionArtworkUrl(String trackId) async {
    return null;
  }
}
