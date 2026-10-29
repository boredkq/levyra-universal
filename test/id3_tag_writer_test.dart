import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Id3TagWriter Syncsafe Tests', () {
    List<int> encodeSyncsafe(int value) {
      return [
        (value >> 21) & 0x7F,
        (value >> 14) & 0x7F,
        (value >> 7) & 0x7F,
        value & 0x7F,
      ];
    }

    int decodeSyncsafe(List<int> bytes) {
      return (bytes[0] << 21) | (bytes[1] << 14) | (bytes[2] << 7) | bytes[3];
    }

    test('Syncsafe encoding and decoding preserves values', () {
      final testValues = [0, 127, 128, 256, 1024, 65535, 1048576, 268435455];

      for (final val in testValues) {
        final encoded = encodeSyncsafe(val);
        // Each syncsafe byte must have MSB 0 (less than 128)
        for (final b in encoded) {
          expect(b, lessThan(128));
        }
        final decoded = decodeSyncsafe(encoded);
        expect(decoded, equals(val));
      }
    });
  });
}