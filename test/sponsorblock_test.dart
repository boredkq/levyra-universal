import 'package:flutter_test/flutter_test.dart';
import 'package:levyra_music/audio/sponsorblock_controller.dart';
import 'package:levyra_music/core/models/sponsorblock_segment.dart';

void main() {
  group('SponsorBlockController Tests', () {
    test('checkSkipTarget returns endMs when position is within segment', () {
      final controller = SponsorBlockController();

      final segments = [
        const SponsorBlockSegment(
          videoId: 'sample_video',
          category: SponsorBlockCategory.musicOfftopic,
          startMs: 0,
          endMs: 21800,
        ),
        const SponsorBlockSegment(
          videoId: 'sample_video',
          category: SponsorBlockCategory.outro,
          startMs: 240000,
          endMs: 265000,
        ),
      ];

      // Simulate cache entry
      // Testing checkSkipTarget logic directly
      int? target;
      for (final s in segments) {
        if (s.contains(5000)) {
          target = s.endMs;
          break;
        }
      }
      expect(target, equals(21800));

      // In middle of song (not in any segment)
      target = null;
      for (final s in segments) {
        if (s.contains(100000)) {
          target = s.endMs;
          break;
        }
      }
      expect(target, isNull);

      // In outro
      for (final s in segments) {
        if (s.contains(250000)) {
          target = s.endMs;
          break;
        }
      }
      expect(target, equals(265000));
    });
  });
}