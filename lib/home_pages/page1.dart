import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:jobee_server/now_playing.dart';
import 'package:jobee_server/provider/audio_provider.dart';
import 'package:jobee_server/provider/user_provider.dart';
import 'package:jobee_server/theme/theme_data.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:provider/provider.dart';

class Page1 extends StatefulWidget {
  const Page1({super.key});

  @override
  State<Page1> createState() => Page1State();
}

class Page1State extends State<Page1> {
  late AudioPlayerProvider audioProvider;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      audioProvider = Provider.of<AudioPlayerProvider>(context, listen: false);
      await audioProvider.loadSongs();
    });
  }

  void _onSongTap(
    BuildContext context,
    AudioPlayerProvider provider,
    SongModel song,
  ) {
    if (provider.currentSong?.id != song.id) {
      provider.playSong(song);
    } else {
      Navigator.push(
        context,
        CupertinoPageRoute(
          fullscreenDialog: true,
          builder: (context) => NowPlaying(
            songModel: song,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final userPro = Provider.of<UserProvider>(context);
    return Scaffold(
      body: Consumer<AudioPlayerProvider>(
        builder: (context, provider, _) {
          final songs = provider.songs;
          const outerPadding = EdgeInsets.only(
            top: 100,
            left: 16,
            right: 16,
            bottom: 150,
          );

          if (userPro.isGrid) {
            return GridView.builder(
              padding: outerPadding,
              physics: const BouncingScrollPhysics(),
              itemCount: songs.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.72,
                crossAxisSpacing: 12,
                mainAxisSpacing: 14,
              ),
              itemBuilder: (context, index) {
                final song = songs[index];
                final isCurrent = provider.currentSong?.id == song.id;
                return _SongGridTile(
                  song: song,
                  isPlaying: isCurrent,
                  onTap: () => _onSongTap(context, provider, song),
                );
              },
            );
          }

          return ListView.separated(
            padding: outerPadding,
            physics: const BouncingScrollPhysics(),
            itemCount: songs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final song = songs[index];
              final isCurrent = provider.currentSong?.id == song.id;
              return _SongListRow(
                song: song,
                isPlaying: isCurrent,
                onTap: () => _onSongTap(context, provider, song),
              );
            },
          );
        },
      ),
    );
  }
}

class _SongGridTile extends StatelessWidget {
  const _SongGridTile({
    required this.song,
    required this.isPlaying,
    required this.onTap,
  });

  final SongModel song;
  final bool isPlaying;
  final VoidCallback onTap;

  String get _artist {
    final a = song.artist;
    if (a == null || a.trim().isEmpty) return 'Unknown artist';
    return a;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Material(
      color: cs.surfaceContainerLow,
      elevation: isPlaying ? 4 : 1,
      shadowColor: Colors.black.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isPlaying
                  ? mainColour.withValues(alpha: 0.65)
                  : cs.outlineVariant.withValues(alpha: 0.35),
              width: isPlaying ? 1.5 : 1,
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              QueryArtworkWidget(
                key: ValueKey(song.id),
                id: song.id,
                type: ArtworkType.AUDIO,
                keepOldArtwork: true,
                size: 320,
                artworkFit: BoxFit.cover,
                artworkBorder: BorderRadius.zero,
                nullArtworkWidget: ColoredBox(
                  color: cs.surfaceContainerHighest,
                  child: Icon(
                    Icons.music_note_rounded,
                    size: 48,
                    color: cs.onSurfaceVariant.withValues(alpha: 0.45),
                  ),
                ),
              ),
              if (isPlaying)
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          mainColour.withValues(alpha: 0.12),
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.35),
                        ],
                        stops: const [0.0, 0.45, 1.0],
                      ),
                    ),
                  ),
                ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(12, 20, 12, 12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.0),
                            Colors.black.withValues(alpha: 0.72),
                          ],
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isPlaying)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.graphic_eq_rounded,
                                    size: 16,
                                    color: mainColour,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'NOW PLAYING',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: mainColour,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          Text(
                            song.displayNameWOExt,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              height: 1.2,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _artist,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.white.withValues(alpha: 0.78),
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              if (isPlaying)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: mainColour,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SongListRow extends StatelessWidget {
  const _SongListRow({
    required this.song,
    required this.isPlaying,
    required this.onTap,
  });

  final SongModel song;
  final bool isPlaying;
  final VoidCallback onTap;

  String get _artist {
    final a = song.artist;
    if (a == null || a.trim().isEmpty) return 'Unknown artist';
    return a;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Material(
      color: isPlaying
          ? mainColour.withValues(alpha: 0.09)
          : cs.surfaceContainerLow,
      elevation: 0,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isPlaying
                  ? mainColour.withValues(alpha: 0.35)
                  : cs.outlineVariant.withValues(alpha: 0.4),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 58,
                    height: 58,
                    child: QueryArtworkWidget(
                      key: ValueKey('list_${song.id}'),
                      id: song.id,
                      type: ArtworkType.AUDIO,
                      keepOldArtwork: true,
                      size: 200,
                      artworkFit: BoxFit.cover,
                      nullArtworkWidget: ColoredBox(
                        color: cs.surfaceContainerHighest,
                        child: Icon(
                          Icons.music_note_rounded,
                          color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                          size: 28,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        song.displayNameWOExt,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.2,
                          color: isPlaying ? mainColour : cs.onSurface,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _artist,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (isPlaying)
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: mainColour.withValues(alpha: 0.18),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.graphic_eq_rounded,
                      color: mainColour,
                      size: 22,
                    ),
                  )
                else
                  Icon(
                    Icons.chevron_right_rounded,
                    color: cs.onSurfaceVariant.withValues(alpha: 0.35),
                    size: 26,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
