import 'package:flutter/material.dart';
import '../../core/theme/levyra_colors.dart';
import '../../core/theme/levyra_typography.dart';
import '../../core/theme/levyra_theme.dart';

enum PlayerPlaybackMode {
  song,
  video,
}

/// Animated mode switcher [Песня | Клип] in the media player.
class PlayerModeSwitch extends StatelessWidget {
  final PlayerPlaybackMode mode;
  final ValueChanged<PlayerPlaybackMode> onModeChanged;
  final bool hasVideo;

  const PlayerModeSwitch({
    super.key,
    required this.mode,
    required this.onModeChanged,
    this.hasVideo = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!hasVideo) return const SizedBox.shrink();

    final isVideo = mode == PlayerPlaybackMode.video;

    return Container(
      height: 36,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: LevyraColors.elevatedContainer,
        borderRadius: BorderRadius.circular(LevyraTheme.radiusPill),
        border: Border.all(color: LevyraColors.hairline, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ModeItem(
            label: 'Песня',
            icon: Icons.music_note_rounded,
            isSelected: !isVideo,
            onTap: () => onModeChanged(PlayerPlaybackMode.song),
          ),
          _ModeItem(
            label: 'Клип',
            icon: Icons.smart_display_rounded,
            isSelected: isVideo,
            onTap: () => onModeChanged(PlayerPlaybackMode.video),
          ),
        ],
      ),
    );
  }
}

class _ModeItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModeItem({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? LevyraColors.cyan : Colors.transparent,
          borderRadius: BorderRadius.circular(LevyraTheme.radiusPill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.black : LevyraColors.secondaryText,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: LevyraTypography.navItem.copyWith(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.black : LevyraColors.secondaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
