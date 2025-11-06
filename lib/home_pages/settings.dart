import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jobee_server/provider/user_provider.dart';
import 'package:jobee_server/provider/audio_provider.dart';
import 'package:jobee_server/theme/theme_data.dart';
import 'package:jobee_server/theme/theme_provider.dart';
import 'package:provider/provider.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    final getTheme = Provider.of<ThemeProvider>(context);
    final userPro = Provider.of<UserProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Settings",
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          ListTile(
            onTap: () {
              getTheme.toggleTheme();
            },
            leading: Icon(
              Theme.of(context).brightness == Brightness.light
                  ? Icons.light
                  : Icons.light_outlined,
              color: mainColour,
            ),
            title: const Text("Theme"),
            trailing: Switch(
              activeColor: mainColour,
              inactiveThumbColor: Colors.black12,
              trackOutlineColor: const WidgetStatePropertyAll(Colors.black12),
              value: getTheme.isDarkMode,
              onChanged: (value) {
                getTheme.toggleTheme();
              },
            ),
          ),
          ListTile(
            onTap: () {
              userPro.toggleIos();
            },
            leading: Icon(
              userPro.ios ? Icons.cookie_rounded : Icons.cookie_outlined,
              color: mainColour,
            ),
            title: const Text("Animations"),
            trailing: Switch(
              activeColor: mainColour,
              inactiveThumbColor: Colors.black12,
              trackOutlineColor: const WidgetStatePropertyAll(Colors.black12),
              value: userPro.ios,
              onChanged: (value) {
                userPro.toggleIos();
              },
            ),
          ),
          ListTile(
            leading: const Icon(
              Icons.audio_file_outlined,
              color: mainColour,
            ),
            title: const Text('No ringtones'),
            trailing: Switch(
              activeColor: mainColour,
              inactiveThumbColor: Colors.black12,
              trackOutlineColor: const WidgetStatePropertyAll(Colors.black12),
              value: userPro.excludeShortSongs,
              onChanged: (value) async {
                await userPro.setExcludeShortSongs(value);
                try {
                  final audioProv =
                      Provider.of<AudioPlayerProvider>(context, listen: false);
                  await audioProv.loadSongs();
                } catch (_) {}
              },
            ),
          ),
          ListTile(
            onTap: () {
              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: const Text(
                      "Username",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: mainColour,
                      ),
                    ),
                    content: TextField(
                      cursorColor: mainColour,
                      decoration: const InputDecoration(
                        hintText: "Your username",
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: mainColour,
                          ),
                        ),
                      ),
                      onSubmitted: (value) {
                        if (value.isEmpty) {
                          HapticFeedback.mediumImpact();
                          Future.delayed(const Duration(milliseconds: 150), () {
                            HapticFeedback.mediumImpact();
                          });
                        } else {
                          userPro.setName(value);
                          Navigator.pop(context);
                        }
                      },
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: const Text(
                          "Close",
                          style: TextStyle(
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
            leading: const Icon(
              Icons.shield,
              color: mainColour,
            ),
            title: Text(userPro.username),
            subtitle: const Text(
              "Change your username",
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.code, color: mainColour),
            title: const Text("Repository"),
            subtitle: Text(
              "https://github.com/maxx4688/Asongs",
              style: TextStyle(
                color: Colors.grey.withAlpha(100),
              ),
            ),
          ),
          SizedBox(
            height: MediaQuery.of(context).size.width / 4,
          ),
          Container(
            width: MediaQuery.of(context).size.width / 2.5,
            height: MediaQuery.of(context).size.width / 2.5,
            clipBehavior: Clip.hardEdge,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
            ),
            child: Image.asset("lib/assets/asong.png"),
          ),
          const Text(
            "Asongs",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: Colors.grey,
            ),
          ),
          const Text(
            "Made in India by Ashish.",
            style: TextStyle(),
          ),
        ],
      ),
    );
  }
}
