import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:jobee_server/theme/theme_data.dart';
import 'package:jobee_server/ux/permission_page.dart';

class BoardingPage extends StatelessWidget {
  const BoardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: MediaQuery.of(context).size.width / 2.5,
            height: MediaQuery.of(context).size.width / 2.5,
            clipBehavior: Clip.hardEdge,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
            ),
            child: Image.asset("lib/assets/Logo.png"),
          ),
          const SizedBox(height: 20),
          const Text(
            "Asongs",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 25,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            "Version $appVersion",
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
          SizedBox(
            height: MediaQuery.of(context).size.height / 4,
          ),
          SizedBox(
            width: MediaQuery.of(context).size.width * 0.9,
            height: 50,
            child: CupertinoButton(
              color: Theme.of(context).brightness == Brightness.light
                  ? Colors.black12
                  : Colors.white10,
              sizeStyle: CupertinoButtonSize.medium,
              child: const Text(
                "Continue",
                style: TextStyle(
                  fontFamily: 'poppins',
                  color: Colors.grey,
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PermPage(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    ));
  }
}
