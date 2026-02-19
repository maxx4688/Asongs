import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:jobee_server/main.dart';
import 'package:jobee_server/provider/audio_provider.dart';
import 'package:jobee_server/provider/user_provider.dart';
import 'package:jobee_server/theme/theme_data.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

class PermPage extends StatefulWidget {
  const PermPage({super.key});

  @override
  State<PermPage> createState() => _PermPageState();
}

class _PermPageState extends State<PermPage> {
  bool allowed = false;
  @override
  Widget build(BuildContext context) {
    final audioProvider =
        Provider.of<AudioPlayerProvider>(context, listen: false);
    final userPro = Provider.of<UserProvider>(context);
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.file_present_rounded,
              size: 100,
              color: Colors.grey.withAlpha(100),
            ),
            const SizedBox(
              height: 10,
            ),
            const Text(
              "Permission",
              style: TextStyle(
                fontFamily: 'poppins',
                fontSize: 25,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(
              height: 50,
            ),
            Divider(
              color: Colors.grey.withAlpha(100),
              indent: 20,
              endIndent: 20,
              height: 1,
            ),
            ListTile(
              leading: Icon(
                Icons.audio_file_rounded,
                color: allowed ? mainColour : Colors.grey.withAlpha(100),
              ),
              title: const Text(
                "Audio Permission",
              ),
              subtitle: Text(
                allowed
                    ? "Permission Allowed"
                    : "Allow the app to access your audio files",
                style: const TextStyle(
                  color: Colors.grey,
                ),
              ),
            ),
            Divider(
              color: Colors.grey.withAlpha(100),
              height: 1,
              indent: 20,
              endIndent: 20,
            ),
            const SizedBox(
              height: 50,
            ),
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.9,
              height: 50,
              child: CupertinoButton(
                color: Theme.of(context).brightness == Brightness.light
                    ? Colors.black12
                    : Colors.white10,
                sizeStyle: CupertinoButtonSize.medium,
                child: Text(
                  !allowed ? "Request Audio Permission" : "Continue",
                  style: const TextStyle(
                    fontFamily: 'poppins',
                    color: Colors.grey,
                  ),
                ),
                onPressed: () async {
                  if (!allowed) {
                    final status = await Permission.audio.request();
                    if (status.isGranted) {
                      setState(() {
                        allowed = true;
                      });
                      await audioProvider.loadSongs();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          backgroundColor: Colors.black,
                          content: Text(
                            "Audio permission denied",
                            style: TextStyle(
                              color: Colors.white,
                            ),
                          ),
                        ),
                      );
                    }
                  } else {
                    userPro.setIsFirst(false);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HomePage(),
                      ),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
