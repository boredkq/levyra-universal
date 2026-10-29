import 'package:flutter/material.dart';
import '../../core/models/unified_track.dart';
import '../../core/models/unified_playlist.dart';
import '../../core/theme/levyra_colors.dart';
import '../../core/theme/levyra_typography.dart';
import '../../core/theme/levyra_theme.dart';
import '../../sources/music_provider.dart';

class HomeScreen extends StatelessWidget {
  final HomeFeed feed;
  final Function(UnifiedTrack) onPlayTrack;
  final Function(UnifiedPlaylist) onOpenPlaylist;

  const HomeScreen({
    super.key,
    required this.feed,
    required this.onPlayTrack,
    required this.onOpenPlaylist,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      children: [
        // Top Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Главная', style: LevyraTypography.display.copyWith(fontSize: 28)),
            IconButton(
              icon: const Icon(Icons.tune_rounded, color: LevyraColors.secondaryText),
              onPressed: () {},
            ),
          ],
        ),
        const SizedBox(height: 20),

        // «Твоя орбита» (Hero card with dynamic gradient and continuous play)
        _PersonalOrbitHeroCard(
          onStartOrbit: () {
            if (feed.personalOrbit.isNotEmpty) {
              onPlayTrack(feed.personalOrbit.first);
            }
          },
        ),
        const SizedBox(height: 32),

        // «Плейлист дня»
        if (feed.playlistOfTheDay != null) ...[
          _SectionTitle(title: 'Плейлист дня', subtitle: 'Обновляется каждое утро специально для вас'),
          const SizedBox(height: 12),
          _DailyPlaylistCard(
            playlist: feed.playlistOfTheDay!,
            onTap: () => onOpenPlaylist(feed.playlistOfTheDay!),
          ),
          const SizedBox(height: 32),
        ],

        // «Открытие для вас»
        _SectionTitle(title: 'Открытие для вас', subtitle: 'Свежие треки, подобранные алгоритмом под ваш вкус'),
        const SizedBox(height: 12),
        _HorizontalTrackShelf(tracks: feed.discoveryForYou, onPlay: onPlayTrack),
        const SizedBox(height: 32),

        // «Чарты» (Топ-50)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const _SectionTitle(title: 'Чарты', subtitle: 'Самое популярное сейчас'),
            TextButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.public_rounded, size: 16, color: LevyraColors.cyan),
              label: const Text('Россия', style: TextStyle(color: LevyraColors.cyan, fontSize: 13)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _HorizontalTrackShelf(tracks: feed.charts, onPlay: onPlayTrack),
        const SizedBox(height: 32),

        // «Премьеры треков»
        _SectionTitle(title: 'Премьеры треков', subtitle: 'Новинки за последние 48 часов'),
        const SizedBox(height: 12),
        _HorizontalTrackShelf(tracks: feed.newPremieres, onPlay: onPlayTrack),
        const SizedBox(height: 32),

        // «Тайник» (Забытые сокровища)
        _SectionTitle(title: 'Тайник', subtitle: 'Любимые треки из прошлого, которые вы давно не слушали'),
        const SizedBox(height: 12),
        _HorizontalTrackShelf(tracks: feed.secretStash, onPlay: onPlayTrack),
        const SizedBox(height: 100),
      ],
    );
  }
}

class _PersonalOrbitHeroCard extends StatelessWidget {
  final VoidCallback onStartOrbit;

  const _PersonalOrbitHeroCard({required this.onStartOrbit});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 170,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(LevyraTheme.radiusLg),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF3B1E6D),
            Color(0xFF13172E),
            LevyraColors.container,
          ],
        ),
        border: Border.all(color: LevyraColors.violet.withOpacity(0.35), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: LevyraColors.violet.withOpacity(0.18),
            blurRadius: 20,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    const Icon(Icons.all_inclusive_rounded, size: 20, color: LevyraColors.violet),
                    const SizedBox(width: 8),
                    Text(
                      'ТВОЯ ОРБИТА',
                      style: LevyraTypography.overline.copyWith(color: LevyraColors.violet),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Бесконечный персональный поток',
                  style: LevyraTypography.pageHeading.copyWith(fontSize: 19),
                ),
                const SizedBox(height: 4),
                Text(
                  'Треки, к которым ты всегда возвращаешься',
                  style: LevyraTypography.metadata.copyWith(fontSize: 12.5),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: onStartOrbit,
            style: ElevatedButton.styleFrom(
              backgroundColor: LevyraColors.violet,
              shape: const CircleBorder(),
              padding: const EdgeInsets.all(16),
            ),
            child: const Icon(Icons.play_arrow_rounded, size: 30, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _DailyPlaylistCard extends StatelessWidget {
  final UnifiedPlaylist playlist;
  final VoidCallback onTap;

  const _DailyPlaylistCard({required this.playlist, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(LevyraTheme.radiusMd),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: LevyraColors.container,
          borderRadius: BorderRadius.circular(LevyraTheme.radiusMd),
          border: Border.all(color: LevyraColors.hairline, width: 1),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(LevyraTheme.radiusSm),
              child: Container(
                width: 64,
                height: 64,
                color: LevyraColors.elevatedContainer,
                child: playlist.coverUrl != null
                    ? Image.network(playlist.coverUrl!, fit: BoxFit.cover)
                    : const Icon(Icons.playlist_play_rounded, size: 36, color: LevyraColors.cyan),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(playlist.title, style: LevyraTypography.cardTitle),
                  const SizedBox(height: 4),
                  Text(playlist.description ?? '', style: LevyraTypography.metadata),
                ],
              ),
            ),
            const Icon(Icons.play_circle_fill_rounded, size: 36, color: LevyraColors.cyan),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionTitle({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: LevyraTypography.sectionHeading),
        const SizedBox(height: 2),
        Text(subtitle, style: LevyraTypography.metadata),
      ],
    );
  }
}

class _HorizontalTrackShelf extends StatelessWidget {
  final List<UnifiedTrack> tracks;
  final Function(UnifiedTrack) onPlay;

  const _HorizontalTrackShelf({required this.tracks, required this.onPlay});

  @override
  Widget build(BuildContext context) {
    if (tracks.isEmpty) {
      return Container(
        height: 160,
        alignment: Alignment.Center,
        child: Text('Загрузка подборок...', style: LevyraTypography.metadata),
      );
    }

    return SizedBox(
      height: 185,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: tracks.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final track = tracks[index];
          return InkWell(
            onTap: () => onPlay(track),
            borderRadius: BorderRadius.circular(LevyraTheme.radiusMd),
            child: SizedBox(
              width: 130,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(LevyraTheme.radiusMd),
                    child: Container(
                      width: 130,
                      height: 130,
                      color: LevyraColors.container,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.network(
                            track.thumbnailUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(Icons.music_note_rounded, size: 40, color: LevyraColors.mutedText),
                          ),
                          Positioned(
                            bottom: 6,
                            right: 6,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.black87,
                              ),
                              child: const Icon(Icons.play_arrow_rounded, size: 16, color: LevyraColors.cyan),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
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
          );
        },
      ),
    );
  }
}
