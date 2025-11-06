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
  // local drag state for seek slider to avoid heavy frequent provider calls
  bool _isSeeking = false;
  double _seekValue = 0.0;

  // local drag state for volume slider to avoid lag and frequent system calls
  bool _isChangingVolume = false;
  double _localVolume = 1.0;

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
                          Colors.black54,
                          Colors.black87,
                          Colors.black,
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
                          color: Colors.white12,
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
                                    },
                                    onChangeEnd: (v) async {
                                      await provider.setVolume(v);
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
