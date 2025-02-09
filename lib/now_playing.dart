import 'package:flutter/material.dart';
import 'package:jobee_server/provider/audio_provider.dart';
import 'package:jobee_server/theme/theme_data.dart';
import 'package:provider/provider.dart';

class NowPlaying extends StatefulWidget {
  const NowPlaying({
    super.key,
  });

  @override
  State<NowPlaying> createState() => _NowPlayingState();
}

class _NowPlayingState extends State<NowPlaying> {
  @override
  Widget build(BuildContext context) {
    final tcolors = Theme.of(context).brightness == Brightness.light
        ? Colors.black38
        : Colors.white38;

    final audioFile = Provider.of<AudioPlayerProvider>(context);
    return Hero(
      tag: 'song',
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height / 3,
                  width: MediaQuery.of(context).size.width / 1.2,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedContainer(
                        curve: Curves.easeInOutQuart,
                        height: audioFile.isPlaying
                            ? MediaQuery.of(context).size.height / 3
                            : MediaQuery.of(context).size.height / 3.5,
                        width: audioFile.isPlaying
                            ? MediaQuery.of(context).size.width / 1.2
                            : MediaQuery.of(context).size.width / 1.3,
                        duration: const Duration(milliseconds: 300),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              blurRadius: audioFile.isPlaying ? 30 : 5,
                              color: Colors.black26,
                              offset:
                                  Offset(0.0, audioFile.isPlaying ? 10.0 : 5.0),
                            )
                          ],
                        ),
                        child: Icon(
                          Icons.music_note,
                          size: 50,
                          color: audioFile.isPlaying ? mainColour : null,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  audioFile.songName,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.fade,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      onPressed: () {
                        // audioFile.toggleRepeat();
                      },
                      icon: const Icon(
                        Icons.favorite_rounded,
                        color: mainColour,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        audioFile.toggleRepeat();
                      },
                      icon: Icon(
                        audioFile.repeat == false
                            ? Icons.looks_one_outlined
                            : Icons.looks_one,
                        color: audioFile.repeat == false ? tcolors : mainColour,
                      ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "${audioFile.currentPosition.inMinutes}:${(audioFile.currentPosition.inSeconds % 60).toString().padLeft(2, '0')}",
                          style: TextStyle(
                            fontSize: 16,
                            color: tcolors,
                          ),
                        ),
                        Text(
                          "${audioFile.totalDuration.inMinutes}:${(audioFile.totalDuration.inSeconds % 60).toString().padLeft(2, '0')}"
                              .toString()
                              .padLeft(2, '0'),
                          style: TextStyle(
                            fontSize: 16,
                            color: tcolors,
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      thumbColor: mainColour,
                      value: audioFile.currentPosition.inSeconds.toDouble(),
                      min: 0,
                      max: audioFile.totalDuration.inSeconds.toDouble(),
                      onChanged: (double value) {
                        audioFile.seekTo(Duration(seconds: value.toInt()));
                      },
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      onPressed: () {
                        audioFile.playPreviousSong();
                        // audioFile.play();
                      },
                      icon: const Icon(
                        Icons.skip_previous,
                      ),
                    ),
                    InkResponse(
                      splashColor: mainColour,
                      onTap: () {
                        audioFile.playSong();
                      },
                      child: Container(
                        alignment: Alignment.center,
                        height: 50,
                        width: 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color:
                              Theme.of(context).brightness == Brightness.light
                                  ? Colors.white
                                  : Colors.black,
                        ),
                        child: Icon(
                          audioFile.isPlaying == false
                              ? Icons.play_arrow
                              : Icons.pause,
                          color: mainColour,
                          size: 40,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        audioFile.playNextSong();
                        // audioFile.play();
                      },
                      icon: const Icon(
                        Icons.skip_next,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
