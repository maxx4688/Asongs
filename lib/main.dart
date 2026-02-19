import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:jobee_server/home_pages/page1.dart';
import 'package:jobee_server/home_pages/page2.dart';
import 'package:jobee_server/home_pages/settings.dart';
import 'package:jobee_server/now_playing.dart';
import 'package:jobee_server/provider/user_provider.dart';
import 'package:jobee_server/ux/boarding_page.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:jobee_server/provider/audio_provider.dart';
import 'package:jobee_server/theme/theme_data.dart';
import 'package:jobee_server/theme/theme_provider.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.asongs.playback',
    androidNotificationChannelName: 'Asongs playback',
    androidNotificationOngoing: true,
    androidNotificationIcon: 'mipmap/ic_launcher',
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
        ChangeNotifierProvider(create: (context) => AudioPlayerProvider()),
        ChangeNotifierProvider(create: (context) => UserProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final userPro = Provider.of<UserProvider>(context);
    return MaterialApp(
      title: 'Asongs',
      theme: Provider.of<ThemeProvider>(context).themeData,
      home: userPro.isFirst ? const BoardingPage() : const HomePage(),
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
          Selector<AudioPlayerProvider, bool>(
            selector: (_, p) => p.currentSong != null,
            builder: (context, hasSong, child) {
              if (!hasSong) return const SizedBox();
              return TweenAnimationBuilder<Offset>(
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
                child: child,
              );
            },
            child: const _MiniPlayer(),
          ),
        ],
      ),
    );
  }
}

class _MiniPlayer extends StatelessWidget {
  const _MiniPlayer();

  @override
  Widget build(BuildContext context) {
    final userPro = Provider.of<UserProvider>(context);

    return Padding(
      padding: const EdgeInsets.only(
        bottom: 30.0,
        left: 25,
        right: 25,
      ),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Consumer<AudioPlayerProvider>(
          builder: (context, audioData, _) {
            final currentSong = audioData.currentSong;
            if (currentSong == null) return const SizedBox();

            return GestureDetector(
              onTap: () {
                userPro.ios == true
                    ? showCupertinoSheet(
                        context: context,
                        pageBuilder: (context) {
                          return NowPlaying(
                            songModel: currentSong,
                          );
                        },
                      )
                    : Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => NowPlaying(
                            songModel: currentSong,
                          ),
                        ),
                      );
              },
              child: Container(
                clipBehavior: Clip.hardEdge,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                height: 80,
                decoration: BoxDecoration(
                  color: userPro.isGrid
                      ? Colors.white12
                      : Colors.black.withAlpha(20),
                  borderRadius: BorderRadius.circular(20),
                  border: userPro.isGrid
                      ? null
                      : Border.all(
                          color: Theme.of(context).brightness ==
                                  Brightness.light
                              ? Colors.black38
                              : Colors.white30,
                          width: 0.5,
                        ),
                ),
                child: BackdropFilter(
                  filter: userPro.isGrid
                      ? ImageFilter.blur(sigmaX: 4, sigmaY: 4)
                      : ImageFilter.blur(sigmaX: 2.5, sigmaY: 2.5),
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
                          child: QueryArtworkWidget(
                            key: ValueKey(currentSong.id),
                            id: currentSong.id,
                            type: ArtworkType.AUDIO,
                            keepOldArtwork: true,
                            size: 120,
                            artworkFit: BoxFit.cover,
                            artworkBorder: BorderRadius.circular(10),
                            nullArtworkWidget: Container(
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(5),
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
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Material(
                              color: Colors.transparent,
                              child: SizedBox.shrink(),
                            ),
                            Material(
                              color: Colors.transparent,
                              child: Text(
                                currentSong.displayNameWOExt,
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
            );
          },
        ),
      ),
    );
  }
}
