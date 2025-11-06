import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:jobee_server/home_pages/page1.dart';
import 'package:jobee_server/home_pages/page2.dart';
import 'package:jobee_server/home_pages/settings.dart';
import 'package:jobee_server/now_playing.dart';
import 'package:jobee_server/provider/user_provider.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:jobee_server/provider/audio_provider.dart';
import 'package:jobee_server/theme/theme_data.dart';
import 'package:jobee_server/theme/theme_provider.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (context) => ThemeProvider()),
      ChangeNotifierProvider(create: (context) => AudioPlayerProvider()),
      ChangeNotifierProvider(create: (context) => UserProvider()),
    ],
    child: const MyApp(),
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Asongs',
      theme: Provider.of<ThemeProvider>(context).themeData,
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    final audioData = Provider.of<AudioPlayerProvider>(context);
    final userPro = Provider.of<UserProvider>(context);
    return Scaffold(
      body: Stack(
        children: [
          PageView(
            physics: const BouncingScrollPhysics(),
            children: const [
              Page1(),
              Page2(),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 40.0, left: 10, right: 10),
            child: Card(
              shadowColor: Colors.black38,
              elevation: 20,
              child: SizedBox(
                height: 50,
                width: double.infinity,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Hey ${userPro.username}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: mainColour,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SettingsPage(),
                            ),
                          );
                        },
                        child: const Icon(
                          CupertinoIcons.gear,
                          color: mainColour,
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
          audioData.currentSong == null
              ? const SizedBox()
              : TweenAnimationBuilder<Offset>(
                  tween: Tween(
                    begin: const Offset(0, 1),
                    end: const Offset(0, 0),
                  ),
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOutCubic,
                  builder: (context, offset, child) {
                    return Transform.translate(
                      offset: Offset(0, offset.dy * 80),
                      child: child,
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(
                      bottom: 30.0,
                      left: 25,
                      right: 25,
                    ),
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: GestureDetector(
                        onTap: () {
                          if (audioData.currentSong != null) {
                            userPro.ios == true
                                ? showCupertinoSheet(
                                    context: context,
                                    pageBuilder: (context) {
                                      return NowPlaying(
                                        songModel: audioData.currentSong!,
                                      );
                                    },
                                  )
                                : Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => NowPlaying(
                                        songModel: audioData.currentSong!,
                                      ),
                                    ),
                                  );
                          }
                        },
                        child: Container(
                          clipBehavior: Clip.hardEdge,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.black.withAlpha(20),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Theme.of(context).brightness ==
                                      Brightness.light
                                  ? Colors.black38
                                  : Colors.white30,
                              width: 0.5,
                            ),
                          ),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 2.5, sigmaY: 2.5),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Card(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  elevation: 5,
                                  child: SizedBox(
                                    height: 60,
                                    width: 60,
                                    child: audioData.currentSong == null
                                        ? const Icon(Icons.music_note)
                                        : QueryArtworkWidget(
                                            key: ValueKey(
                                                audioData.currentSong!.id),
                                            id: audioData.currentSong!.id,
                                            type: ArtworkType.AUDIO,
                                            keepOldArtwork: true,
                                            // request slightly larger artwork for bottom sheet
                                            size: 120,
                                            artworkFit: BoxFit.cover,
                                            artworkBorder:
                                                BorderRadius.circular(10),
                                            nullArtworkWidget: Container(
                                              decoration: BoxDecoration(
                                                color: Colors.grey[300],
                                                borderRadius:
                                                    BorderRadius.circular(5),
                                              ),
                                              child: Icon(
                                                Icons.music_note,
                                                color: Colors.grey[700],
                                              ),
                                            ),
                                          ),
                                  ),
                                ),
                                Expanded(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Material(
                                        color: Colors.transparent,
                                        child: Text(
                                          audioData.currentSong
                                                  ?.displayNameWOExt ??
                                              '',
                                          maxLines: 2,
                                          overflow: TextOverflow.fade,
                                        ),
                                      ),
                                      Material(
                                        color: Colors.transparent,
                                        child: Text(
                                          "${audioData.formatDuration(audioData.position)} / ${audioData.formatDuration(audioData.duration)}",
                                          style: const TextStyle(
                                            color: mainColour,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                CupertinoButton(
                                  padding: EdgeInsets.zero,
                                  child: Icon(
                                    !audioData.isPlaying
                                        ? Icons.play_circle_fill_rounded
                                        : Icons.pause_circle,
                                    color: mainColour,
                                    size: 30,
                                  ),
                                  onPressed: () => audioData.playPause(),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}
