import 'package:flutter/material.dart';
import '../../core/theme/levyra_colors.dart';
import '../../core/theme/levyra_typography.dart';
import '../../core/theme/levyra_theme.dart';
import '../../recognition/recognition_service.dart';

class RecognitionSheet extends StatefulWidget {
  final MusicRecognitionService recognitionService;
  final Function(TrackRecognitionMatch) onMatchFound;

  const RecognitionSheet({
    super.key,
    required this.recognitionService,
    required this.onMatchFound,
  });

  @override
  State<RecognitionSheet> createState() => _RecognitionSheetState();
}

class _RecognitionSheetState extends State<RecognitionSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  TrackRecognitionMatch? _match;
  bool _isSearching = true;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _startRecognition();
  }

  void _startRecognition() async {
    final result = await widget.recognitionService.recognizeFromMicrophone();
    if (mounted) {
      setState(() {
        _match = result;
        _isSearching = false;
      });
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    widget.recognitionService.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: LevyraColors.elevatedContainer,
        borderRadius: BorderRadius.vertical(top: Radius.circular(LevyraTheme.radiusXl)),
        border: Border(top: BorderSide(color: LevyraColors.hairline, width: 1)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: LevyraColors.strongOutline,
              borderRadius: BorderRadius.circular(LevyraTheme.radiusPill),
            ),
          ),
          const SizedBox(height: 24),

          if (_isSearching) ...[
            Text('Распознавание музыки', style: LevyraTypography.pageHeading.copyWith(fontSize: 22)),
            const SizedBox(height: 6),
            Text('Слушаю трек вокруг вас через микрофон...', style: LevyraTypography.metadata.copyWith(fontSize: 13)),
            const SizedBox(height: 40),

            // Pulsing radar circles
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Stack(
                  alignment: Alignment.Center,
                  children: [
                    Container(
                      width: 140 + (_pulseController.value * 40),
                      height: 140 + (_pulseController.value * 40),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: LevyraColors.mint.withOpacity((1.0 - _pulseController.value) * 0.25),
                      ),
                    ),
                    Container(
                      width: 110,
                      height: 110,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: LevyraColors.mint,
                        boxShadow: [
                          BoxShadow(color: LevyraColors.mint, blurRadius: 20, spreadRadius: 2),
                        ],
                      ),
                      child: const Icon(Icons.graphic_eq_rounded, size: 52, color: Colors.black),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 40),
          ] else if (_match != null) ...[
            Text('Трек распознан!', style: LevyraTypography.pageHeading.copyWith(color: LevyraColors.mint)),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: LevyraColors.container,
                borderRadius: BorderRadius.circular(LevyraTheme.radiusMd),
                border: Border.all(color: LevyraColors.hairline),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(LevyraTheme.radiusSm),
                    child: Container(
                      width: 64,
                      height: 64,
                      color: LevyraColors.highestContainer,
                      child: _match!.artworkUrl != null
                          ? Image.network(_match!.artworkUrl!, fit: BoxFit.cover)
                          : const Icon(Icons.music_note_rounded, size: 32),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_match!.title, style: LevyraTypography.cardTitle.copyWith(fontSize: 16)),
                        const SizedBox(height: 4),
                        Text(_match!.artist, style: LevyraTypography.metadata.copyWith(fontSize: 13)),
                        if (_match!.album != null) ...[
                          const SizedBox(height: 2),
                          Text(_match!.album!, style: LevyraTypography.metadata),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  widget.onMatchFound(_match!);
                },
                icon: const Icon(Icons.play_arrow_rounded, color: Colors.black),
                label: const Text('Слушать в Levyra', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: LevyraColors.cyan,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(LevyraTheme.radiusPill)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
