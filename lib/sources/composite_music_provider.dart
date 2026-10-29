import '../core/models/unified_track.dart';
import '../core/models/audio_stream_descriptor.dart';
import '../core/models/synced_lyrics.dart';
import 'music_provider.dart';
import 'youtube_music/youtube_music_provider.dart';
import 'yandex_music/yandex_music_provider.dart';
import 'soundcloud/soundcloud_provider.dart';

class CompositeMusicProvider implements MusicProvider {
  final Map<TrackSource, MusicProvider> _providers;

  CompositeMusicProvider({
    YouTubeMusicProvider? ytProvider,
    YandexMusicProvider? ymProvider,
    SoundCloudMusicProvider? scProvider,
  }) : _providers = {
          TrackSource.youtubeMusic: ytProvider ?? YouTubeMusicProvider(),
          TrackSource.yandexMusic: ymProvider ?? YandexMusicProvider(),
          TrackSource.soundcloud: scProvider ?? SoundCloudMusicProvider(),
        };

  @override
  TrackSource get source => TrackSource.youtubeMusic;

  MusicProvider _providerFor(String trackId) {
    if (trackId.startsWith('ym:')) {
      return _providers[TrackSource.yandexMusic]!;
    } else if (trackId.startsWith('sc:')) {
      return _providers[TrackSource.soundcloud]!;
    }
    return _providers[TrackSource.youtubeMusic]!;
  }

  @override
  Future<SearchResultPage> search(String query, {int page = 0, TrackSource? filterSource}) async {
    if (filterSource != null && _providers.containsKey(filterSource)) {
      return _providers[filterSource]!.search(query, page: page);
    }

    // Parallel multi-source search across all active providers
    final futures = _providers.values.map((p) => p.search(query, page: page).catchError((_) => const SearchResultPage()));
    final results = await Future.wait(futures);

    final mergedTracks = <UnifiedTrack>[];
    final mergedArtists = <UnifiedArtist>[];
    final mergedAlbums = <UnifiedAlbum>[];
    final mergedPlaylists = <UnifiedPlaylist>[];

    for (final res in results) {
      mergedTracks.addAll(res.tracks);
      mergedArtists.addAll(res.artists);
      mergedAlbums.addAll(res.albums);
      mergedPlaylists.addAll(res.playlists);
    }

    return SearchResultPage(
      tracks: mergedTracks,
      artists: mergedArtists,
      albums: mergedAlbums,
      playlists: mergedPlaylists,
    );
  }

  @override
  Future<AudioStreamDescriptor> getStreamDescriptor(String trackId) {
    return _providerFor(trackId).getStreamDescriptor(trackId);
  }

  @override
  Future<String?> getVideoStreamUrl(String videoId) {
    return _providers[TrackSource.youtubeMusic]!.getVideoStreamUrl(videoId);
  }

  @override
  Future<SyncedLyrics?> getLyrics(String trackId) {
    return _providerFor(trackId).getLyrics(trackId);
  }

  @override
  Future<ArtistDetails> getArtistDetails(String artistId) {
    return _providerFor(artistId).getArtistDetails(artistId);
  }

  @override
  Future<HomeFeed> getHomeFeed() async {
    // Merge personal feed from Yandex (Orbit, Landing3) and YouTube
    final ymFeed = await _providers[TrackSource.yandexMusic]?.getHomeFeed() ?? const HomeFeed();
    return ymFeed;
  }

  @override
  Future<List<TrackComment>> getComments(String trackId) {
    return _providers[TrackSource.youtubeMusic]!.getComments(trackId);
  }

  @override
  Future<String?> getMotionArtworkUrl(String trackId) {
    return _providerFor(trackId).getMotionArtworkUrl(trackId);
  }
}
