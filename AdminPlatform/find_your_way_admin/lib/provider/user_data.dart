import 'package:flutter/material.dart';

class UserData with ChangeNotifier {
  String? _username;
  String? _password;

  String? get username => _username;
  String? get password => _password;

  void setUserData(String username, String password) {
    _username = username;
    _password = password;
    notifyListeners();
  }

  void clearUserData() {
    _username = null;
    _password = null;
    notifyListeners();
  }
}
