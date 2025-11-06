import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserProvider extends ChangeNotifier {
  String _username = 'ash.';
  bool _ios = false;
  String get username => _username;
  bool get ios => _ios;

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

  UserProvider() {
    _loadUser();
  }

  Future _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    _username = prefs.getString("user") ?? "ash.";
    _ios = prefs.getBool("ios") ?? false;
    notifyListeners();
  }
}
