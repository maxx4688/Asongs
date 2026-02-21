import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:jobee_server/provider/audio_provider.dart';
import 'package:flutter/services.dart';
import 'package:jobee_server/theme/theme_data.dart';
import 'package:on_audio_query/on_audio_query.dart';
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
  late AudioPlayerProvider audioProvider;
  bool _isSeeking = false;
  double _seekValue = 0.0;
  bool _isSyncing = false;

  bool _isChangingVolume = false;
  double _localVolume = 1.0;

  void _showSpeedPitchSheet(AudioPlayerProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        double tempSpeed = provider.speed;
        double tempPitch = provider.pitch;
        return StatefulBuilder(
          builder: (context, setStateSheet) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Modify tune',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      CupertinoButton(
                        sizeStyle: CupertinoButtonSize.small,
                        color: Colors.white10,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        child: Text(
                          _isSyncing ? "Syncing" : "Sync",
                          style: TextStyle(
                            color: _isSyncing ? mainColour : null,
                            fontSize: 13,
                          ),
                        ),
                        onPressed: () {
                          setState(() {
                            _isSyncing = !_isSyncing;
                          });
                          Navigator.of(context).pop();
                        },
                      ),
                      TextButton(
                        onPressed: () {
                          provider.setSpeed(1.0);
                          provider.setPitch(1.0);
                          Navigator.of(context).pop();
                        },
                        child: const Text(
                          'Reset',
                          style: TextStyle(color: mainColour),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _isSyncing ? 'Speed & Pitch (${tempSpeed.toStringAsFixed(2)}x)' : 'Speed (${tempSpeed.toStringAsFixed(2)}x)',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  Slider(
                    value: tempSpeed,
                    min: 0.7,
                    max: 1.4,
                    divisions: 35,
                    activeColor: mainColour,
                    inactiveColor: Colors.white24,
                    onChanged: (v) {
                      // Snap to nearest 0.02x for a sticky effect
                      final snapped = (v / 0.02).round() * 0.02;
                      final clamped = snapped.clamp(0.7, 1.4);
                      setStateSheet(() => tempSpeed = clamped);
                      provider.setSpeed(clamped);
                      if (_isSyncing) {
                        final snapped = (v / 0.02).round() * 0.02;
                      final clamped = snapped.clamp(0.7, 1.4);
                      setStateSheet(() => tempPitch = clamped);
                      provider.setPitch(clamped);
                      }
                    },
                  ),
                  if (!_isSyncing)...[
                  const SizedBox(height: 8),
                  Text(
                    'Pitch (${tempPitch.toStringAsFixed(2)})',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  Slider(
                    value: tempPitch,
                    min: 0.7,
                    max: 1.4,
                    // 0.70–1.40 with steps of 0.02 => 35 divisions
                    divisions: 35,
                    activeColor: mainColour,
                    inactiveColor: Colors.white24,
                    onChanged: (v) {
                      // Snap to nearest 0.02 for pitch
                      final snapped = (v / 0.02).round() * 0.02;
                      final clamped = snapped.clamp(0.7, 1.4);
                      setStateSheet(() => tempPitch = clamped);
                      provider.setPitch(clamped);
                    },
                  ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      audioProvider = Provider.of<AudioPlayerProvider>(context, listen: false);
    });
  }

  @override
  Widget build(BuildContext context) {
    const tcolors = Colors.white38;
    return Scaffold(
        backgroundColor: Colors.black,
        body: GestureDetector(
          onVerticalDragEnd: (details) {
            final velocity = details.primaryVelocity ?? 0.0;
            final provider =
                Provider.of<AudioPlayerProvider>(context, listen: false);
            if (velocity < -300) {
              if (provider.hasNext) {
                provider.playNext();
                HapticFeedback.mediumImpact();
              }
            } else if (velocity > 300) {
              if (provider.hasPrevious) {
                provider.playPrevious();
                HapticFeedback.mediumImpact();
              }
            }
          },
          child: Stack(
            children: [
              SizedBox(
                width: double.infinity,
                height: MediaQuery.of(context).size.height * 0.6,
                child: Consumer<AudioPlayerProvider>(
                  builder: (context, provider, _) {
                    final song = provider.currentSong ?? widget.songModel;
                    return QueryArtworkWidget(
                      id: song.id,
                      type: ArtworkType.AUDIO,
                      artworkBorder: BorderRadius.circular(0),
                      keepOldArtwork: true,
                      size: 512,
                      artworkFit: BoxFit.cover,
                      quality: 100,
                      nullArtworkWidget: Container(
                        color: Colors.grey[300],
                        child: Icon(
                          Icons.music_note,
                          size: 48,
                          color: Colors.grey[700],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: MediaQuery.of(context).size.height * 0.25,
                  ),
                  Container(
                    height: MediaQuery.of(context).size.height * 0.3,
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    alignment: Alignment.bottomLeft,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withAlpha(2),
                          Colors.black38,
                          Colors.black54,
                          Colors.black87,
                          Colors.black,
                        ],
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Consumer<AudioPlayerProvider>(
                            builder: (context, provider, _) {
                              final song =
                                  provider.currentSong ?? widget.songModel;
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    song.displayNameWOExt,
                                    textAlign: TextAlign.left,
                                    maxLines: 2,
                                    overflow: TextOverflow.fade,
                                    style: const TextStyle(
                                      fontSize: 30,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    song.artist ?? 'Unknown artist',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      color: Colors.white54,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                        Consumer<AudioPlayerProvider>(
                          builder: (context, provider, _) {
                            final song = provider.currentSong ?? widget.songModel;
                            final isFav = provider.isFavourite(song.id);
                            return IconButton(
                              icon: Icon(
                                isFav ? Icons.favorite : Icons.favorite_border,
                                color: isFav ? mainColour : Colors.white54,
                                size: 28,
                              ),
                              onPressed: () => provider.toggleFavourite(song.id),
                            );
                          },
                        ),
                        CupertinoButton(
                          color: Colors.white10,
                          padding: const EdgeInsets.all(8),
                          borderRadius: BorderRadius.circular(50),
                          child: Consumer<AudioPlayerProvider>(
                            builder: (context, provider, _) => Icon(
                              provider.isPlaying
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              size: 40,
                              color: Colors.white,
                            ),
                          ),
                          onPressed: () {
                            audioProvider.playPause();
                          },
                        ),
                      ],
                    ),
                  ),
                  Consumer<AudioPlayerProvider>(
                    builder: (context, provider, _) => Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        const SizedBox(width: 15),
                        CupertinoButton(
                          color: provider.isLoopAll
                              ? mainColour.withAlpha(50)
                              : Colors.white12,
                          padding: const EdgeInsets.all(7),
                          sizeStyle: CupertinoButtonSize.small,
                          child: Icon(
                            provider.isRepeatOne
                                ? CupertinoIcons.repeat_1
                                : CupertinoIcons.repeat,
                            color: (provider.isRepeatOne || provider.isLoopAll)
                                ? mainColour
                                : Colors.white38,
                          ),
                          onPressed: () => provider.toggleRepeat(),
                        ),
                        const SizedBox(width: 12),
                        CupertinoButton(
                          padding: const EdgeInsets.all(8),
                          minSize: 0,
                          color: Colors.white12,
                          borderRadius: BorderRadius.circular(50),
                          child: const Icon(
                            CupertinoIcons.music_note,
                            color: Colors.white38,
                          ),
                          onPressed: () => _showSpeedPitchSheet(provider),
                        ),
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 15),
                          width: 1,
                          height: 20,
                          color: Colors.white24,
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: mainColour.withAlpha(50),
                            border: Border.all(color: mainColour.withAlpha(50)),
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: Row(
                            children: [
                              CupertinoButton(
                                sizeStyle: CupertinoButtonSize.small,
                                onPressed: provider.hasPrevious
                                    ? () => provider.playPrevious()
                                    : null,
                                child: Icon(
                                  Icons.skip_previous,
                                  color: provider.hasPrevious
                                      ? Colors.white
                                      : Colors.white38,
                                ),
                              ),
                              CupertinoButton(
                                sizeStyle: CupertinoButtonSize.small,
                                onPressed: provider.hasNext
                                    ? () => provider.playNext()
                                    : null,
                                child: Icon(
                                  Icons.skip_next,
                                  color: provider.hasNext
                                      ? Colors.white
                                      : Colors.white38,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      Consumer<AudioPlayerProvider>(
                        builder: (context, provider, _) {
                          final duration = provider.duration;
                          final position = provider.position;
                          final max = duration.inMilliseconds.toDouble();
                          final displayPosition = _isSeeking
                              ? Duration(milliseconds: _seekValue.round())
                              : position;

                          return Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      provider.formatDuration(displayPosition),
                                      style: const TextStyle(
                                        color: tcolors,
                                      ),
                                    ),
                                    Text(
                                      provider
                                          .formatDuration(provider.duration),
                                      style: const TextStyle(
                                        color: tcolors,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Slider(
                                activeColor: Colors.white30,
                                thumbColor: Colors.white,
                                inactiveColor: Colors.white10,
                                overlayColor: const WidgetStatePropertyAll(
                                  Colors.white30,
                                ),
                                min: 0.0,
                                max: max > 0 ? max : 1.0,
                                value: _isSeeking
                                    ? _seekValue.clamp(0.0, max > 0 ? max : 1.0)
                                    : (max > 0
                                        ? position.inMilliseconds.toDouble()
                                        : 0.0),
                                onChangeStart: (v) {
                                  setState(() {
                                    _isSeeking = true;
                                    _seekValue = v;
                                  });
                                },
                                onChanged: (double v) {
                                  setState(() {
                                    _seekValue = v;
                                  });
                                },
                                onChangeEnd: (double v) {
                                  provider.seekTo(
                                      Duration(milliseconds: v.round()));
                                  setState(() {
                                    _isSeeking = false;
                                  });
                                },
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      Consumer<AudioPlayerProvider>(
                        builder: (context, provider, _) {
                          final vol = _isChangingVolume
                              ? _localVolume
                              : provider.volume.clamp(0.0, 1.0);
                          return Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 25.0),
                            child: Row(
                              children: [
                                Icon(
                                  vol == 0
                                      ? CupertinoIcons.volume_off
                                      : CupertinoIcons.volume_down,
                                  color: Colors.white70,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: CupertinoSlider(
                                    activeColor: Colors.white60,
                                    thumbColor: mainColour,
                                    min: 0.0,
                                    max: 1.0,
                                    value: vol,
                                    onChangeStart: (v) {
                                      setState(() {
                                        _isChangingVolume = true;
                                        _localVolume = v;
                                      });
                                    },
                                    onChanged: (v) {
                                      setState(() {
                                        _localVolume = v;
                                      });
                                      // Apply volume changes in real time while dragging
                                      provider.setVolume(v);
                                    },
                                    onChangeEnd: (v) {
                                      setState(() {
                                        _isChangingVolume = false;
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(
                                  CupertinoIcons.volume_up,
                                  color: Colors.white70,
                                  size: 20,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ));
  }
}
