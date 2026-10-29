import '../core/models/unified_track.dart';
import '../core/models/unified_artist.dart';
import '../core/models/unified_album.dart';
import '../core/models/unified_playlist.dart';
import '../core/models/audio_stream_descriptor.dart';
import '../core/models/synced_lyrics.dart';

class SearchResultPage {
  final List<UnifiedTrack> tracks;
  final List<UnifiedArtist> artists;
  final List<UnifiedAlbum> albums;
  final List<UnifiedPlaylist> playlists;

  const SearchResultPage({
    this.tracks = const [],
    this.artists = const [],
    this.albums = const [],
    this.playlists = const [],
  });
}

class HomeFeed {
  final List<UnifiedTrack> personalOrbit;     // «Твоя орбита» / Моя волна
  final List<UnifiedTrack> discoveryForYou;  // «Открытие для вас»
  final List<UnifiedTrack> charts;           // «Чарты» Топ-50/100
  final List<UnifiedTrack> newPremieres;     // «Премьеры треков»
  final List<UnifiedTrack> secretStash;      // «Тайник» (забытые любимые)
  final UnifiedPlaylist? playlistOfTheDay;   // «Плейлист дня»

  const HomeFeed({
    this.personalOrbit = const [],
    this.discoveryForYou = const [],
    this.charts = const [],
    this.newPremieres = const [],
    this.secretStash = const [],
    this.playlistOfTheDay,
  });
}

class ArtistDetails {
  final UnifiedArtist artist;
  final List<UnifiedTrack> topTracks;
  final List<UnifiedAlbum> albums;
  final List<UnifiedAlbum> singlesAndEps;
  final List<UnifiedAlbum> compilations;
  final List<UnifiedPlaylist> featuredPlaylists;
  final List<UnifiedArtist> similarArtists;

  const ArtistDetails({
    required this.artist,
    this.topTracks = const [],
    this.albums = const [],
    this.singlesAndEps = const [],
    this.compilations = const [],
    this.featuredPlaylists = const [],
    this.similarArtists = const [],
  });
}

class TrackComment {
  final String authorName;
  final String? authorAvatarUrl;
  final String text;
  final int likeCount;
  final String publishedTime;

  const TrackComment({
    required this.authorName,
    this.authorAvatarUrl,
    required this.text,
    this.likeCount = 0,
    required this.publishedTime,
  });
}

abstract interface class MusicProvider {
  TrackSource get source;

  Future<SearchResultPage> search(String query, {int page = 0});
  Future<AudioStreamDescriptor> getStreamDescriptor(String trackId);
  Future<String?> getVideoStreamUrl(String videoId);
  Future<SyncedLyrics?> getLyrics(String trackId);
  Future<ArtistDetails> getArtistDetails(String artistId);
  Future<HomeFeed> getHomeFeed();
  Future<List<TrackComment>> getComments(String trackId);
  Future<String?> getMotionArtworkUrl(String trackId);
}
