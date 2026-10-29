import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:levyra_music/database/local_database.dart';
import 'package:levyra_music/core/models/unified_track.dart';
import 'package:levyra_music/core/models/unified_artist.dart';

void main() {
  group('LocalDatabase Tests', () {
    late Directory tempDir;
    late LocalDatabase db;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('levyra_db_test_');
      db = LocalDatabase(storageDir: tempDir);
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    final testTrack = UnifiedTrack(
      id: 'ym:12345',
      source: TrackSource.yandexMusic,
      sourceId: '12345',
      title: 'Utopia',
      artists: const [UnifiedArtist(id: '1', name: 'Miyagi')],
      duration: const Duration(minutes: 3, seconds: 45),
      thumbnailUrl: 'https://example.com/cover.jpg',
    );

    test('Toggling favorites persists to storage', () {
      expect(db.isFavorite(testTrack.id), isFalse);

      db.toggleFavorite(testTrack);
      expect(db.isFavorite(testTrack.id), isTrue);
      expect(db.getSavedTracks().length, equals(1));

      // Reload fresh database from same file
      final reloadedDb = LocalDatabase(storageDir: tempDir);
      expect(reloadedDb.isFavorite(testTrack.id), isTrue);

      // Toggle off
      reloadedDb.toggleFavorite(testTrack);
      expect(reloadedDb.isFavorite(testTrack.id), isFalse);
    });

    test('1-Click Backup Export and Restore matches structure', () {
      db.toggleFavorite(testTrack);
      db.createPlaylist('Favorites 2026', description: 'Test playlist');

      final backupJson = db.exportBackupJson();
      expect(backupJson.contains('Favorites 2026'), isTrue);
      expect(backupJson.contains('Utopia'), isTrue);

      final freshDir = Directory.systemTemp.createTempSync('levyra_restore_test_');
      final newDb = LocalDatabase(storageDir: freshDir);
      expect(newDb.getSavedTracks(), isEmpty);

      final success = newDb.restoreFromBackupJson(backupJson);
      expect(success, isTrue);
      expect(newDb.isFavorite(testTrack.id), isTrue);
      expect(newDb.getPlaylists().length, equals(1));
      expect(newDb.getPlaylists().first.title, equals('Favorites 2026'));

      freshDir.deleteSync(recursive: true);
    });
  });
}