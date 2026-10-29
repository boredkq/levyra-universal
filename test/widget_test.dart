import 'package:flutter_test/flutter_test.dart';
import 'package:levyra_music/core/models/unified_track.dart';
import 'package:levyra_music/core/models/unified_artist.dart';

void main() {
  test('Levyra Music Smoke Test', () {
    const artist = UnifiedArtist(id: 'art_1', name: 'Levyra Audiophile');
    const track = UnifiedTrack(
      id: 'ytm:test_smoke_123',
      source: 'youtube_music',
      sourceId: 'test_smoke_123',
      title: 'Smoke Test Track',
      artists: [artist],
      durationMs: 240000,
      thumbnailUrl: 'https://example.com/thumb.jpg',
    );

    expect(track.id, equals('ytm:test_smoke_123'));
    expect(track.artists.first.name, equals('Levyra Audiophile'));
    expect(track.isExplicit, isFalse);
    expect(track.durationMs, equals(240000));
  });
}
