import 'package:flutter/material.dart';
import '../../core/models/unified_track.dart';
import '../../core/theme/levyra_colors.dart';
import '../../core/theme/levyra_typography.dart';
import '../../core/theme/levyra_theme.dart';

/// Desktop Picture-in-Picture / Always-on-top Mini-Player.
class DesktopMiniPlayer extends StatelessWidget {
  final UnifiedTrack? track;
  final bool isPlaying;
  final String? currentLyricsLine;
  final VoidCallback onTogglePlay;
  final VoidCallback onNext;
  final VoidCallback onExpand;
  final VoidCallback onClose;

  const DesktopMiniPlayer({
    super.key,
    required this.track,
    required this.isPlaying,
    this.currentLyricsLine,
    required this.onTogglePlay,
    required this.onNext,
    required this.onExpand,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    if (track == null) return const SizedBox.shrink();

    return Material(
      color: Colors.transparent,
      child: Container(
        width: 310,
        height: 94,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: LevyraColors.elevatedContainer,
          borderRadius: BorderRadius.circular(LevyraTheme.radiusMd),
          border: Border.all(color: LevyraColors.strongOutline, width: 1.5),
          boxShadow: const [
            BoxShadow(
              color: Colors.black87,
              blurRadius: 16,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            // Artwork
            ClipRRect(
              borderRadius: BorderRadius.circular(LevyraTheme.radiusSm),
              child: Image.network(
                track!.thumbnailUrl,
                width: 74,
                height: 74,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 74,
                  height: 74,
                  color: LevyraColors.container,
                  child: const Icon(Icons.music_note_rounded, color: LevyraColors.cyan),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Track details + Lyrics ticker
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    track!.title,
                    style: LevyraTypography.cardTitle.copyWith(fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    track!.artistNames,
                    style: LevyraTypography.metadata.copyWith(fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  if (currentLyricsLine != null && currentLyricsLine!.isNotEmpty)
                    Text(
                      currentLyricsLine!,
                      style: LevyraTypography.metadata.copyWith(
                        fontSize: 10.5,
                        color: LevyraColors.cyan,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),

            // Playback controls & Actions
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: onExpand,
                      child: const Icon(Icons.open_in_full_rounded, size: 14, color: LevyraColors.secondaryText),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: onClose,
                      child: const Icon(Icons.close_rounded, size: 14, color: LevyraColors.secondaryText),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                        color: LevyraColors.cyan,
                        size: 26,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: onTogglePlay,
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.skip_next_rounded, size: 22, color: LevyraColors.primaryText),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: onNext,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
