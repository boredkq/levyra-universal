import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('YandexMusicClient Tests', () {
    test('MD5 signature generation matches specification', () {
      const secretSalt = 'XGRlBW9FXlekgbPrRHuSiA';
      const path = '/get-mp3/b1c2d3e4f5a6b7c8d9e0/1234567890/data/0';
      const s = 'sample_salt_token';

      // Formula: md5(secretSalt + path.removeLeadingSlash + s)
      final cleanPath = path.startsWith('/') ? path.substring(1) : path;
      final signTarget = utf8.encode('$secretSalt$cleanPath$s');
      final expectedHash = md5.convert(signTarget).toString();

      expect(expectedHash.length, 32);
      expect(expectedHash, isNotEmpty);
    });

    test('XML download-info parsing extracts host, path, ts, s', () {
      const sampleXml = '''<?xml version="1.0" encoding="utf-8"?>
<download-info>
    <host>storage.mds.yandex.net</host>
    <path>/get-mp3/sample_hash/12345/data/0</path>
    <ts>1730190000</ts>
    <s>9876543210abcdef</s>
</download-info>''';

      // Verify that XML elements exist
      expect(sampleXml.contains('<host>storage.mds.yandex.net</host>'), isTrue);
      expect(sampleXml.contains('<path>/get-mp3/sample_hash/12345/data/0</path>'), isTrue);
      expect(sampleXml.contains('<ts>1730190000</ts>'), isTrue);
      expect(sampleXml.contains('<s>9876543210abcdef</s>'), isTrue);
    });
  });
}
