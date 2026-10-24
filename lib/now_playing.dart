import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jobee_server/provider/audio_provider.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:provider/provider.dart';

class NowPlaying extends StatefulWidget {
  final SongModel songModel;
  const NowPlaying({
    super.key,
    required this.songModel,
  });

  @override
  State<NowPlaying> createState() => _NowPlayingState();
}

class _NowPlayingState extends State<NowPlaying> {
  final OnAudioQuery _audioQuery = OnAudioQuery();
  late final PageController _pageController;
  bool _isSeeking = false;
  double _seekValue = 0.0;
  bool _isSyncing = false;
  bool _syncingPageFromProvider = false;
  int? _lastProviderIndexSynced;

  LinearGradient _backgroundGradient = const LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0x66121212),
      Color(0xCC0A0A0A),
      Color(0xFF000000),
    ],
  );

  int? _paletteSongId;
  int? _scheduledPaletteSongId;

  static const double _artworkPlayingScale = 1.0;
  static const double _artworkPausedScale = 0.88;
  static const Duration _artworkScaleDuration = Duration(milliseconds: 280);

  Color _seedFromPalette(PaletteGenerator p) {
    return p.darkVibrantColor?.color ??
        p.vibrantColor?.color ??
        p.darkMutedColor?.color ??
        p.mutedColor?.color ??
        p.dominantColor?.color ??
        const Color(0xFF2A1510);
  }

  LinearGradient _gradientFromSeed(Color seed) {
    final top = Color.lerp(seed, Colors.black, 0.55)!;
    final mid = Color.lerp(seed, Colors.black, 0.78)!;
    final bottom = Color.lerp(seed, Colors.black, 0.92)!;
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        top.withValues(alpha: 0.55),
        mid.withValues(alpha: 0.82),
        bottom,
      ],
      stops: const [0.0, 0.45, 1.0],
    );
  }

  Future<void> _loadBackgroundPalette(int songId) async {
    Uint8List? bytes;
    try {
      bytes = await _audioQuery.queryArtwork(
        songId,
        ArtworkType.AUDIO,
        format: ArtworkFormat.JPEG,
        size: 200,
        quality: 80,
      );
    } catch (_) {
      bytes = null;
    }
    if (!mounted) return;

    if (bytes == null || bytes.isEmpty) {
      setState(() {
        _backgroundGradient = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0x66332218),
            Color(0xCC120A08),
            Color(0xFF000000),
          ],
        );
      });
      return;
    }

    final palette = await PaletteGenerator.fromImageProvider(
      MemoryImage(bytes),
      size: const Size(112, 112),
      maximumColorCount: 12,
    );
    if (!mounted) return;

    final provider = Provider.of<AudioPlayerProvider>(context, listen: false);
    final activeId = provider.currentSong?.id ?? widget.songModel.id;
    if (activeId != songId) return;

    setState(() {
      _backgroundGradient = _gradientFromSeed(_seedFromPalette(palette));
    });
  }

  void _syncBackgroundPalette(SongModel song) {
    if (_paletteSongId == song.id) return;
    _paletteSongId = song.id;
    _loadBackgroundPalette(song.id);
  }

  void _schedulePaletteLoad(SongModel song) {
    if (_scheduledPaletteSongId == song.id) return;
    _scheduledPaletteSongId = song.id;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _syncBackgroundPalette(song);
    });
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _jumpToCurrentSong());
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  int _indexForSong(AudioPlayerProvider provider, SongModel song) {
    final idx = provider.songs.indexWhere((s) => s.id == song.id);
    return idx >= 0 ? idx : 0;
  }

  void _jumpToCurrentSong() {
    if (!mounted || !_pageController.hasClients) return;
    final provider = Provider.of<AudioPlayerProvider>(context, listen: false);
    if (provider.songs.isEmpty) return;
    final song = provider.currentSong ?? widget.songModel;
    final index = _indexForSong(provider, song);
    final current =
        _pageController.page?.round() ?? _pageController.initialPage;
    if (current != index) {
      _pageController.jumpToPage(index);
    }
  }

  void _syncPageFromProvider(AudioPlayerProvider provider) {
    if (_syncingPageFromProvider || !mounted || provider.songs.isEmpty) {
      return;
    }
    final song = provider.currentSong ?? widget.songModel;
    final index = _indexForSong(provider, song);
    if (!_pageController.hasClients) return;
    final current = _pageController.page?.round() ?? index;
    if (current != index) {
      _pageController.jumpToPage(index);
    }
  }

  Future<void> _onPageChanged(int index, AudioPlayerProvider provider) async {
    if (provider.songs.isEmpty || index < 0 || index >= provider.songs.length) {
      return;
    }
    final song = provider.songs[index];
    final current = provider.currentSong;
    if (current != null && current.id == song.id) return;

    _syncingPageFromProvider = true;
    _lastProviderIndexSynced = index;
    HapticFeedback.mediumImpact();
    _paletteSongId = null;
    _scheduledPaletteSongId = null;
    _schedulePaletteLoad(song);
    if (_isSeeking) {
      setState(() => _isSeeking = false);
    }
    await provider.playSong(song);
    if (mounted) {
      setState(() => _syncingPageFromProvider = false);
    }
  }

  void _showSpeedPitchSheet(AudioPlayerProvider provider) {
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) {
        double tempSpeed = provider.speed;
        double tempPitch = provider.pitch;

        return StatefulBuilder(
          builder: (context, setStateSheet) {
            return CupertinoAlertDialog(
              title: const Text('Modify tune'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CupertinoButton(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        color:
                            CupertinoColors.systemGrey5.withValues(alpha: 0.4),
                        minimumSize: const Size(28, 28),
                        borderRadius: BorderRadius.circular(16),
                        child: Text(
                          _isSyncing ? 'Syncing' : 'Sync',
                          style: TextStyle(
                            fontSize: 13,
                            color: _isSyncing
                                ? CupertinoColors.activeGreen
                                : CupertinoColors.label,
                          ),
                        ),
                        onPressed: () {
                          setState(() {
                            _isSyncing = !_isSyncing;
                          });
                          Navigator.of(ctx).pop();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _isSyncing
                        ? 'Speed & Pitch ${tempSpeed.toStringAsFixed(2)}x'
                        : 'Speed ${tempSpeed.toStringAsFixed(2)}x',
                    style: const TextStyle(
                      fontSize: 13,
                      color: CupertinoColors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  CupertinoSlider(
                    min: 0.7,
                    max: 1.4,
                    divisions: 35,
                    value: tempSpeed,
                    onChanged: (v) {
                      final snapped = (v / 0.02).round() * 0.02;
                      final clamped = snapped.clamp(0.7, 1.4);
                      setStateSheet(() => tempSpeed = clamped);
                      provider.setSpeed(clamped);
                      if (_isSyncing) {
                        setStateSheet(() => tempPitch = clamped);
                        provider.setPitch(clamped);
                      }
                    },
                  ),
                  if (!_isSyncing) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Pitch ${tempPitch.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: CupertinoColors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    CupertinoSlider(
                      min: 0.7,
                      max: 1.4,
                      divisions: 35,
                      value: tempPitch,
                      onChanged: (v) {
                        final snapped = (v / 0.02).round() * 0.02;
                        final clamped = snapped.clamp(0.7, 1.4);
                        setStateSheet(() => tempPitch = clamped);
                        provider.setPitch(clamped);
                      },
                    ),
                  ],
                  const Divider(
                    color: Colors.grey,
                    thickness: 0.7,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      CupertinoButton(
                        onPressed: () {
                          provider.setSpeed(1.0);
                          provider.setPitch(1.0);
                          Navigator.of(ctx).pop();
                        },
                        child: const Text(
                          'Reset',
                          style: TextStyle(
                            color: Colors.grey,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                      CupertinoButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: const Text(
                          'Done',
                          style: TextStyle(
                            color: Colors.black,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _formatRemaining(Duration position, Duration duration) {
    if (duration <= Duration.zero) return '-00:00';
    var remaining = duration - position;
    if (remaining.isNegative) remaining = Duration.zero;
    final provider = Provider.of<AudioPlayerProvider>(context, listen: false);
    return '-${provider.formatDuration(remaining)}';
  }

  Widget _artworkPlaceholder({double iconSize = 48}) {
    return ColoredBox(
      color: const Color(0xFF3A3A3A),
      child: Icon(
        Icons.music_note_rounded,
        size: iconSize,
        color: Colors.white24,
      ),
    );
  }

  Widget _buildBlurredBackground(SongModel song, {required bool isActivePage}) {
    final gradient = isActivePage
        ? _backgroundGradient
        : const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0x66121212),
              Color(0xCC0A0A0A),
              Color(0xFF000000),
            ],
          );
    return Stack(
      fit: StackFit.expand,
      children: [
        QueryArtworkWidget(
          key: ValueKey('bg_${song.id}'),
          id: song.id,
          type: ArtworkType.AUDIO,
          keepOldArtwork: true,
          size: 512,
          artworkFit: BoxFit.cover,
          artworkBorder: BorderRadius.zero,
          nullArtworkWidget: _artworkPlaceholder(iconSize: 64),
        ),
        if (isActivePage)
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 56, sigmaY: 56),
            child: Container(
              color: Colors.black.withValues(alpha: 0.35),
            ),
          )
        else
          Container(
            color: Colors.black.withValues(alpha: 0.55),
          ),
        Container(
          decoration: BoxDecoration(gradient: gradient),
        ),
      ],
    );
  }

  Widget _buildMainArtwork(SongModel song, bool isPlaying,
      {required bool isActivePage}) {
    final width = MediaQuery.sizeOf(context).width;
    final artSize = (width - 56).clamp(260.0, 340.0);

    return GestureDetector(
      onTap: isActivePage
          ? () {
              HapticFeedback.lightImpact();
              Provider.of<AudioPlayerProvider>(context, listen: false)
                  .playPause();
            }
          : null,
      child: AnimatedScale(
        scale: isPlaying ? _artworkPlayingScale : _artworkPausedScale,
        duration: _artworkScaleDuration,
        curve: Curves.easeOutCubic,
        child: Container(
          width: artSize,
          height: artSize,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 28,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: QueryArtworkWidget(
            key: ValueKey('main_${song.id}'),
            id: song.id,
            type: ArtworkType.AUDIO,
            keepOldArtwork: true,
            size: 512,
            artworkFit: BoxFit.cover,
            quality: 100,
            nullArtworkWidget: _artworkPlaceholder(),
          ),
        ),
      ),
    );
  }

  Widget _circleActionButton({
    required IconData icon,
    required VoidCallback? onPressed,
    Color iconColor = Colors.white,
  }) {
    return Material(
      color: Colors.white.withValues(alpha: 0.12),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: IconButton(
        icon: Icon(icon, color: iconColor, size: 22),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildSongPage({
    required SongModel song,
    required AudioPlayerProvider provider,
    required bool isActivePage,
    required double bottomPad,
  }) {
    final isPlaying = provider.isPlaying && isActivePage;

    if (isActivePage) {
      _schedulePaletteLoad(song);
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        _buildBlurredBackground(song, isActivePage: isActivePage),
        SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 48),
              const Spacer(flex: 2),
              Center(
                child: _buildMainArtwork(
                  song,
                  isPlaying,
                  isActivePage: isActivePage,
                ),
              ),
              const Spacer(flex: 3),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _MiniArtworkWithVisualizer(
                      song: song,
                      isPlaying: isPlaying,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: GestureDetector(
                        onLongPress: isActivePage
                            ? () => _showSpeedPitchSheet(provider)
                            : null,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              song.displayNameWOExt,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                letterSpacing: -0.2,
                                height: 1.25,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              song.artist ?? 'Unknown artist',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.white.withValues(alpha: 0.55),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    _circleActionButton(
                      icon: provider.isFavourite(song.id)
                          ? Icons.check_rounded
                          : Icons.favorite_border_rounded,
                      iconColor: Colors.white54,
                      onPressed: isActivePage
                          ? () => provider.toggleFavourite(song.id)
                          : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              if (isActivePage)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _ProgressSection(
                    provider: provider,
                    isSeeking: _isSeeking,
                    seekValue: _seekValue,
                    formatRemaining: _formatRemaining,
                    onSeekStart: (v) {
                      setState(() {
                        _isSeeking = true;
                        _seekValue = v;
                      });
                    },
                    onSeekChanged: (v) {
                      setState(() => _seekValue = v);
                    },
                    onSeekEnd: (v) {
                      provider.seekTo(Duration(milliseconds: v.round()));
                      setState(() => _isSeeking = false);
                    },
                  ),
                )
              else
                const SizedBox(height: 40),
              const Spacer(),
              Column(
                children: [
                  Icon(
                    Icons.keyboard_double_arrow_up_rounded,
                    color: Colors.white.withValues(alpha: 0.45),
                    size: 28,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Swipe for more',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.4),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: bottomPad + 8),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Consumer<AudioPlayerProvider>(
        builder: (context, provider, _) {
          final activeSong = provider.currentSong ?? widget.songModel;

          final targetIndex =
              provider.songs.isEmpty ? 0 : _indexForSong(provider, activeSong);
          if (!_syncingPageFromProvider &&
              _lastProviderIndexSynced != targetIndex) {
            _lastProviderIndexSynced = targetIndex;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted || _syncingPageFromProvider) return;
              _syncPageFromProvider(provider);
            });
          }

          if (provider.songs.isEmpty) {
            return Stack(
              fit: StackFit.expand,
              children: [
                _buildSongPage(
                  song: activeSong,
                  provider: provider,
                  isActivePage: true,
                  bottomPad: bottomPad,
                ),
                SafeArea(
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ),
              ],
            );
          }

          return Stack(
            fit: StackFit.expand,
            children: [
              PageView.builder(
                controller: _pageController,
                scrollDirection: Axis.vertical,
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                onPageChanged: (index) => _onPageChanged(index, provider),
                itemCount: provider.songs.length,
                itemBuilder: (context, index) {
                  final song = provider.songs[index];
                  final isActivePage = activeSong.id == song.id;
                  return _buildSongPage(
                    song: song,
                    provider: provider,
                    isActivePage: isActivePage,
                    bottomPad: bottomPad,
                  );
                },
              ),
              SafeArea(
                child: Align(
                  alignment: Alignment.topLeft,
                  child: IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MiniArtworkWithVisualizer extends StatelessWidget {
  const _MiniArtworkWithVisualizer({
    required this.song,
    required this.isPlaying,
  });

  final SongModel song;
  final bool isPlaying;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: SizedBox(
        width: 52,
        height: 52,
        child: Stack(
          fit: StackFit.expand,
          children: [
            QueryArtworkWidget(
              key: ValueKey('mini_${song.id}'),
              id: song.id,
              type: ArtworkType.AUDIO,
              keepOldArtwork: true,
              size: 128,
              artworkFit: BoxFit.cover,
              nullArtworkWidget: const ColoredBox(
                color: Color(0xFF3A3A3A),
                child: Icon(
                  Icons.music_note_rounded,
                  color: Colors.white24,
                  size: 24,
                ),
              ),
            ),
            if (isPlaying)
              ColoredBox(
                color: Colors.black.withValues(alpha: 0.45),
                child: const Center(
                  child: Icon(
                    Icons.graphic_eq_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ProgressSection extends StatelessWidget {
  const _ProgressSection({
    required this.provider,
    required this.isSeeking,
    required this.seekValue,
    required this.formatRemaining,
    required this.onSeekStart,
    required this.onSeekChanged,
    required this.onSeekEnd,
  });

  final AudioPlayerProvider provider;
  final bool isSeeking;
  final double seekValue;
  final String Function(Duration position, Duration duration) formatRemaining;
  final void Function(double) onSeekStart;
  final void Function(double) onSeekChanged;
  final void Function(double) onSeekEnd;

  @override
  Widget build(BuildContext context) {
    final duration = provider.duration;
    final position = provider.position;
    final max = duration.inMilliseconds.toDouble();
    final currentValue = position.inMilliseconds.toDouble();
    final displayPosition =
        isSeeking ? Duration(milliseconds: seekValue.round()) : position;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 3,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 0),
            overlayShape: SliderComponentShape.noOverlay,
            activeTrackColor: Colors.white,
            inactiveTrackColor: Colors.white.withValues(alpha: 0.18),
          ),
          child: Slider(
            min: 0.0,
            max: max > 0 ? max : 1.0,
            value: isSeeking
                ? seekValue.clamp(0.0, max > 0 ? max : 1.0)
                : (max > 0 ? currentValue.clamp(0.0, max) : 0.0),
            onChangeStart: onSeekStart,
            onChanged: onSeekChanged,
            onChangeEnd: onSeekEnd,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                provider.formatDuration(displayPosition),
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.45),
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              Text(
                formatRemaining(displayPosition, duration),
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.45),
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
