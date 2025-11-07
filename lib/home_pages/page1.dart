import 'dart:ui';

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

  @override
  Widget build(BuildContext context) {
    final userPro = Provider.of<UserProvider>(context);
    return Scaffold(
      body: Consumer<AudioPlayerProvider>(
        builder: (context, provider, _) {
          final songs = provider.songs;
          return userPro.isGrid
              ? GridView.builder(
                  padding: const EdgeInsets.only(
                    top: 100,
                    left: 15,
                    right: 15,
                  ),
                  itemCount: songs.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                  ),
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () {
                        if (provider.currentSong?.id != songs[index].id) {
                          provider.playSong(songs[index]);
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => NowPlaying(
                                songModel: songs[index],
                              ),
                            ),
                          );
                        }
                      },
                      child: Card(
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadiusGeometry.circular(25)),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Stack(
                            children: [
                              SizedBox(
                                height: double.infinity,
                                width: double.infinity,
                                child: QueryArtworkWidget(
                                  key: ValueKey(songs[index].id),
                                  id: songs[index].id,
                                  type: ArtworkType.AUDIO,
                                  keepOldArtwork: true,
                                  size: 512,
                                  artworkFit: BoxFit.cover,
                                  quality: 100,
                                  artworkBorder: BorderRadius.circular(18),
                                  nullArtworkWidget: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.grey[300],
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    height: 50,
                                    width: 50,
                                    child: Icon(
                                      Icons.music_note,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ),
                              ),
                              Container(
                                alignment: Alignment.bottomLeft,
                                width: double.infinity,
                                padding: const EdgeInsetsDirectional.symmetric(
                                  horizontal: 10,
                                  vertical: 7,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(18),
                                  gradient: LinearGradient(
                                    begin: Alignment.center,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.white.withAlpha(1),
                                      Colors.black38,
                                      Colors.black,
                                    ],
                                  ),
                                ),
                                child: Text(
                                  songs[index].displayNameWOExt,
                                  maxLines: 1,
                                  overflow: TextOverflow.fade,
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              if (provider.currentSong?.id == songs[index].id)
                                Container(
                                    alignment: Alignment.bottomLeft,
                                    width: double.infinity,
                                    clipBehavior: Clip.hardEdge,
                                    padding:
                                        const EdgeInsetsDirectional.symmetric(
                                      horizontal: 10,
                                      vertical: 7,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(18),
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Colors.white.withAlpha(1),
                                          Colors.black38,
                                          Colors.black,
                                        ],
                                      ),
                                    ),
                                    child: BackdropFilter(
                                      filter: ImageFilter.blur(
                                        sigmaX: 2.5,
                                        sigmaY: 2.5,
                                      ),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            "Playing..",
                                            maxLines: 1,
                                            overflow: TextOverflow.fade,
                                            style: TextStyle(
                                              color: mainColour,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 20,
                                            ),
                                          ),
                                          Text(
                                            songs[index].displayNameWOExt,
                                            maxLines: 1,
                                            overflow: TextOverflow.fade,
                                            style: const TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                          Text(
                                            songs[index].artist!,
                                            maxLines: 1,
                                            overflow: TextOverflow.fade,
                                            style: const TextStyle(
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(
                    top: 100,
                    left: 15,
                    right: 15,
                    bottom: 60,
                  ),
                  itemCount: songs.length,
                  itemBuilder: (context, index) {
                    return Card(
                      shadowColor: Colors.black26,
                      elevation: 15,
                      child: ListTile(
                        leading: QueryArtworkWidget(
                          key: ValueKey(songs[index].id),
                          id: songs[index].id,
                          type: ArtworkType.AUDIO,
                          keepOldArtwork: true,
                          artworkBorder: BorderRadius.circular(8),
                          nullArtworkWidget: Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(5),
                            ),
                            height: 50,
                            width: 50,
                            child: Icon(
                              Icons.music_note,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                        title: Text(
                          songs[index].displayNameWOExt,
                          maxLines: 2,
                          overflow: TextOverflow.fade,
                          style: const TextStyle(),
                        ),
                        subtitle: Text(
                          songs[index].artist!,
                          style: const TextStyle(
                            color: Colors.grey,
                          ),
                        ),
                        onTap: () {
                          if (provider.currentSong?.id != songs[index].id) {
                            provider.playSong(songs[index]);
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => NowPlaying(
                                  songModel: songs[index],
                                ),
                              ),
                            );
                          }
                        },
                      ),
                    );
                  },
                );
        },
      ),
    );
  }
}
