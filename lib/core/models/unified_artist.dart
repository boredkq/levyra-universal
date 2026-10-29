class UnifiedArtist {
  final String id;
  final String name;
  final String? avatarUrl;
  final bool isVerified;
  final int? subscribersCount;
  final String? bio;

  const UnifiedArtist({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.isVerified = false,
    this.subscribersCount,
    this.bio,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'avatarUrl': avatarUrl,
    'isVerified': isVerified,
    'subscribersCount': subscribersCount,
    'bio': bio,
  };

  factory UnifiedArtist.fromJson(Map<String, dynamic> json) => UnifiedArtist(
    id: json['id'] as String,
    name: json['name'] as String,
    avatarUrl: json['avatarUrl'] as String?,
    isVerified: json['isVerified'] as bool? ?? false,
    subscribersCount: json['subscribersCount'] as int?,
    bio: json['bio'] as String?,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UnifiedArtist && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
