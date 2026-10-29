import 'package:flutter/material.dart';
import '../../core/models/unified_artist.dart';
import '../../core/theme/levyra_colors.dart';
import '../../core/theme/levyra_typography.dart';
import '../../core/theme/levyra_theme.dart';
import 'player_artist_picker_sheet.dart';

/// Circular artist cluster for media player.
/// Ported directly from Levyra `PlayerTopArtistCluster`.
class PlayerTopArtistCluster extends StatelessWidget {
  final List<UnifiedArtist> artists;
  final String trackTitle;
  final Function(UnifiedArtist) onSelectArtist;

  static const double avatarSize = 46.0;
  static const double avatarStep = 34.0;
  static const int visibleLimit = 2;

  const PlayerTopArtistCluster({
    super.key,
    required this.artists,
    required this.trackTitle,
    required this.onSelectArtist,
  });

  void _handleClick(BuildContext context) {
    if (artists.isEmpty) return;
    if (artists.length == 1) {
      onSelectArtist(artists.first);
    } else {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (_) => PlayerArtistPickerSheet(
          trackTitle: trackTitle,
          artists: artists,
          onSelect: onSelectArtist,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (artists.isEmpty) return const SizedBox.shrink();

    final visible = artists.take(visibleLimit).toList();
    final overflow = artists.length - visible.length;
    final totalWidth = avatarSize + (avatarStep * (visible.length + (overflow > 0 ? 1 : 0) - 1));

    return InkWell(
      onTap: () => _handleClick(context),
      borderRadius: BorderRadius.circular(LevyraTheme.radiusPill),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: totalWidth,
              height: avatarSize,
              child: Stack(
                children: [
                  for (int i = 0; i < visible.length; i++)
                    Positioned(
                      left: i * avatarStep,
                      child: _ArtistAvatarCircle(artist: visible[i]),
                    ),
                  if (overflow > 0)
                    Positioned(
                      left: visible.length * avatarStep,
                      child: Container(
                        width: avatarSize,
                        height: avatarSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: LevyraColors.elevatedContainer,
                          border: Border.all(color: LevyraColors.strongOutline, width: 1.5),
                          boxShadow: const [
                            BoxShadow(color: Colors.black45, blurRadius: 6, offset: Offset(0, 2))
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '+$overflow',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: LevyraColors.primaryText,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'ИСПОЛНИТЕЛЬ',
                    style: LevyraTypography.overline.copyWith(color: LevyraColors.cyan),
                  ),
                  Text(
                    artists.map((a) => a.name).join(', '),
                    style: LevyraTypography.cardTitle.copyWith(fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ArtistAvatarCircle extends StatelessWidget {
  final UnifiedArtist artist;

  const _ArtistAvatarCircle({required this.artist});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: PlayerTopArtistCluster.avatarSize,
      height: PlayerTopArtistCluster.avatarSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: LevyraColors.container,
        border: Border.all(color: LevyraColors.strongOutline, width: 2),
        boxShadow: const [
          BoxShadow(color: Colors.black54, blurRadius: 8, offset: Offset(0, 3)),
        ],
      ),
      child: ClipOval(
        child: artist.avatarUrl != null && artist.avatarUrl!.isNotEmpty
            ? Image.network(
                artist.avatarUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _FallbackInitial(name: artist.name),
              )
            : _FallbackInitial(name: artist.name),
      ),
    );
  }
}

class _FallbackInitial extends StatelessWidget {
  final String name;

  const _FallbackInitial({required this.name});

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : '?';
    return Container(
      color: LevyraColors.highestContainer,
      alignment: Alignment.center,
      child: Text(
        initial,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: LevyraColors.primaryText,
        ),
      ),
    );
  }
}
