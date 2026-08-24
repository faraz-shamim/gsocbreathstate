// SPDX-License-Identifier: AGPL-3.0-only
import 'package:flutter/material.dart';

class NavBarProvider with ChangeNotifier {
  int _index = 0;

  NavBarProvider(this._index);

  int getIndex() {
    return _index;
  }

  void changeIndex(int newIndex) {
    _index = newIndex;
    notifyListeners();
  }
}
