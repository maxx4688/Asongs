import 'package:flutter/material.dart';
import 'package:jobee_server/now_playing.dart';
import 'package:jobee_server/provider/audio_provider.dart';
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
    return Scaffold(
      body: Consumer<AudioPlayerProvider>(
        builder: (context, provider, _) {
          final songs = provider.songs;
          return ListView.builder(
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
