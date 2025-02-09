import 'package:flutter/material.dart';
import 'package:jobee_server/home_pages/page1.dart';
import 'package:jobee_server/home_pages/page2.dart';
import 'package:jobee_server/now_playing.dart';
import 'package:jobee_server/provider/audio_provider.dart';
import 'package:jobee_server/theme/theme_data.dart';
import 'package:jobee_server/theme/theme_provider.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (context) => ThemeProvider()),
      ChangeNotifierProvider(create: (context) => AudioPlayerProvider())
    ],
    child: const MyApp(),
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
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
    final getTheme = Provider.of<ThemeProvider>(context);
    final audioData = Provider.of<AudioPlayerProvider>(context);
    final tcolors = Theme.of(context).brightness == Brightness.light
        ? Colors.black38
        : Colors.white38;
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
                      const Text(
                        'Hey ash.',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: mainColour,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          getTheme.toggleTheme();
                        },
                        child: Icon(
                          Theme.of(context).brightness == Brightness.light
                              ? Icons.toggle_off
                              : Icons.toggle_on,
                          color: mainColour,
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomSheet: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const NowPlaying(),
            ),
          );
        },
        child: Hero(
          tag: 'song',
          child: AnimatedOpacity(
            opacity: audioData.songName == "Song Name" ? 0.0 : 1.0,
            duration: const Duration(milliseconds: 200),
            child: Container(
              padding: const EdgeInsets.only(right: 10.0, left: 10),
              height: 80,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    elevation: 5,
                    child: const SizedBox(
                      height: 60,
                      width: 60,
                    ),
                  ),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Material(
                          child: Text(
                            audioData.songName,
                            maxLines: 2,
                            overflow: TextOverflow.fade,
                            style: TextStyle(
                              color: tcolors,
                            ),
                          ),
                        ),
                        Material(
                          child: Text(
                            "${audioData.currentPosition.inMinutes}:${(audioData.currentPosition.inSeconds % 60).toString().padLeft(2, '0')} / ${audioData.totalDuration.inMinutes}:${(audioData.totalDuration.inSeconds % 60).toString().padLeft(2, '0')}"
                                .toString()
                                .padLeft(2, '0'),
                            style: const TextStyle(
                              color: mainColour,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    child: Icon(
                      audioData.isPlaying == false
                          ? Icons.play_circle
                          : Icons.pause_circle,
                      color: mainColour,
                      size: 30,
                    ),
                    onTap: () {
                      audioData.playSong();
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
