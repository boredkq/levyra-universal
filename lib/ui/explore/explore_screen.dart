import 'package:flutter/material.dart';
import '../../core/models/unified_track.dart';
import '../../core/theme/levyra_colors.dart';
import '../../core/theme/levyra_typography.dart';
import '../../core/theme/levyra_theme.dart';

class ExploreScreen extends StatelessWidget {
  final Function(UnifiedTrack) onPlayTrack;

  const ExploreScreen({super.key, required this.onPlayTrack});

  static const List<Map<String, dynamic>> moodsAndGenres = [
    {'title': 'Энергия & Драйв', 'color': Color(0xFFE53935), 'icon': Icons.bolt_rounded},
    {'title': 'Фокус & Работа', 'color': Color(0xFF1E88E5), 'icon': Icons.psychology_rounded},
    {'title': 'Релакс & Чилл', 'color': Color(0xFF43A047), 'icon': Icons.spa_rounded},
    {'title': 'Вечеринка', 'color': Color(0xFF8E24AA), 'icon': Icons.celebration_rounded},
    {'title': 'Хип-хоп & Дрилл', 'color': Color(0xFFF4511E), 'icon': Icons.graphic_eq_rounded},
    {'title': 'Рок & Альтернатива', 'color': Color(0xFF546E7A), 'icon': Icons.album_rounded},
    {'title': 'Электроника & EDM', 'color': Color(0xFF00ACC1), 'icon': Icons.waves_rounded},
    {'title': 'R&B & Соул', 'color': Color(0xFFD81B60), 'icon': Icons.favorite_rounded},
    {'title': 'Фонк', 'color': Color(0xFF3949AB), 'icon': Icons.nightlife_rounded},
    {'title': 'Метал & Кор', 'color': Color(0xFF212121), 'icon': Icons.hearing_rounded},
    {'title': 'В дорогу', 'color': Color(0xFFFB8C00), 'icon': Icons.directions_car_rounded},
    {'title': 'Сон', 'color': Color(0xFF5E35B1), 'icon': Icons.bedtime_rounded},
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      children: [
        Text('Обзор', style: LevyraTypography.display.copyWith(fontSize: 28)),
        const SizedBox(height: 4),
        Text('Жанры, настроения, сэмплы и свежие клипы', style: LevyraTypography.metadata),
        const SizedBox(height: 24),

        // Сэмплы (Quick Samples Banner)
        _SamplesHeroBanner(),
        const SizedBox(height: 28),

        // 4-рядная сетка жанров и настроений
        Text('Настроения и жанры', style: LevyraTypography.sectionHeading),
        const SizedBox(height: 14),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 2.8,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: moodsAndGenres.length,
          itemBuilder: (context, index) {
            final item = moodsAndGenres[index];
            return _MoodGenreCard(
              title: item['title'] as String,
              accentColor: item['accentColor'] ?? (item['color'] as Color),
              icon: item['icon'] as IconData,
            );
          },
        ),
        const SizedBox(height: 32),

        // Новые музыкальные видео
        Text('Новые видеоклипы', style: LevyraTypography.sectionHeading),
        const SizedBox(height: 4),
        Text('Самые обсуждаемые видео недели', style: LevyraTypography.metadata),
        const SizedBox(height: 14),
        _VideoClipsRow(onPlay: onPlayTrack),
        const SizedBox(height: 100),
      ],
    );
  }
}

class _SamplesHeroBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: LevyraColors.container,
        borderRadius: BorderRadius.circular(LevyraTheme.radiusLg),
        border: Border.all(color: LevyraColors.mint.withOpacity(0.4), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: LevyraColors.mint,
            ),
            child: const Icon(Icons.flash_on_rounded, size: 28, color: Colors.black),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Сэмплы треков', style: LevyraTypography.cardTitle.copyWith(color: LevyraColors.mint)),
                const SizedBox(height: 2),
                Text('Быстрый поиск новой музыки в 30-секундных отрывках', style: LevyraTypography.metadata),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: LevyraColors.secondaryText),
        ],
      ),
    );
  }
}

class _MoodGenreCard extends StatelessWidget {
  final String title;
  final Color accentColor;
  final IconData icon;

  const _MoodGenreCard({
    required this.title,
    required this.accentColor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(LevyraTheme.radiusMd),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: LevyraColors.container,
          borderRadius: BorderRadius.circular(LevyraTheme.radiusMd),
          border: Border.all(color: LevyraColors.hairline, width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 28,
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: LevyraTypography.cardTitle.copyWith(fontSize: 13),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(icon, size: 18, color: accentColor.withOpacity(0.8)),
          ],
        ),
      ),
    );
  }
}

class _VideoClipsRow extends StatelessWidget {
  final Function(UnifiedTrack) onPlay;

  const _VideoClipsRow({required this.onPlay});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 160,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: 4,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          return Container(
            width: 220,
            decoration: BoxDecoration(
              color: LevyraColors.container,
              borderRadius: BorderRadius.circular(LevyraTheme.radiusMd),
              border: Border.all(color: LevyraColors.hairline, width: 1),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Center(
                  child: Icon(Icons.smart_display_rounded, size: 48, color: LevyraColors.cyan.withOpacity(0.7)),
                ),
                Positioned(
                  bottom: 10,
                  left: 12,
                  right: 12,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Музыкальный клип #${index + 1}', style: LevyraTypography.cardTitle.copyWith(fontSize: 13)),
                      Text('YouTube Music Video', style: LevyraTypography.metadata),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
