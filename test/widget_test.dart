import 'package:flutter_test/flutter_test.dart';
import 'package:levyra_music/core/models/unified_track.dart';
import 'package:levyra_music/core/models/unified_artist.dart';

void main() {
  test('Levyra Music Smoke Test', () {
    const artist = UnifiedArtist(id: 'art_1', name: 'Levyra Audiophile');
    final track = UnifiedTrack(
      id: 'ytm:test_smoke_123',
      source: TrackSource.youtubeMusic,
      sourceId: 'test_smoke_123',
      title: 'Smoke Test Track',
      artists: const [artist],
      duration: const Duration(seconds: 240),
      thumbnailUrl: 'https://example.com/thumb.jpg',
    );

    expect(track.id, equals('ytm:test_smoke_123'));
    expect(track.source, equals(TrackSource.youtubeMusic));
    expect(track.artists.first.name, equals('Levyra Audiophile'));
    expect(track.isExplicit, isFalse);
    expect(track.duration.inSeconds, equals(240));
  });
}
