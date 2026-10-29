import '../../core/models/unified_track.dart';
import '../../core/models/unified_artist.dart';
import '../../core/models/audio_stream_descriptor.dart';
import '../../core/models/synced_lyrics.dart';
import '../music_provider.dart';
import 'soundcloud_client.dart';

class SoundCloudMusicProvider implements MusicProvider {
  final SoundCloudClient _client;

  SoundCloudMusicProvider([SoundCloudClient? client])
      : _client = client ?? SoundCloudClient();

  @override
  TrackSource get source => TrackSource.soundcloud;

  @override
  Future<SearchResultPage> search(String query, {int page = 0}) {
    return _client.search(query);
  }

  @override
  Future<AudioStreamDescriptor> getStreamDescriptor(String trackId) async {
    final descriptor = await _client.resolveStream(trackId);
    if (descriptor == null) {
      throw Exception('Failed to resolve SoundCloud audio stream for $trackId');
    }
    return descriptor;
  }

  @override
  Future<String?> getVideoStreamUrl(String videoId) async => null;

  @override
  Future<SyncedLyrics?> getLyrics(String trackId) async => null;

  @override
  Future<ArtistDetails> getArtistDetails(String artistId) async {
    return ArtistDetails(
      artist: UnifiedArtist(id: artistId, name: 'SoundCloud Creator'),
    );
  }

  @override
  Future<HomeFeed> getHomeFeed() async => const HomeFeed();

  @override
  Future<List<TrackComment>> getComments(String trackId) async => const [];

  @override
  Future<String?> getMotionArtworkUrl(String trackId) async => null;
}