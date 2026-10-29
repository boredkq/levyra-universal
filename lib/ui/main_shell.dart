import 'dart:io';
import 'package:flutter/material.dart';
import '../core/models/unified_track.dart';
import '../core/models/unified_artist.dart';
import '../core/models/unified_playlist.dart';
import '../core/models/synced_lyrics.dart';
import '../core/theme/levyra_colors.dart';
import '../core/theme/levyra_typography.dart';
import '../core/theme/levyra_theme.dart';
import '../sources/music_provider.dart';
import '../sources/composite_music_provider.dart';
import '../recognition/recognition_service.dart';
import '../audio/sponsorblock_controller.dart';
import '../audio/dsp_processor.dart';
import '../audio/stream_cache_proxy.dart';
import '../audio/playback_service.dart';
import 'components/player_mode_switch.dart';
import 'player/player_dock.dart';
import 'player/lyrics_karaoke_view.dart';
import 'player/video_player_surface.dart';
import 'player/desktop_mini_player.dart';
import 'player/youtube_comments_sheet.dart';
import 'recognition/recognition_sheet.dart';
import 'home/home_screen.dart';
import 'explore/explore_screen.dart';
import 'library/library_screen.dart';
import 'artist/artist_profile_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  final CompositeMusicProvider _musicProvider = CompositeMusicProvider();
  final MusicRecognitionService _recognitionService = MusicRecognitionService();
  final SponsorBlockController _sponsorBlock = SponsorBlockController();
  final StreamCacheProxy _cacheProxy = StreamCacheProxy(
    cacheDir: Directory('/tmp/levyra_audio_cache'),
  );

  late final PlaybackController _playbackController;

  int _selectedNavIndex = 0;
  bool _showLyricsDrawer = false;
  bool _showMiniPlayer = false;

  HomeFeed _homeFeed = const HomeFeed();

  @override
  void initState() {
    super.initState();
    _playbackController = PlaybackController(
      musicProvider: _musicProvider,
      cacheProxy: _cacheProxy,
      sponsorBlock: _sponsorBlock,
    );
    _playbackController.initialize();
    _playbackController.addListener(_onPlaybackChanged);
    _loadInitialData();
  }

  void _onPlaybackChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _playbackController.removeListener(_onPlaybackChanged);
    _playbackController.dispose();
    super.dispose();
  }

  void _loadInitialData() async {
    final sampleTrack = UnifiedTrack(
      id: 'ym:11223344',
      source: TrackSource.yandexMusic,
      sourceId: '11223344',
      title: 'Звёздная пыль',
      artists: const [
        UnifiedArtist(id: 'ym:artist:1', name: 'Miyagi', isVerified: true),
        UnifiedArtist(id: 'ym:artist:2', name: 'Эндшпиль', isVerified: true),
      ],
      duration: const Duration(minutes: 3, seconds: 45),
      thumbnailUrl: 'https://music.yandex.ru/blocks/common/default.400x400.png',
      videoId: 'sample_video_id',
      hasLyrics: true,
      replayGainDb: -1.5,
    );

    setState(() {
      _homeFeed = HomeFeed(
        personalOrbit: [sampleTrack],
        discoveryForYou: [sampleTrack],
        charts: [sampleTrack],
        newPremieres: [sampleTrack],
        secretStash: [sampleTrack],
        playlistOfTheDay: const UnifiedPlaylist(
          id: 'ym:daily',
          title: 'Плейлист дня',
          description: 'Персональная подборка от алгоритмов Яндекс Музыки',
          createdAt: null as dynamic ?? DateTime.timestamp(),
        ),
      );
    });

    try {
      final feed = await _musicProvider.getHomeFeed();
      if (mounted && feed.charts.isNotEmpty) {
        setState(() => _homeFeed = feed);
      }
    } catch (_) {}
  }

  void _playTrack(UnifiedTrack track) {
    _playbackController.playTrack(track, newQueue: _homeFeed.personalOrbit);
  }

  void _openArtist(UnifiedArtist artist) async {
    final details = await _musicProvider.getArtistDetails(artist.id);
    if (!mounted) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ArtistProfileScreen(
          artist: artist,
          details: details,
          onPlayTrack: _playTrack,
        ),
      ),
    );
  }

  void _openRecognitionSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RecognitionSheet(
        recognitionService: _recognitionService,
        onMatchFound: (match) {
          final matchedTrack = UnifiedTrack(
            id: match.matchedTrackId ?? 'ym:recognized',
            source: TrackSource.yandexMusic,
            sourceId: 'recognized',
            title: match.title,
            artists: [UnifiedArtist(id: 'artist', name: match.artist)],
            duration: const Duration(minutes: 3, seconds: 30),
            thumbnailUrl: match.artworkUrl ?? '',
          );
          _playTrack(matchedTrack);
        },
      ),
    );
  }

  void _openCommentsSheet() {
    if (_currentTrack == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => YoutubeCommentsSheet(
        comments: _currentComments,
        trackTitle: _currentTrack!.title,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 768;

    return Scaffold(
      backgroundColor: LevyraColors.canvas,
      body: Stack(
        children: [
          isDesktop ? _buildDesktopLayout() : _buildMobileLayout(),

          // Desktop Floating Mini-Player (Picture-in-Picture)
          if (_showMiniPlayer && isDesktop)
            Positioned(
              bottom: LevyraTheme.desktopPlayerHeight + 20,
              right: 20,
              child: DesktopMiniPlayer(
                track: _currentTrack,
                isPlaying: _isPlaying,
                currentLyricsLine: _currentLyrics?.lines.firstOrNull?.text,
                onTogglePlay: () => setState(() => _isPlaying = !_isPlaying),
                onNext: () {},
                onExpand: () => setState(() => _showMiniPlayer = false),
                onClose: () => setState(() => _showMiniPlayer = false),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        // Left Sidebar (220px)
        Container(
          width: LevyraTheme.sidebarWidth,
          color: LevyraColors.baseSurface,
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Logo
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: LevyraColors.cyan,
                      ),
                      child: const Icon(Icons.graphic_eq_rounded, size: 18, color: Colors.black),
                    ),
                    const SizedBox(width: 10),
                    Text('LEVYRA', style: LevyraTypography.display.copyWith(fontSize: 18, letterSpacing: 2)),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Nav Buttons
              _SidebarNavButton(
                icon: Icons.home_rounded,
                label: 'Главная',
                isSelected: _selectedNavIndex == 0,
                onTap: () => setState(() => _selectedNavIndex = 0),
              ),
              _SidebarNavButton(
                icon: Icons.explore_rounded,
                label: 'Обзор',
                isSelected: _selectedNavIndex == 1,
                onTap: () => setState(() => _selectedNavIndex = 1),
              ),
              _SidebarNavButton(
                icon: Icons.library_music_rounded,
                label: 'Медиатека',
                isSelected: _selectedNavIndex == 2,
                onTap: () => setState(() => _selectedNavIndex = 2),
              ),
              const Spacer(),

              // Desktop Mini-player Toggle button
              InkWell(
                onTap: () => setState(() => _showMiniPlayer = !_showMiniPlayer),
                borderRadius: BorderRadius.circular(LevyraTheme.radiusMd),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: _showMiniPlayer ? LevyraColors.elevatedContainer : Colors.transparent,
                    borderRadius: BorderRadius.circular(LevyraTheme.radiusMd),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.picture_in_picture_alt_rounded, color: LevyraColors.cyan, size: 18),
                      const SizedBox(width: 10),
                      Text('Мини-плеер', style: LevyraTypography.cardTitle.copyWith(fontSize: 12.5)),
                    ],
                  ),
                ),
              ),

              // Music Recognition (Shazam) button
              InkWell(
                onTap: _openRecognitionSheet,
                borderRadius: BorderRadius.circular(LevyraTheme.radiusMd),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: LevyraColors.container,
                    borderRadius: BorderRadius.circular(LevyraTheme.radiusMd),
                    border: Border.all(color: LevyraColors.hairline),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.mic_rounded, color: LevyraColors.mint, size: 20),
                      const SizedBox(width: 10),
                      Text('Распознать', style: LevyraTypography.cardTitle.copyWith(fontSize: 13)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Main content area + Player dock
        Expanded(
          child: Stack(
            children: [
              Column(
                children: [
                  Expanded(
                    child: _playbackController.isVideoMode && _playbackController.currentTrack != null
                        ? VideoPlayerSurface(
                            track: _playbackController.currentTrack!,
                            onSwitchToSong: () => _playbackController.setVideoMode(false),
                          )
                        : IndexedStack(
                            index: _selectedNavIndex,
                            children: [
                              HomeScreen(
                                feed: _homeFeed,
                                onPlayTrack: _playTrack,
                                onOpenPlaylist: (_) {},
                              ),
                              ExploreScreen(onPlayTrack: _playTrack),
                              LibraryScreen(
                                playlists: const [],
                                savedTracks: _homeFeed.personalOrbit,
                                onPlayTrack: _playTrack,
                              ),
                            ],
                          ),
                  ),
                  PlayerDock(
                    currentTrack: _playbackController.currentTrack,
                    isPlaying: _playbackController.state == PlaybackState.playing,
                    position: _playbackController.position,
                    duration: _playbackController.duration,
                    mode: _playbackController.isVideoMode ? PlayerPlaybackMode.video : PlayerPlaybackMode.song,
                    sponsorSegments: _playbackController.currentSegments,
                    onTogglePlay: _playbackController.togglePlayPause,
                    onNext: _playbackController.skipNext,
                    onPrevious: _playbackController.skipPrevious,
                    onSeek: _playbackController.seek,
                    onModeChanged: (m) => _playbackController.setVideoMode(m == PlayerPlaybackMode.video),
                    onToggleLyrics: () => setState(() => _showLyricsDrawer = !_showLyricsDrawer),
                    onToggleComments: _openCommentsSheet,
                    onSelectArtist: _openArtist,
                    onExpand: () {},
                  ),
                ],
              ),

              // Slide-in right panel for synced karaoke lyrics
              if (_showLyricsDrawer)
                Positioned(
                  top: 0,
                  bottom: LevyraTheme.desktopPlayerHeight,
                  right: 0,
                  width: 360,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: LevyraColors.baseSurface,
                      border: Border(left: BorderSide(color: LevyraColors.hairline)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Слова песни', style: LevyraTypography.sectionHeading),
                              IconButton(
                                icon: const Icon(Icons.close_rounded, color: LevyraColors.secondaryText),
                                onPressed: () => setState(() => _showLyricsDrawer = false),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: LyricsKaraokeView(
                            lyrics: _playbackController.currentLyrics,
                            currentPosition: _playbackController.position,
                            onSeek: (ms) => _playbackController.seek(Duration(milliseconds: ms)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Desktop Mini-Player Overlay (Always On Top PiP mode)
              if (_showMiniPlayer && _playbackController.currentTrack != null)
                Positioned(
                  bottom: LevyraTheme.desktopPlayerHeight + 16,
                  right: 24,
                  child: DesktopMiniPlayer(
                    track: _playbackController.currentTrack,
                    isPlaying: _playbackController.state == PlaybackState.playing,
                    currentLyricsLine: _playbackController.currentLyrics
                        ?.lineAt(_playbackController.position.inMilliseconds)
                        ?.text,
                    onTogglePlay: _playbackController.togglePlayPause,
                    onNext: _playbackController.skipNext,
                    onExpand: () => setState(() => _showMiniPlayer = false),
                    onClose: () => setState(() => _showMiniPlayer = false),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return Stack(
      children: [
        _playbackController.isVideoMode && _playbackController.currentTrack != null
            ? VideoPlayerSurface(
                track: _playbackController.currentTrack!,
                onSwitchToSong: () => _playbackController.setVideoMode(false),
              )
            : IndexedStack(
                index: _selectedNavIndex,
                children: [
                  HomeScreen(
                    feed: _homeFeed,
                    onPlayTrack: _playTrack,
                    onOpenPlaylist: (_) {},
                  ),
                  ExploreScreen(onPlayTrack: _playTrack),
                  LibraryScreen(
                    playlists: const [],
                    savedTracks: _homeFeed.personalOrbit,
                    onPlayTrack: _playTrack,
                  ),
                ],
              ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 56,
          child: PlayerDock(
            currentTrack: _playbackController.currentTrack,
            isPlaying: _playbackController.state == PlaybackState.playing,
            position: _playbackController.position,
            duration: _playbackController.duration,
            mode: _playbackController.isVideoMode ? PlayerPlaybackMode.video : PlayerPlaybackMode.song,
            sponsorSegments: _playbackController.currentSegments,
            onTogglePlay: _playbackController.togglePlayPause,
            onNext: _playbackController.skipNext,
            onPrevious: _playbackController.skipPrevious,
            onSeek: _playbackController.seek,
            onModeChanged: (m) => _playbackController.setVideoMode(m == PlayerPlaybackMode.video),
            onToggleLyrics: () => setState(() => _showLyricsDrawer = !_showLyricsDrawer),
            onToggleComments: _openCommentsSheet,
            onSelectArtist: _openArtist,
            onExpand: () {},
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: NavigationBar(
            selectedIndex: _selectedNavIndex,
            onDestinationSelected: (idx) => setState(() => _selectedNavIndex = idx),
            backgroundColor: LevyraColors.baseSurface,
            destinations: const [
              NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'Главная'),
              NavigationDestination(icon: Icon(Icons.explore_outlined), selectedIcon: Icon(Icons.explore_rounded), label: 'Обзор'),
              NavigationDestination(icon: Icon(Icons.library_music_outlined), selectedIcon: Icon(Icons.library_music_rounded), label: 'Медиатека'),
            ],
          ),
        ),
      ],
    );
  }
}

class _SidebarNavButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SidebarNavButton({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(LevyraTheme.radiusSm),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? LevyraColors.container : Colors.transparent,
            borderRadius: BorderRadius.circular(LevyraTheme.radiusSm),
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: isSelected ? LevyraColors.cyan : LevyraColors.secondaryText),
              const SizedBox(width: 12),
              Text(
                label,
                style: LevyraTypography.navItem.copyWith(
                  color: isSelected ? LevyraColors.primaryText : LevyraColors.secondaryText,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
