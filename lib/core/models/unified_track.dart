import 'unified_artist.dart';
import 'unified_album.dart';

enum TrackSource {
  youtubeMusic,
  yandexMusic,
  soundcloud,
  local,
}

class UnifiedTrack {
  final String id;
  final TrackSource source;
  final String sourceId;
  final String title;
  final List<UnifiedArtist> artists;
  final UnifiedAlbum? album;
  final Duration duration;
  final String thumbnailUrl;
  final String? highResThumbnailUrl;
  final String? motionArtworkUrl; // Loop video URL for Canvas mode
  final String? videoId;          // YouTube video ID for clip mode
  final bool hasLyrics;
  final bool isExplicit;
  final double replayGainDb;      // ReplayGain target offset in dB

  const UnifiedTrack({
    required this.id,
    required this.source,
    required this.sourceId,
    required this.title,
    required this.artists,
    this.album,
    required this.duration,
    required this.thumbnailUrl,
    this.highResThumbnailUrl,
    this.motionArtworkUrl,
    this.videoId,
    this.hasLyrics = false,
    this.isExplicit = false,
    this.replayGainDb = 0.0,
  });

  String get artistNames => artists.map((a) => a.name).join(', ');

  Map<String, dynamic> toJson() => {
    'id': id,
    'source': source.name,
    'sourceId': sourceId,
    'title': title,
    'artists': artists.map((a) => a.toJson()).toList(),
    'album': album?.toJson(),
    'durationMs': duration.inMilliseconds,
    'thumbnailUrl': thumbnailUrl,
    'highResThumbnailUrl': highResThumbnailUrl,
    'motionArtworkUrl': motionArtworkUrl,
    'videoId': videoId,
    'hasLyrics': hasLyrics,
    'isExplicit': isExplicit,
    'replayGainDb': replayGainDb,
  };

  factory UnifiedTrack.fromJson(Map<String, dynamic> json) => UnifiedTrack(
    id: json['id'] as String,
    source: TrackSource.values.byName(json['source'] as String),
    sourceId: json['sourceId'] as String,
    title: json['title'] as String,
    artists: (json['artists'] as List<dynamic>)
        .map((e) => UnifiedArtist.fromJson(e as Map<String, dynamic>))
        .toList(),
    album: json['album'] != null
        ? UnifiedAlbum.fromJson(json['album'] as Map<String, dynamic>)
        : null,
    duration: Duration(milliseconds: json['durationMs'] as int),
    thumbnailUrl: json['thumbnailUrl'] as String,
    highResThumbnailUrl: json['highResThumbnailUrl'] as String?,
    motionArtworkUrl: json['motionArtworkUrl'] as String?,
    videoId: json['videoId'] as String?,
    hasLyrics: json['hasLyrics'] as bool? ?? false,
    isExplicit: json['isExplicit'] as bool? ?? false,
    replayGainDb: (json['replayGainDb'] as num?)?.toDouble() ?? 0.0,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UnifiedTrack && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
