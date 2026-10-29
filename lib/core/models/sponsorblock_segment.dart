enum SponsorBlockCategory {
  sponsor,
  intro,
  outro,
  interaction,
  musicOfftopic,
}

class SponsorBlockSegment {
  final String videoId;
  final SponsorBlockCategory category;
  final int startMs;
  final int endMs;

  const SponsorBlockSegment({
    required this.videoId,
    required this.category,
    required this.startMs,
    required this.endMs,
  });

  bool contains(int currentMs) => currentMs >= startMs && currentMs < endMs;

  Map<String, dynamic> toJson() => {
    'videoId': videoId,
    'category': category.name,
    'startMs': startMs,
    'endMs': endMs,
  };

  factory SponsorBlockSegment.fromJson(Map<String, dynamic> json) => SponsorBlockSegment(
    videoId: json['videoId'] as String,
    category: SponsorBlockCategory.values.byName(json['category'] as String),
    startMs: json['startMs'] as int,
    endMs: json['endMs'] as int,
  );
}
