import 'dart:convert';
import 'dart:io';
import '../core/models/unified_track.dart';
import '../core/models/unified_playlist.dart';
import '../recognition/recognition_service.dart';

/// Local Storage and Relational Database with 1-Click Backup/Restore.
class LocalDatabase {
  final Directory storageDir;
  late final File _dbFile;

  final Map<String, UnifiedTrack> _savedTracks = {};
  final Map<String, UnifiedPlaylist> _playlists = {};
  final List<TrackRecognitionMatch> _recognitionHistory = [];
  final List<Map<String, dynamic>> _listeningHistory = [];

  LocalDatabase({required this.storageDir}) {
    if (!storageDir.existsSync()) {
      storageDir.createSync(recursive: true);
    }
    _dbFile = File('${storageDir.path}/levyra_database.json');
    _load();
  }

  void _load() {
    if (!_dbFile.existsSync()) return;
    try {
      final content = _dbFile.readAsStringSync();
      final data = jsonDecode(content) as Map<String, dynamic>;

      final tracks = data['savedTracks'] as List<dynamic>? ?? [];
      for (final t in tracks) {
        if (t is Map<String, dynamic>) {
          final track = UnifiedTrack.fromJson(t);
          _savedTracks[track.id] = track;
        }
      }

      final playlists = data['playlists'] as List<dynamic>? ?? [];
      for (final p in playlists) {
        if (p is Map<String, dynamic>) {
          final playlist = UnifiedPlaylist.fromJson(p);
          _playlists[playlist.id] = playlist;
        }
      }
    } catch (_) {}
  }

  void _save() {
    final data = {
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'savedTracks': _savedTracks.values.map((t) => t.toJson()).toList(),
      'playlists': _playlists.values.map((p) => p.toJson()).toList(),
      'listeningHistory': _listeningHistory,
    };
    _dbFile.writeAsStringSync(jsonEncode(data), flush: true);
  }

  // --- Favorites & Saved Tracks ---
  List<UnifiedTrack> getSavedTracks() => _savedTracks.values.toList();

  void toggleFavorite(UnifiedTrack track) {
    if (_savedTracks.containsKey(track.id)) {
      _savedTracks.remove(track.id);
    } else {
      _savedTracks[track.id] = track;
    }
    _save();
  }

  bool isFavorite(String trackId) => _savedTracks.containsKey(trackId);

  // --- Playlists & Drag-and-drop Reordering ---
  List<UnifiedPlaylist> getPlaylists() => _playlists.values.toList();

  void createPlaylist(String title, {String? description, String? coverUrl}) {
    final id = 'pl_${DateTime.now().millisecondsSinceEpoch}';
    final playlist = UnifiedPlaylist(
      id: id,
      title: title,
      description: description,
      coverUrl: coverUrl,
      createdAt: DateTime.now(),
    );
    _playlists[id] = playlist;
    _save();
  }

  void reorderPlaylistTracks(String playlistId, int oldIndex, int newIndex) {
    final pl = _playlists[playlistId];
    if (pl == null) return;

    final updatedTracks = List<UnifiedTrack>.from(pl.tracks);
    if (newIndex > oldIndex) newIndex -= 1;
    final item = updatedTracks.removeAt(oldIndex);
    updatedTracks.insert(newIndex, item);

    _playlists[playlistId] = UnifiedPlaylist(
      id: pl.id,
      title: pl.title,
      description: pl.description,
      coverUrl: pl.coverUrl,
      tracks: updatedTracks,
      isPinned: pl.isPinned,
      createdAt: pl.createdAt,
    );
    _save();
  }

  // --- Listening History & Pulse ---
  void logListening({
    required String trackId,
    required Duration durationPlayed,
    required bool completed,
  }) {
    _listeningHistory.add({
      'trackId': trackId,
      'playedAt': DateTime.now().toIso8601String(),
      'durationMs': durationPlayed.inMilliseconds,
      'completed': completed,
    });
    _save();
  }

  // --- 1-Click Backup and Restore ---
  String exportBackupJson() {
    final data = {
      'levyraBackupVersion': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'savedTracks': _savedTracks.values.map((t) => t.toJson()).toList(),
      'playlists': _playlists.values.map((p) => p.toJson()).toList(),
      'listeningHistory': _listeningHistory,
    };
    return jsonEncode(data);
  }

  bool restoreFromBackupJson(String jsonString) {
    try {
      final data = jsonDecode(jsonString) as Map<String, dynamic>;
      final tracks = data['savedTracks'] as List<dynamic>? ?? [];
      final playlists = data['playlists'] as List<dynamic>? ?? [];

      _savedTracks.clear();
      _playlists.clear();

      for (final t in tracks) {
        if (t is Map<String, dynamic>) {
          final track = UnifiedTrack.fromJson(t);
          _savedTracks[track.id] = track;
        }
      }

      for (final p in playlists) {
        if (p is Map<String, dynamic>) {
          final playlist = UnifiedPlaylist.fromJson(p);
          _playlists[playlist.id] = playlist;
        }
      }

      _save();
      return true;
    } catch (_) {
      return false;
    }
  }
}
