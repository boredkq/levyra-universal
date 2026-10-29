import 'package:flutter/material.dart';
import '../../core/models/unified_artist.dart';
import '../../core/theme/levyra_colors.dart';
import '../../core/theme/levyra_typography.dart';
import '../../core/theme/levyra_theme.dart';

/// Bottom sheet opened when tapping the artist cluster on tracks with multiple artists.
class PlayerArtistPickerSheet extends StatelessWidget {
  final String trackTitle;
  final List<UnifiedArtist> artists;
  final Function(UnifiedArtist) onSelect;

  const PlayerArtistPickerSheet({
    super.key,
    required this.trackTitle,
    required this.artists,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: LevyraColors.elevatedContainer,
        borderRadius: BorderRadius.vertical(top: Radius.circular(LevyraTheme.radiusXl)),
        border: Border(top: BorderSide(color: LevyraColors.hairline, width: 1)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: LevyraColors.strongOutline,
                borderRadius: BorderRadius.circular(LevyraTheme.radiusPill),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Исполнители трека',
            style: LevyraTypography.pageHeading.copyWith(fontSize: 20),
          ),
          const SizedBox(height: 4),
          Text(
            trackTitle,
            style: LevyraTypography.metadata.copyWith(fontSize: 13),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 140,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: artists.length,
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemBuilder: (context, index) {
                final artist = artists[index];
                return _ArtistPickerCard(
                  artist: artist,
                  onTap: () {
                    Navigator.of(context).pop();
                    onSelect(artist);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ArtistPickerCard extends StatelessWidget {
  final UnifiedArtist artist;
  final VoidCallback onTap;

  const _ArtistPickerCard({
    required this.artist,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const avatarSize = 78.0;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(LevyraTheme.radiusMd),
      child: Container(
        width: 110,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: LevyraColors.container,
          borderRadius: BorderRadius.circular(LevyraTheme.radiusMd),
          border: Border.all(color: LevyraColors.hairline, width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: avatarSize,
              height: avatarSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: LevyraColors.highestContainer,
                border: Border.all(color: LevyraColors.cyan.withOpacity(0.4), width: 1.5),
              ),
              child: ClipOval(
                child: artist.avatarUrl != null && artist.avatarUrl!.isNotEmpty
                    ? Image.network(
                        artist.avatarUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _Initial(name: artist.name),
                      )
                    : _Initial(name: artist.name),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              artist.name,
              style: LevyraTypography.cardTitle.copyWith(fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _Initial extends StatelessWidget {
  final String name;

  const _Initial({required this.name});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : '?',
        style: const TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w700,
          color: LevyraColors.cyan,
        ),
      ),
    );
  }
}
