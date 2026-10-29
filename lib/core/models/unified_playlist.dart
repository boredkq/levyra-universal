import 'unified_track.dart';

class UnifiedPlaylist {
  final String id;
  final String title;
  final String? description;
  final String? coverUrl;
  final List<UnifiedTrack> tracks;
  final bool isPinned;
  final DateTime createdAt;

  const UnifiedPlaylist({
    required this.id,
    required this.title,
    this.description,
    this.coverUrl,
    this.tracks = const [],
    this.isPinned = false,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'coverUrl': coverUrl,
    'tracks': tracks.map((t) => t.toJson()).toList(),
    'isPinned': isPinned,
    'createdAt': createdAt.toIso8601String(),
  };

  factory UnifiedPlaylist.fromJson(Map<String, dynamic> json) => UnifiedPlaylist(
    id: json['id'] as String,
    title: json['title'] as String,
    description: json['description'] as String?,
    coverUrl: json['coverUrl'] as String?,
    tracks: (json['tracks'] as List<dynamic>?)
            ?.map((e) => UnifiedTrack.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const [],
    isPinned: json['isPinned'] as bool? ?? false,
    createdAt: DateTime.parse(json['createdAt'] as String),
  );
}
