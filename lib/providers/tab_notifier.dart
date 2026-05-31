import 'package:flutter/material.dart';

class TabNotifier extends ChangeNotifier {
  int _index = 0;

  int get index => _index;

  void navigateTo(int index) {
    _index = index;
    notifyListeners();
  }
}
