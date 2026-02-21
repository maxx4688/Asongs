import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:jobee_server/now_playing.dart';
import 'package:jobee_server/provider/audio_provider.dart';
import 'package:jobee_server/theme/theme_data.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:provider/provider.dart';

class Page2 extends StatefulWidget {
  const Page2({super.key});

  @override
  State<Page2> createState() => _Page2State();
}

class _Page2State extends State<Page2> {
  @override
  Widget build(BuildContext context) {
    return Consumer<AudioPlayerProvider>(
      builder: (context, provider, _) {
        final recent = provider.recentSongs;
        final favourites = provider.favouriteSongs;
        final upNext = provider.upNextSongs;
        final sleepRemaining = provider.sleepTimerRemaining;
        final sleepActive = provider.isSleepTimerActive;

        return CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.only(top: 100, left: 16, right: 16, bottom: 100),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _sectionTitle('Sleep timer', Icons.nightlight_round),
                  const SizedBox(height: 8),
                  _SleepTimerCard(
                    isActive: sleepActive,
                    remaining: sleepRemaining,
                    currentDuration: provider.duration,
                    currentPosition: provider.position,
                    onStart: provider.startSleepTimer,
                    onCancel: provider.cancelSleepTimer,
                  ),
                  const SizedBox(height: 28),
                  _sectionTitle('Recently played', Icons.history_rounded),
                  const SizedBox(height: 8),
                  if (recent.isEmpty)
                    _emptyState('No recent plays yet')
                  else
                    _SongStrip(
                      songs: recent,
                      currentSongId: provider.currentSong?.id,
                      onTap: (s) {
                        provider.playSong(s);
                        Navigator.push(
                          context,
                          CupertinoPageRoute(
                            fullscreenDialog: true,
                            builder: (_) => NowPlaying(songModel: s),
                          ),
                        );
                      },
                    ),
                  const SizedBox(height: 28),
                  _sectionTitle('Favourites', Icons.favorite_rounded),
                  const SizedBox(height: 8),
                  if (favourites.isEmpty)
                    _emptyState('Like songs from your library to see them here')
                  else
                    _SongList(
                      songs: favourites,
                      currentSongId: provider.currentSong?.id,
                      isFavourite: true,
                      onTap: (s) {
                        provider.playSong(s);
                        Navigator.push(
                          context,
                          CupertinoPageRoute(
                            fullscreenDialog: true,
                            builder: (_) => NowPlaying(songModel: s),
                          ),
                        );
                      },
                      onToggleFavourite: (s) => provider.toggleFavourite(s.id),
                    ),
                  const SizedBox(height: 28),
                  _sectionTitle('Up next', Icons.queue_music_rounded),
                  const SizedBox(height: 8),
                  if (upNext.isEmpty)
                    _emptyState('Nothing in the queue')
                  else
                    _SongList(
                      songs: upNext,
                      currentSongId: provider.currentSong?.id,
                      showIndex: true,
                      onTap: (s) {
                        provider.playSong(s);
                        Navigator.push(
                          context,
                          CupertinoPageRoute(
                            fullscreenDialog: true,
                            builder: (_) => NowPlaying(songModel: s),
                          ),
                        );
                      },
                    ),
                ]),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _sectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 22, color: mainColour),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _emptyState(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: Text(
          message,
          style: TextStyle(
            color: Colors.grey.shade500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

class _SleepTimerCard extends StatelessWidget {
  const _SleepTimerCard({
    required this.isActive,
    required this.remaining,
    required this.currentDuration,
    required this.currentPosition,
    required this.onStart,
    required this.onCancel,
  });

  final bool isActive;
  final Duration? remaining;
  final Duration currentDuration;
  final Duration currentPosition;
  final void Function(Duration) onStart;
  final void Function() onCancel;

  static String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final presets = [
      (const Duration(minutes: 15), '15 min'),
      (const Duration(minutes: 30), '30 min'),
      (const Duration(minutes: 45), '45 min'),
      (const Duration(hours: 1), '1 hr'),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.white.withOpacity(0.06)
            : Colors.black.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: mainColour.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isActive && remaining != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.timer_outlined, color: mainColour, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Stopping in ${_formatDuration(remaining!)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: onCancel,
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ] else ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ...presets.map((e) => ActionChip(
                      label: Text(e.$2),
                      onPressed: () => onStart(e.$1),
                      backgroundColor: mainColour.withOpacity(0.12),
                      side: BorderSide(color: mainColour.withOpacity(0.4)),
                    )),
                ActionChip(
                  label: const Text('End of track'),
                  onPressed: () {
                    final left = currentDuration - currentPosition;
                    if (left.inSeconds > 0) onStart(left);
                  },
                  backgroundColor: mainColour.withOpacity(0.12),
                  side: BorderSide(color: mainColour.withOpacity(0.4)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _SongStrip extends StatelessWidget {
  const _SongStrip({
    required this.songs,
    required this.currentSongId,
    required this.onTap,
  });

  final List<SongModel> songs;
  final int? currentSongId;
  final void Function(SongModel) onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: songs.length,
        itemBuilder: (context, index) {
          final s = songs[index];
          final isCurrent = currentSongId == s.id;
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: InkWell(
              onTap: () => onTap(s),
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 100,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        width: 72,
                        height: 72,
                        child: QueryArtworkWidget(
                          key: ValueKey(s.id),
                          id: s.id,
                          type: ArtworkType.AUDIO,
                          keepOldArtwork: true,
                          size: 144,
                          artworkFit: BoxFit.cover,
                          nullArtworkWidget: Container(
                            color: Colors.grey.shade700,
                            child: const Icon(Icons.music_note, color: Colors.white54),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      s.displayNameWOExt,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: isCurrent ? mainColour : null,
                        fontWeight: isCurrent ? FontWeight.w600 : null,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SongList extends StatelessWidget {
  const _SongList({
    required this.songs,
    required this.currentSongId,
    required this.onTap,
    this.showIndex = false,
    this.isFavourite = false,
    this.onToggleFavourite,
  });

  final List<SongModel> songs;
  final int? currentSongId;
  final void Function(SongModel) onTap;
  final bool showIndex;
  final bool isFavourite;
  final void Function(SongModel s)? onToggleFavourite;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: songs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 4),
      itemBuilder: (context, index) {
        final s = songs[index];
        final isCurrent = currentSongId == s.id;
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          leading: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showIndex)
                SizedBox(
                  width: 24,
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 13,
                    ),
                  ),
                ),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: QueryArtworkWidget(
                    key: ValueKey(s.id),
                    id: s.id,
                    type: ArtworkType.AUDIO,
                    keepOldArtwork: true,
                    size: 96,
                    artworkFit: BoxFit.cover,
                    nullArtworkWidget: Container(
                      color: Colors.grey.shade700,
                      child: const Icon(Icons.music_note, color: Colors.white54),
                    ),
                  ),
                ),
              ),
            ],
          ),
          title: Text(
            s.displayNameWOExt,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isCurrent ? mainColour : null,
              fontWeight: isCurrent ? FontWeight.w600 : null,
              fontSize: 14,
            ),
          ),
          subtitle: Text(
            s.artist ?? 'Unknown',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
          ),
          trailing: isFavourite
              ? IconButton(
                  icon: Icon(
                    Icons.favorite,
                    color: mainColour,
                    size: 22,
                  ),
                  onPressed: onToggleFavourite != null ? () => onToggleFavourite!(s) : null,
                )
              : (isCurrent
                  ? const Icon(Icons.graphic_eq_rounded, color: mainColour, size: 22)
                  : null),
          onTap: () => onTap(s),
        );
      },
    );
  }
}
