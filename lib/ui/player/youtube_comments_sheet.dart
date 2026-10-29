import 'package:flutter/material.dart';
import '../../core/theme/levyra_colors.dart';
import '../../core/theme/levyra_typography.dart';
import '../../core/theme/levyra_theme.dart';
import '../../sources/music_provider.dart';

class YoutubeCommentsSheet extends StatelessWidget {
  final List<TrackComment> comments;
  final String trackTitle;

  const YoutubeCommentsSheet({
    super.key,
    required this.comments,
    required this.trackTitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: LevyraColors.elevatedContainer,
        borderRadius: BorderRadius.vertical(top: Radius.circular(LevyraTheme.radiusXl)),
        border: Border(top: BorderSide(color: LevyraColors.hairline, width: 1)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Column(
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Комментарии YouTube', style: LevyraTypography.sectionHeading),
                  Text(trackTitle, style: LevyraTypography.metadata),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: LevyraColors.secondaryText),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: LevyraColors.hairline, height: 1),
          Expanded(
            child: comments.isEmpty
                ? Center(
                    child: Text('Комментариев пока нет', style: LevyraTypography.metadata),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    itemCount: comments.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final comment = comments[index];
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: LevyraColors.container,
                            child: Text(
                              comment.authorName.isNotEmpty ? comment.authorName[0].toUpperCase() : '?',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: LevyraColors.cyan),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(comment.authorName, style: LevyraTypography.cardTitle.copyWith(fontSize: 13)),
                                    const SizedBox(width: 8),
                                    Text(comment.publishedTime, style: LevyraTypography.metadata.copyWith(fontSize: 11)),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(comment.text, style: LevyraTypography.body.copyWith(fontSize: 13.5)),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(Icons.thumb_up_alt_outlined, size: 14, color: LevyraColors.secondaryText),
                                    const SizedBox(width: 4),
                                    Text('${comment.likeCount}', style: LevyraTypography.metadata),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
