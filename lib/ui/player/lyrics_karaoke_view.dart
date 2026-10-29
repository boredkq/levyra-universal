import 'package:flutter/material.dart';
import '../../core/models/synced_lyrics.dart';
import '../../core/theme/levyra_colors.dart';
import '../../core/theme/levyra_typography.dart';

/// Karaoke-style interactive synchronized lyrics viewer.
class LyricsKaraokeView extends StatefulWidget {
  final SyncedLyrics? lyrics;
  final Duration currentPosition;
  final Function(int seekMs) onSeek;

  const LyricsKaraokeView({
    super.key,
    required this.lyrics,
    required this.currentPosition,
    required this.onSeek,
  });

  @override
  State<LyricsKaraokeView> createState() => _LyricsKaraokeViewState();
}

class _LyricsKaraokeViewState extends State<LyricsKaraokeView> {
  final ScrollController _scrollController = ScrollController();
  int _lastActiveIndex = -1;

  @override
  void didUpdateWidget(covariant LyricsKaraokeView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.lyrics == null || widget.lyrics!.lines.isEmpty) return;

    final currentMs = widget.currentPosition.inMilliseconds;
    final activeIndex = widget.lyrics!.findCurrentLineIndex(currentMs);

    if (activeIndex != _lastActiveIndex && activeIndex >= 0) {
      _lastActiveIndex = activeIndex;
      _scrollToActiveLine(activeIndex);
    }
  }

  void _scrollToActiveLine(int index) {
    if (!_scrollController.hasClients) return;
    const itemHeight = 60.0;
    final targetOffset = (index * itemHeight) - 120.0;
    _scrollController.animateTo(
      targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lyrics = widget.lyrics;
    if (lyrics == null || lyrics.lines.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lyrics_outlined, size: 48, color: LevyraColors.mutedText),
            const SizedBox(height: 12),
            Text(
              'Текст песни недоступен',
              style: LevyraTypography.sectionHeading.copyWith(color: LevyraColors.secondaryText),
            ),
          ],
        ),
      );
    }

    final currentMs = widget.currentPosition.inMilliseconds;
    final activeIndex = lyrics.findCurrentLineIndex(currentMs);

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 80),
      itemCount: lyrics.lines.length,
      itemBuilder: (context, index) {
        final line = lyrics.lines[index];
        final isActive = index == activeIndex;
        final isPast = index < activeIndex;

        return GestureDetector(
          onTap: () => widget.onSeek(line.startMs),
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              line.text,
              style: isActive
                  ? LevyraTypography.karaokeActive.copyWith(color: LevyraColors.cyan)
                  : (isPast
                      ? LevyraTypography.karaokeInactive.copyWith(color: Colors.white70)
                      : LevyraTypography.karaokeInactive.copyWith(color: Colors.white24)),
            ),
          ),
        );
      },
    );
  }
}
