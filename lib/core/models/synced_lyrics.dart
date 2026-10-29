class LyricWord {
  final String text;
  final int startMs;
  final int durationMs;

  const LyricWord({
    required this.text,
    required this.startMs,
    required this.durationMs,
  });

  Map<String, dynamic> toJson() => {
    'text': text,
    'startMs': startMs,
    'durationMs': durationMs,
  };

  factory LyricWord.fromJson(Map<String, dynamic> json) => LyricWord(
    text: json['text'] as String,
    startMs: json['startMs'] as int,
    durationMs: json['durationMs'] as int,
  );
}

class LyricLine {
  final int startMs;
  final String text;
  final List<LyricWord> words;

  const LyricLine({
    required this.startMs,
    required this.text,
    this.words = const [],
  });

  Map<String, dynamic> toJson() => {
    'startMs': startMs,
    'text': text,
    'words': words.map((w) => w.toJson()).toList(),
  };

  factory LyricLine.fromJson(Map<String, dynamic> json) => LyricLine(
    startMs: json['startMs'] as int,
    text: json['text'] as String,
    words: (json['words'] as List<dynamic>?)
            ?.map((e) => LyricWord.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const [],
  );
}

class SyncedLyrics {
  final String trackId;
  final List<LyricLine> lines;
  final bool isWordSynced;

  const SyncedLyrics({
    required this.trackId,
    required this.lines,
    this.isWordSynced = false,
  });

  int findCurrentLineIndex(int currentMs) {
    if (lines.isEmpty) return -1;
    for (int i = lines.length - 1; i >= 0; i--) {
      if (currentMs >= lines[i].startMs) {
        return i;
      }
    }
    return 0;
  }
}
