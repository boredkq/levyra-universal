import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../core/models/unified_track.dart';

/// Pure Dart ID3v2.4 Tag Writer.
/// Writes standard ID3v2.4 frames:
/// - TIT2: Track Title
/// - TPE1: Lead Artist / Performer
/// - TALB: Album Title
/// - TLEN: Length in milliseconds
/// - APIC: Attached Picture (Front Cover, JPEG/PNG)
class Id3TagWriter {
  static const List<int> id3HeaderMagic = [0x49, 0x44, 0x33]; // 'ID3'
  static final http.Client _client = http.Client();

  /// Prepends an ID3v2.4 tag header and frames to an audio file
  static Future<void> writeTags(File audioFile, UnifiedTrack track) async {
    final frameBytes = <int>[];

    // 1. Title (TIT2)
    frameBytes.addAll(_buildTextFrame('TIT2', track.title));

    // 2. Artist (TPE1)
    frameBytes.addAll(_buildTextFrame('TPE1', track.artistNames));

    // 3. Album (TALB)
    if (track.albumTitle != null && track.albumTitle!.isNotEmpty) {
      frameBytes.addAll(_buildTextFrame('TALB', track.albumTitle!));
    }

    // 4. Duration (TLEN)
    if (track.durationMs > 0) {
      frameBytes.addAll(_buildTextFrame('TLEN', track.durationMs.toString()));
    }

    // 5. Cover Artwork (APIC)
    final coverUrl = track.highResThumbnailUrl ?? track.thumbnailUrl;
    if (coverUrl.isNotEmpty) {
      try {
        final resp = await _client.get(Uri.parse(coverUrl)).timeout(const Duration(seconds: 4));
        if (resp.statusCode == 200 && resp.bodyBytes.isNotEmpty) {
          frameBytes.addAll(_buildPictureFrame(resp.bodyBytes));
        }
      } catch (_) {}
    }

    // Build ID3v2.4 Header (10 bytes)
    final tagSize = frameBytes.length;
    final header = <int>[
      ...id3HeaderMagic,
      0x04, // Version 2.4
      0x00, // Revision
      0x00, // Flags
      ..._encodeSyncsafe(tagSize), // 4 syncsafe bytes
    ];

    final fullTag = Uint8List.fromList([...header, ...frameBytes]);

    // Read original audio content
    final audioBytes = await audioFile.readAsBytes();

    // Check if existing ID3 tag exists to replace or strip
    int audioStartOffset = 0;
    if (audioBytes.length > 10 &&
        audioBytes[0] == 0x49 &&
        audioBytes[1] == 0x44 &&
        audioBytes[2] == 0x33) {
      final existingSize = _decodeSyncsafe(audioBytes.sublist(6, 10));
      audioStartOffset = 10 + existingSize;
    }

    final outputBytes = BytesBuilder();
    outputBytes.add(fullTag);
    outputBytes.add(audioBytes.sublist(audioStartOffset));

    await audioFile.writeAsBytes(outputBytes.toBytes());
  }

  static List<int> _buildTextFrame(String frameId, String text) {
    final textBytes = utf8.encode(text);
    // Encoding byte 0x03 = UTF-8
    final content = [0x03, ...textBytes];
    return _buildFrame(frameId, content);
  }

  static List<int> _buildPictureFrame(List<int> imageBytes) {
    final mimeBytes = utf8.encode('image/jpeg');
    final content = <int>[
      0x03, // UTF-8 description encoding
      ...mimeBytes,
      0x00, // Null terminator for MIME
      0x03, // Picture type: Cover (front)
      0x00, // Description null terminator
      ...imageBytes,
    ];
    return _buildFrame('APIC', content);
  }

  static List<int> _buildFrame(String frameId, List<int> content) {
    final idBytes = ascii.encode(frameId);
    final sizeBytes = _encodeSyncsafe(content.length);
    const flags = [0x00, 0x00];
    return [...idBytes, ...sizeBytes, ...flags, ...content];
  }

  static List<int> _encodeSyncsafe(int value) {
    return [
      (value >> 21) & 0x7F,
      (value >> 14) & 0x7F,
      (value >> 7) & 0x7F,
      value & 0x7F,
    ];
  }

  static int _decodeSyncsafe(List<int> bytes) {
    return (bytes[0] << 21) | (bytes[1] << 14) | (bytes[2] << 7) | bytes[3];
  }
}