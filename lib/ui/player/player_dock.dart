import 'package:flutter/material.dart';
import '../../core/models/unified_track.dart';
import '../../core/models/unified_artist.dart';
import '../../core/models/sponsorblock_segment.dart';
import '../../core/theme/levyra_colors.dart';
import '../../core/theme/levyra_typography.dart';
import '../../core/theme/levyra_theme.dart';
import '../components/player_artist_cluster.dart';
import '../components/player_mode_switch.dart';

/// Desktop bottom player dock and Mobile floating mini-player.
class PlayerDock extends StatelessWidget {
  final UnifiedTrack? currentTrack;
  final bool isPlaying;
  final Duration position;
  final Duration duration;
  final PlayerPlaybackMode mode;
  final List<SponsorBlockSegment> sponsorSegments;
  final VoidCallback onTogglePlay;
  final VoidCallback onNext;
  final VoidCallback onPrevious;
  final ValueChanged<Duration> onSeek;
  final ValueChanged<PlayerPlaybackMode> onModeChanged;
  final VoidCallback onToggleLyrics;
  final VoidCallback onToggleComments;
  final Function(UnifiedArtist) onSelectArtist;
  final VoidCallback onExpand;

  const PlayerDock({
    super.key,
    required this.currentTrack,
    required this.isPlaying,
    required this.position,
    required this.duration,
    required this.mode,
    this.sponsorSegments = const [],
    required this.onTogglePlay,
    required this.onNext,
    required this.onPrevious,
    required this.onSeek,
    required this.onModeChanged,
    required this.onToggleLyrics,
    required this.onToggleComments,
    required this.onSelectArtist,
    required this.onExpand,
  });

  @override
  Widget build(BuildContext context) {
    if (currentTrack == null) return const SizedBox.shrink();

    final isDesktop = MediaQuery.of(context).size.width >= 768;

    return isDesktop
        ? _buildDesktopDock(context)
        : _buildMobileMiniPlayer(context);
  }

  Widget _buildDesktopDock(BuildContext context) {
    final track = currentTrack!;
    final posSeconds = position.inSeconds.toDouble();
    final durSeconds = duration.inSeconds > 0 ? duration.inSeconds.toDouble() : 1.0;

    return Container(
      height: LevyraTheme.desktopPlayerHeight,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: LevyraColors.elevatedContainer,
        border: Border(top: BorderSide(color: LevyraColors.hairline, width: 1)),
      ),
      child: Row(
        children: [
          // Left: Artwork + Track details + Circular Artist Cluster
          Expanded(
            flex: 3,
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(LevyraTheme.radiusSm),
                  child: Image.network(
                    track.thumbnailUrl,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 56,
                      height: 56,
                      color: LevyraColors.container,
                      child: const Icon(Icons.music_note_rounded),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Flexible(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        track.title,
                        style: LevyraTypography.cardTitle.copyWith(fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      PlayerTopArtistCluster(
                        artists: track.artists,
                        trackTitle: track.title,
                        onSelectArtist: onSelectArtist,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Center: Playback Controls & Progress Bar
          Expanded(
            flex: 5,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.shuffle_rounded, size: 18, color: LevyraColors.secondaryText),
                      onPressed: () {},
                    ),
                    IconButton(
                      icon: const Icon(Icons.skip_previous_rounded, size: 26, color: LevyraColors.primaryText),
                      onPressed: onPrevious,
                    ),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: LevyraColors.cyan,
                      ),
                      child: IconButton(
                        icon: Icon(
                          isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                          color: Colors.black,
                          size: 28,
                        ),
                        onPressed: onTogglePlay,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.skip_next_rounded, size: 26, color: LevyraColors.primaryText),
                      onPressed: onNext,
                    ),
                    IconButton(
                      icon: const Icon(Icons.repeat_rounded, size: 18, color: LevyraColors.secondaryText),
                      onPressed: () {},
                    ),
                  ],
                ),
                Row(
                  children: [
                    Text(_formatDuration(position), style: LevyraTypography.metadata),
                    Expanded(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          if (sponsorSegments.isNotEmpty && duration.inMilliseconds > 0)
                            LayoutBuilder(
                              builder: (ctx, constraints) {
                                final totalMs = duration.inMilliseconds;
                                final width = constraints.maxWidth;
                                return Stack(
                                  children: sponsorSegments.map((seg) {
                                    final startRatio = (seg.startMs / totalMs).clamp(0.0, 1.0);
                                    final endRatio = (seg.endMs / totalMs).clamp(0.0, 1.0);
                                    final segWidth = ((endRatio - startRatio) * width).clamp(2.0, width);
                                    return Positioned(
                                      left: startRatio * width,
                                      width: segWidth,
                                      height: 3,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: LevyraColors.mint.withOpacity(0.9),
                                          borderRadius: BorderRadius.circular(1.5),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                );
                              },
                            ),
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                              trackHeight: 3,
                              activeTrackColor: LevyraColors.cyan,
                              inactiveTrackColor: LevyraColors.highestContainer,
                              thumbColor: Colors.white,
                            ),
                            child: Slider(
                              value: posSeconds.clamp(0.0, durSeconds),
                              max: durSeconds,
                              onChanged: (v) => onSeek(Duration(seconds: v.toInt())),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(_formatDuration(duration), style: LevyraTypography.metadata),
                  ],
                ),
              ],
            ),
          ),

          // Right: Mode switch [Песня | Клип], Lyrics, Comments, Volume
          Expanded(
            flex: 3,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                PlayerModeSwitch(
                  mode: mode,
                  onModeChanged: onModeChanged,
                  hasVideo: track.videoId != null,
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.lyrics_rounded, size: 20, color: LevyraColors.secondaryText),
                  onPressed: onToggleLyrics,
                  tooltip: 'Слова песни',
                ),
                IconButton(
                  icon: const Icon(Icons.chat_bubble_outline_rounded, size: 19, color: LevyraColors.secondaryText),
                  onPressed: onToggleComments,
                  tooltip: 'Комментарии YouTube',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileMiniPlayer(BuildContext context) {
    final track = currentTrack!;

    return GestureDetector(
      onTap: onExpand,
      child: Container(
        height: LevyraTheme.mobileMiniPlayerHeight,
        margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: LevyraColors.elevatedContainer,
          borderRadius: BorderRadius.circular(LevyraTheme.radiusMd),
          border: Border.all(color: LevyraColors.hairline, width: 1),
          boxShadow: const [
            BoxShadow(color: Colors.black54, blurRadius: 12, offset: Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(LevyraTheme.radiusSm),
              child: Image.network(
                track.thumbnailUrl,
                width: 44,
                height: 44,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    track.title,
                    style: LevyraTypography.cardTitle.copyWith(fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    track.artistNames,
                    style: LevyraTypography.metadata,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            PlayerModeSwitch(
              mode: mode,
              onModeChanged: onModeChanged,
              hasVideo: track.videoId != null,
            ),
            IconButton(
              icon: Icon(
                isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: LevyraColors.cyan,
                size: 28,
              ),
              onPressed: onTogglePlay,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }
}
