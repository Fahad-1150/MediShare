import 'package:flutter/material.dart';
import '../models/user.dart';

class AuthState extends ChangeNotifier {
  UserModel? user;

  void login(UserModel u) {
    user = u;
    notifyListeners();
  }

  void logout() {
    user = null;
    notifyListeners();
  }

  bool get isLoggedIn => user != null;
}
