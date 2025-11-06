import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserProvider extends ChangeNotifier {
  String _username = 'ash.';
  bool _ios = false;
  bool _excludeShortSongs = false;
  String get username => _username;
  bool get ios => _ios;
  bool get excludeShortSongs => _excludeShortSongs;

  void setName(String username) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString("user", username);
    _username = username;
    notifyListeners();
  }

  void toggleIos() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool("ios", !_ios);
    _ios = !_ios;
    notifyListeners();
  }

  Future<void> setExcludeShortSongs(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('exclude_short_songs', value);
    _excludeShortSongs = value;
    notifyListeners();
  }

  UserProvider() {
    _loadUser();
  }

  Future _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    _username = prefs.getString("user") ?? "ash.";
    _ios = prefs.getBool("ios") ?? false;
    _excludeShortSongs = prefs.getBool('exclude_short_songs') ?? false;
    notifyListeners();
  }
}
