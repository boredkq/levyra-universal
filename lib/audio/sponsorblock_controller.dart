import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/models/sponsorblock_segment.dart';

/// Controller for SponsorBlock automated non-music segment skipping.
class SponsorBlockController {
  static const String apiUrl = 'https://sponsor.ajay.app/api/skipSegments';

  final http.Client _client = http.Client();
  final Map<String, List<SponsorBlockSegment>> _cache = {};

  bool isEnabled = true;

  /// Fetch skip segments for a given YouTube video ID
  Future<List<SponsorBlockSegment>> getSegments(String videoId) async {
    if (!isEnabled) return const [];
    if (_cache.containsKey(videoId)) return _cache[videoId]!;

    try {
      final categoriesParam = '["music_offtopic","sponsor","intro","outro","interaction"]';
      final uri = Uri.parse('$apiUrl?videoID=$videoId&categories=${Uri.encodeComponent(categoriesParam)}');

      final response = await _client.get(uri).timeout(const Duration(seconds: 4));
      if (response.statusCode != 200) {
        _cache[videoId] = const [];
        return const [];
      }

      final list = jsonDecode(response.body) as List<dynamic>? ?? [];
      final segments = <SponsorBlockSegment>[];

      for (final item in list) {
        if (item is! Map<String, dynamic>) continue;
        final categoryStr = item['category'] as String? ?? '';
        final segmentRange = item['segment'] as List<dynamic>? ?? [];

        if (segmentRange.length < 2) continue;
        final startMs = ((segmentRange[0] as num).toDouble() * 1000).round();
        final endMs = ((segmentRange[1] as num).toDouble() * 1000).round();

        SponsorBlockCategory category;
        switch (categoryStr) {
          case 'sponsor':
            category = SponsorBlockCategory.sponsor;
            break;
          case 'intro':
            category = SponsorBlockCategory.intro;
            break;
          case 'outro':
            category = SponsorBlockCategory.outro;
            break;
          case 'music_offtopic':
            category = SponsorBlockCategory.musicOfftopic;
            break;
          default:
            category = SponsorBlockCategory.interaction;
        }

        segments.add(SponsorBlockSegment(
          videoId: videoId,
          category: category,
          startMs: startMs,
          endMs: endMs,
        ));
      }

      _cache[videoId] = segments;
      return segments;
    } catch (_) {
      _cache[videoId] = const [];
      return const [];
    }
  }

  /// Checks if current position falls into any skip segment and returns target seek timestamp
  int? checkSkipTarget(String videoId, int currentMs) {
    if (!isEnabled) return null;
    final segments = _cache[videoId];
    if (segments == null || segments.isEmpty) return null;

    for (final seg in segments) {
      if (seg.contains(currentMs)) {
        return seg.endMs;
      }
    }
    return null;
  }
}
