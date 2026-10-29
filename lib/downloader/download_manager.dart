import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../core/models/unified_track.dart';
import 'id3_tag_writer.dart';

enum DownloadStatus {
  queued,
  downloading,
  tagging,
  completed,
  failed,
  paused,
}

class DownloadTask {
  final UnifiedTrack track;
  final String streamUrl;
  final String destinationPath;
  DownloadStatus status;
  double progress;
  int bytesReceived;
  int totalBytes;
  String? errorMessage;

  DownloadTask({
    required this.track,
    required this.streamUrl,
    required this.destinationPath,
    this.status = DownloadStatus.queued,
    this.progress = 0.0,
    this.bytesReceived = 0,
    this.totalBytes = 0,
    this.errorMessage,
  });
}

class DownloadManager {
  final Directory downloadDirectory;
  final http.Client _client = http.Client();
  final Map<String, DownloadTask> _tasks = {};
  final StreamController<DownloadTask> _taskUpdates = StreamController.broadcast();

  Stream<DownloadTask> get onTaskUpdate => _taskUpdates.stream;
  List<DownloadTask> get allTasks => _tasks.values.toList();

  DownloadManager({required this.downloadDirectory});

  /// Enqueue track for downloading and tagging
  Future<void> enqueue(UnifiedTrack track, String streamUrl) async {
    final sanitizedArtist = _sanitize(track.artistNames);
    final sanitizedTitle = _sanitize(track.title);
    final fileName = '$sanitizedArtist - $sanitizedTitle.mp3';
    final filePath = '${downloadDirectory.path}/$fileName';

    final task = DownloadTask(
      track: track,
      streamUrl: streamUrl,
      destinationPath: filePath,
    );

    _tasks[track.id] = task;
    _taskUpdates.add(task);

    _startDownload(task);
  }

  Future<void> _startDownload(DownloadTask task) async {
    task.status = DownloadStatus.downloading;
    _taskUpdates.add(task);

    try {
      if (!downloadDirectory.existsSync()) {
        downloadDirectory.createSync(recursive: true);
      }

      final file = File(task.destinationPath);
      final tempFile = File('${task.destinationPath}.part');

      final request = http.Request('GET', Uri.parse(task.streamUrl));
      final response = await _client.send(request);

      task.totalBytes = response.contentLength ?? 0;
      final sink = tempFile.openWrite();

      await for (final chunk in response.stream) {
        sink.add(chunk);
        task.bytesReceived += chunk.length;
        if (task.totalBytes > 0) {
          task.progress = (task.bytesReceived / task.totalBytes).clamp(0.0, 1.0);
        }
        _taskUpdates.add(task);
      }

      await sink.flush();
      await sink.close();

      // Tagging phase
      task.status = DownloadStatus.tagging;
      _taskUpdates.add(task);

      await _embedMetadata(tempFile, task.track);

      if (file.existsSync()) file.deleteSync();
      tempFile.renameSync(file.path);

      task.status = DownloadStatus.completed;
      task.progress = 1.0;
      _taskUpdates.add(task);
    } catch (e) {
      task.status = DownloadStatus.failed;
      task.errorMessage = e.toString();
      _taskUpdates.add(task);
    }
  }

  /// Embeds ID3v2.4 tags and high-res cover artwork
  Future<void> _embedMetadata(File audioFile, UnifiedTrack track) async {
    try {
      await Id3TagWriter.writeTags(audioFile, track);
    } catch (_) {
      // Non-fatal if tagging fails on non-mp3 stream
    }
  }

  String _sanitize(String input) {
    return input.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_').trim();
  }
}
