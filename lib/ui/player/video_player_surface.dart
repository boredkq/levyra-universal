import 'package:flutter/material.dart';
import '../../core/models/unified_track.dart';
import '../../core/theme/levyra_colors.dart';
import '../../core/theme/levyra_typography.dart';
import '../../core/theme/levyra_theme.dart';
import '../components/player_mode_switch.dart';

/// Fullscreen or embedded video player surface with pinch-to-zoom (1.0x - 5.0x)
/// ported from Levyra `PlayerVideoZoom.kt`.
class VideoPlayerSurface extends StatefulWidget {
  final UnifiedTrack track;
  final String? videoStreamUrl;
  final VoidCallback onSwitchToSong;

  const VideoPlayerSurface({
    super.key,
    required this.track,
    this.videoStreamUrl,
    required this.onSwitchToSong,
  });

  @override
  State<VideoPlayerSurface> createState() => _VideoPlayerSurfaceState();
}

class _VideoPlayerSurfaceState extends State<VideoPlayerSurface> {
  double _scale = 1.0;
  Offset _offset = Offset.zero;

  static const double minScale = 1.0;
  static const double maxScale = 5.0;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Gesture detector for Pinch-to-zoom
          GestureDetector(
            onScaleUpdate: (details) {
              setState(() {
                _scale = (_scale * details.scale).clamp(minScale, maxScale);
                _offset += details.focalPointDelta;
              });
            },
            onDoubleTap: () {
              setState(() {
                _scale = _scale > 1.5 ? 1.0 : 2.0;
                _offset = Offset.zero;
              });
            },
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..translate(_offset.dx, _offset.dy)
                ..scale(_scale),
              child: Center(
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      image: DecorationImage(
                        image: NetworkImage(widget.track.thumbnailUrl),
                        fit: BoxFit.cover,
                      ),
                    ),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black54,
                          border: Border.all(color: LevyraColors.cyan, width: 2),
                        ),
                        child: const Icon(
                          Icons.smart_display_rounded,
                          size: 54,
                          color: LevyraColors.cyan,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Top Header overlay with Mode Switch
          Positioned(
            top: 20,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.track.title,
                      style: LevyraTypography.cardTitle.copyWith(color: Colors.white, fontSize: 16),
                    ),
                    Text(
                      widget.track.artistNames,
                      style: LevyraTypography.metadata.copyWith(color: Colors.white70),
                    ),
                  ],
                ),
                PlayerModeSwitch(
                  mode: PlayerPlaybackMode.video,
                  onModeChanged: (newMode) {
                    if (newMode == PlayerPlaybackMode.song) {
                      widget.onSwitchToSong();
                    }
                  },
                ),
              ],
            ),
          ),

          // Scale indicator badge if zoomed
          if (_scale > 1.05)
            Positioned(
              bottom: 24,
              left: 24,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(LevyraTheme.radiusPill),
                  border: Border.all(color: LevyraColors.hairline),
                ),
                child: Text(
                  '${_scale.toStringAsFixed(1)}x зум (двойной тап для сброса)',
                  style: LevyraTypography.metadata.copyWith(color: LevyraColors.cyan),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
