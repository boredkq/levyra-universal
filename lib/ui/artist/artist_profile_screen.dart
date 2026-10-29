import 'package:flutter/material.dart';
import '../../core/models/unified_artist.dart';
import '../../core/models/unified_track.dart';
import '../../core/models/unified_album.dart';
import '../../core/theme/levyra_colors.dart';
import '../../core/theme/levyra_typography.dart';
import '../../core/theme/levyra_theme.dart';
import '../../sources/music_provider.dart';

class ArtistProfileScreen extends StatelessWidget {
  final UnifiedArtist artist;
  final ArtistDetails? details;
  final Function(UnifiedTrack) onPlayTrack;

  const ArtistProfileScreen({
    super.key,
    required this.artist,
    this.details,
    required this.onPlayTrack,
  });

  @override
  Widget build(BuildContext context) {
    final topTracks = details?.topTracks ?? [];
    final albums = details?.albums ?? [];
    final singles = details?.singlesAndEps ?? [];
    final similar = details?.similarArtists ?? [];

    return Scaffold(
      backgroundColor: LevyraColors.canvas,
      body: CustomScrollView(
        slivers: [
          // Hero AppBar with artist banner and verified badge
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: LevyraColors.baseSurface,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              title: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    artist.name,
                    style: LevyraTypography.pageHeading.copyWith(fontSize: 18),
                  ),
                  if (artist.isVerified) ...[
                    const SizedBox(width: 6),
                    const Icon(Icons.verified_rounded, size: 16, color: LevyraColors.cyan),
                  ],
                ],
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (artist.avatarUrl != null)
                    Image.network(
                      artist.avatarUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(color: LevyraColors.container),
                    )
                  else
                    Container(color: LevyraColors.container),
                  // Gradient Overlay
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          LevyraColors.canvas.withOpacity(0.5),
                          LevyraColors.canvas,
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Action buttons row (Play, Shuffle, Follow)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      if (topTracks.isNotEmpty) onPlayTrack(topTracks.first);
                    },
                    icon: const Icon(Icons.play_arrow_rounded, color: Colors.black),
                    label: const Text('Слушать', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.black)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: LevyraColors.cyan,
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.shuffle_rounded, size: 18, color: LevyraColors.primaryText),
                    label: const Text('Перемешать', style: TextStyle(color: LevyraColors.primaryText)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: LevyraColors.strongOutline),
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.favorite_border_rounded, color: LevyraColors.secondaryText),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ),

          // Popular tracks section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text('Популярные треки', style: LevyraTypography.sectionHeading),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final track = topTracks[index];
                return ListTile(
                  leading: Text(
                    '${index + 1}',
                    style: LevyraTypography.metadata.copyWith(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  title: Text(track.title, style: LevyraTypography.cardTitle),
                  subtitle: Text(track.artistNames, style: LevyraTypography.metadata),
                  trailing: Text(
                    _formatDuration(track.duration),
                    style: LevyraTypography.metadata,
                  ),
                  onTap: () => onPlayTrack(track),
                );
              },
              childCount: topTracks.length,
            ),
          ),

          // Discography - Albums
          if (albums.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                child: Text('Альбомы', style: LevyraTypography.sectionHeading),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 190,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: albums.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 16),
                  itemBuilder: (context, index) {
                    final album = albums[index];
                    return _AlbumCard(album: album);
                  },
                ),
              ),
            ),
          ],

          // Discography - Singles & EPs
          if (singles.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                child: Text('Синглы и EP', style: LevyraTypography.sectionHeading),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 190,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: singles.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 16),
                  itemBuilder: (context, index) {
                    final single = singles[index];
                    return _AlbumCard(album: single);
                  },
                ),
              ),
            ),
          ],

          // Similar artists
          if (similar.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                child: Text('Похожие исполнители', style: LevyraTypography.sectionHeading),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 140,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: similar.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 16),
                  itemBuilder: (context, index) {
                    final simArtist = similar[index];
                    return Column(
                      children: [
                        CircleAvatar(
                          radius: 38,
                          backgroundColor: LevyraColors.elevatedContainer,
                          backgroundImage: simArtist.avatarUrl != null
                              ? NetworkImage(simArtist.avatarUrl!)
                              : null,
                          child: simArtist.avatarUrl == null
                              ? Text(simArtist.name[0], style: const TextStyle(fontSize: 22, color: LevyraColors.cyan))
                              : null,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          simArtist.name,
                          style: LevyraTypography.metadata.copyWith(color: LevyraColors.primaryText),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }
}

class _AlbumCard extends StatelessWidget {
  final UnifiedAlbum album;

  const _AlbumCard({required this.album});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(LevyraTheme.radiusMd),
            child: Container(
              width: 140,
              height: 140,
              color: LevyraColors.container,
              child: album.coverUrl != null
                  ? Image.network(album.coverUrl!, fit: BoxFit.cover)
                  : const Icon(Icons.album_rounded, size: 48, color: LevyraColors.mutedText),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            album.title,
            style: LevyraTypography.cardTitle.copyWith(fontSize: 13),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (album.year != null)
            Text(
              '${album.year}',
              style: LevyraTypography.metadata,
            ),
        ],
      ),
    );
  }
}
