import 'package:flutter/material.dart';
import '../../core/models/unified_playlist.dart';
import '../../core/models/unified_track.dart';
import '../../core/theme/levyra_colors.dart';
import '../../core/theme/levyra_typography.dart';
import '../../core/theme/levyra_theme.dart';

enum LibraryTab {
  playlists,
  songs,
  albums,
  artists,
  downloads,
  pulse,
}

class LibraryScreen extends StatefulWidget {
  final List<UnifiedPlaylist> playlists;
  final List<UnifiedTrack> savedTracks;
  final Function(UnifiedTrack) onPlayTrack;

  const LibraryScreen({
    super.key,
    required this.playlists,
    required this.savedTracks,
    required this.onPlayTrack,
  });

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  LibraryTab _activeTab = LibraryTab.playlists;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Медиатека', style: LevyraTypography.display.copyWith(fontSize: 28)),
            IconButton(
              icon: const Icon(Icons.add_circle_outline_rounded, size: 26, color: LevyraColors.cyan),
              onPressed: () {},
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Filter chips row
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _TabChip(
                label: 'Плейлисты',
                icon: Icons.playlist_play_rounded,
                isSelected: _activeTab == LibraryTab.playlists,
                onTap: () => setState(() => _activeTab = LibraryTab.playlists),
              ),
              _TabChip(
                label: 'Треки',
                icon: Icons.music_note_rounded,
                isSelected: _activeTab == LibraryTab.songs,
                onTap: () => setState(() => _activeTab = LibraryTab.songs),
              ),
              _TabChip(
                label: 'Скачанное',
                icon: Icons.download_done_rounded,
                isSelected: _activeTab == LibraryTab.downloads,
                onTap: () => setState(() => _activeTab = LibraryTab.downloads),
              ),
              _TabChip(
                label: 'Пульс',
                icon: Icons.insights_rounded,
                isSelected: _activeTab == LibraryTab.pulse,
                onTap: () => setState(() => _activeTab = LibraryTab.pulse),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Content per active tab
        if (_activeTab == LibraryTab.playlists)
          _PlaylistsView(playlists: widget.playlists)
        else if (_activeTab == LibraryTab.songs)
          _SongsView(tracks: widget.savedTracks, onPlay: widget.onPlayTrack)
        else if (_activeTab == LibraryTab.downloads)
          _DownloadsView()
        else if (_activeTab == LibraryTab.pulse)
          _PulseInsightsView(),

        const SizedBox(height: 100),
      ],
    );
  }
}

class _TabChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: isSelected ? Colors.black : LevyraColors.secondaryText),
            const SizedBox(width: 6),
            Text(label),
          ],
        ),
        selected: isSelected,
        onSelected: (_) => onTap(),
        selectedColor: LevyraColors.cyan,
        backgroundColor: LevyraColors.container,
        labelStyle: TextStyle(
          color: isSelected ? Colors.black : LevyraColors.primaryText,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          fontSize: 13,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(LevyraTheme.radiusPill),
          side: BorderSide(
            color: isSelected ? Colors.transparent : LevyraColors.hairline,
            width: 1,
          ),
        ),
      ),
    );
  }
}

class _PlaylistsView extends StatelessWidget {
  final List<UnifiedPlaylist> playlists;

  const _PlaylistsView({required this.playlists});

  @override
  Widget build(BuildContext context) {
    if (playlists.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 40),
        alignment: Alignment.Center,
        child: Column(
          children: [
            const Icon(Icons.queue_music_rounded, size: 54, color: LevyraColors.mutedText),
            const SizedBox(height: 12),
            Text('Нет созданных плейлистов', style: LevyraTypography.sectionHeading),
            const SizedBox(height: 4),
            Text('Создайте гибридный плейлист из треков разных источников', style: LevyraTypography.metadata),
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: playlists.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final pl = playlists[index];
        return ListTile(
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: LevyraColors.container,
              borderRadius: BorderRadius.circular(LevyraTheme.radiusSm),
            ),
            child: pl.coverUrl != null
                ? Image.network(pl.coverUrl!, fit: BoxFit.cover)
                : const Icon(Icons.playlist_play_rounded, color: LevyraColors.cyan),
          ),
          title: Text(pl.title, style: LevyraTypography.cardTitle),
          subtitle: Text('${pl.tracks.length} треков', style: LevyraTypography.metadata),
          trailing: const Icon(Icons.drag_handle_rounded, color: LevyraColors.mutedText),
        );
      },
    );
  }
}

class _SongsView extends StatelessWidget {
  final List<UnifiedTrack> tracks;
  final Function(UnifiedTrack) onPlay;

  const _SongsView({required this.tracks, required this.onPlay});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: tracks.length,
      separatorBuilder: (_, __) => const Divider(color: LevyraColors.hairline, height: 1),
      itemBuilder: (context, index) {
        final track = tracks[index];
        return ListTile(
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(LevyraTheme.radiusSm),
            child: Image.network(
              track.thumbnailUrl,
              width: 46,
              height: 46,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Icon(Icons.music_note_rounded),
            ),
          ),
          title: Text(track.title, style: LevyraTypography.cardTitle),
          subtitle: Text(track.artistNames, style: LevyraTypography.metadata),
          trailing: const Icon(Icons.more_horiz_rounded, color: LevyraColors.secondaryText),
          onTap: () => onPlay(track),
        );
      },
    );
  }
}

class _DownloadsView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: LevyraColors.container,
        borderRadius: BorderRadius.circular(LevyraTheme.radiusMd),
        border: Border.all(color: LevyraColors.hairline, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Офлайн-хранилище', style: LevyraTypography.sectionHeading),
              Text('3.2 ГБ / 20 ГБ', style: LevyraTypography.metadata.copyWith(color: LevyraColors.cyan)),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: 0.16,
            backgroundColor: LevyraColors.elevatedContainer,
            color: LevyraColors.cyan,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 16),
          Text(
            'Все скачанные треки снабжены ID3v2 тегами, обложками в высоком разрешении и караоке-текстами.',
            style: LevyraTypography.metadata,
          ),
        ],
      ),
    );
  }
}

class _PulseInsightsView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: LevyraColors.container,
        borderRadius: BorderRadius.circular(LevyraTheme.radiusLg),
        border: Border.all(color: LevyraColors.violet.withOpacity(0.4), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bolt_rounded, color: LevyraColors.violet, size: 22),
              const SizedBox(width: 8),
              Text('ПУЛЬС ПРОСЛУШИВАНИЯ', style: LevyraTypography.overline.copyWith(color: LevyraColors.violet)),
            ],
          ),
          const SizedBox(height: 6),
          Text('Приватная статистика устройства', style: LevyraTypography.sectionHeading),
          const SizedBox(height: 4),
          Text('Рассчитывается локально без отправки данных на сервера', style: LevyraTypography.metadata),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatItem(number: '1,420', label: 'Минут музыки'),
              _StatItem(number: '84', label: 'Исполнителя'),
              _StatItem(number: '21:00', label: 'Пиковый час'),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String number;
  final String label;

  const _StatItem({required this.number, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(number, style: LevyraTypography.display.copyWith(fontSize: 22, color: LevyraColors.cyan)),
        const SizedBox(height: 2),
        Text(label, style: LevyraTypography.metadata),
      ],
    );
  }
}
