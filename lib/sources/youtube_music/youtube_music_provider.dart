import '../../core/models/unified_track.dart';
import '../../core/models/unified_artist.dart';
import '../../core/models/audio_stream_descriptor.dart';
import '../../core/models/synced_lyrics.dart';
import '../music_provider.dart';
import 'innertube_client.dart';

class YouTubeMusicProvider implements MusicProvider {
  final InnertubeClient _client;

  YouTubeMusicProvider([InnertubeClient? client])
      : _client = client ?? InnertubeClient();

  @override
  TrackSource get source => TrackSource.youtubeMusic;

  @override
  Future<SearchResultPage> search(String query, {int page = 0}) {
    return _client.search(query);
  }

  @override
  Future<AudioStreamDescriptor> getStreamDescriptor(String trackId) async {
    final videoId = trackId.replaceFirst('ytm:', '');
    final stream = await _client.resolveStream(videoId);
    if (stream == null) {
      throw Exception('Failed to resolve YouTube Music audio stream for $videoId');
    }
    return stream;
  }

  @override
  Future<String?> getVideoStreamUrl(String videoId) async {
    // Returns video stream for YouTube clip playback mode
    final stream = await _client.resolveVideoStream(videoId);
    return stream?.streamUrl;
  }

  @override
  Future<SyncedLyrics?> getLyrics(String trackId) async {
    // Return sample synced karaoke lyrics
    return SyncedLyrics(
      trackId: trackId,
      isWordSynced: true,
      lines: [
        LyricLine(startMs: 0, text: '♪ Музыкальное вступление ♪'),
        LyricLine(startMs: 4000, text: 'Первая строчка песни звучит здесь'),
        LyricLine(startMs: 8500, text: 'И караоке плавно заполняет текст'),
        LyricLine(startMs: 13000, text: 'Переход к припеву трека...'),
      ],
    );
  }

  @override
  Future<ArtistDetails> getArtistDetails(String artistId) async {
    return ArtistDetails(
      artist: UnifiedArtist(id: artistId, name: 'YouTube Артист'),
    );
  }

  @override
  Future<HomeFeed> getHomeFeed() async {
    return const HomeFeed();
  }

  @override
  Future<List<TrackComment>> getComments(String trackId) {
    final videoId = trackId.replaceFirst('ytm:', '');
    return _client.getComments(videoId);
  }

  @override
  Future<String?> getMotionArtworkUrl(String trackId) async {
    return null;
  }
}
