import 'unified_artist.dart';

class UnifiedAlbum {
  final String id;
  final String title;
  final List<UnifiedArtist> artists;
  final String? coverUrl;
  final int? year;
  final int? trackCount;

  const UnifiedAlbum({
    required this.id,
    required this.title,
    this.artists = const [],
    this.coverUrl,
    this.year,
    this.trackCount,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'artists': artists.map((a) => a.toJson()).toList(),
    'coverUrl': coverUrl,
    'year': year,
    'trackCount': trackCount,
  };

  factory UnifiedAlbum.fromJson(Map<String, dynamic> json) => UnifiedAlbum(
    id: json['id'] as String,
    title: json['title'] as String,
    artists: (json['artists'] as List<dynamic>?)
            ?.map((e) => UnifiedArtist.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const [],
    coverUrl: json['coverUrl'] as String?,
    year: json['year'] as int?,
    trackCount: json['trackCount'] as int?,
  );
}
