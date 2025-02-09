import 'dart:io';
import 'package:flutter/material.dart';
import 'package:jobee_server/now_playing.dart';
import 'package:jobee_server/provider/audio_provider.dart';
import 'package:jobee_server/theme/theme_data.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

class Page1 extends StatefulWidget {
  const Page1({super.key});

  @override
  State<Page1> createState() => Page1State();
}

class Page1State extends State<Page1> {
  List<File> audioFiles = [];

  @override
  void initState() {
    requestStoragePermission();
    super.initState();
  }

  Future<void> requestStoragePermission() async {
    if (await Permission.storage.isGranted ||
        await Permission.mediaLibrary.isGranted) {
      print("Storage permission already granted");
      loadAudioFiles();
      return;
    }

    if (await Permission.storage.status.isDenied ||
        await Permission.storage.status.isRestricted) {
      PermissionStatus status = await Permission.storage.request();

      if (status.isGranted) {
        print("Storage permission granted");
        loadAudioFiles();
      } else if (status.isPermanentlyDenied) {
        print(
            "Storage permission permanently denied. Redirecting to settings.");
        openAppSettings();
      } else {
        print("Storage permission denied");
      }
    }
  }

  Future<List<File>> getAudioFiles() async {
    List<File> audioFiles = [];

    Directory directory =
        Directory("/storage/emulated/0/snaptube/download/SnapTube Audio");

    if (directory.existsSync()) {
      List<FileSystemEntity> files = directory.listSync(recursive: true);
      for (var file in files) {
        if (file is File &&
            (file.path.endsWith('.mp3') || file.path.endsWith('.wav'))) {
          audioFiles.add(file);
        }
      }
      audioFiles.sort(
          (a, b) => b.statSync().modified.compareTo(a.statSync().modified));
    }
    return audioFiles;
  }

  Future<void> loadAudioFiles() async {
    List<File> files = await getAudioFiles();
    setState(() {
      audioFiles = files;
    });
  }

  @override
  Widget build(BuildContext context) {
    final audioProvider = Provider.of<AudioPlayerProvider>(context);
    return Scaffold(
      body: audioFiles.isEmpty
          ? const Center(child: Text("No songs found"))
          : ListView.builder(
              padding: const EdgeInsets.only(
                top: 100,
                left: 10,
                right: 10,
                bottom: 60,
              ),
              itemCount: audioFiles.length,
              itemBuilder: (context, index) {
                return Card(
                  shadowColor: Colors.black26,
                  elevation: 15,
                  child: ListTile(
                    leading: Icon(
                      audioProvider.songName ==
                              audioFiles[index].path.split('/').last
                          ? Icons.music_note
                          : Icons.music_note_outlined,
                      color: audioProvider.songName ==
                              audioFiles[index].path.split('/').last
                          ? mainColour
                          : null,
                    ),
                    title: Text(
                      audioFiles[index].path.split('/').last,
                      maxLines: 2,
                      overflow: TextOverflow.fade,
                      style: TextStyle(
                        color: audioProvider.songName ==
                                audioFiles[index].path.split('/').last
                            ? mainColour
                            : null,
                      ),
                    ),
                    subtitle: const Text('song'),
                    onTap: () {
                      audioProvider.setAudioFile(audioFiles[index],
                          songs: audioFiles);
                      audioProvider.play();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const NowPlaying(),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
