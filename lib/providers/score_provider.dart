import 'package:flutter/material.dart';

class ScoreProvider extends ChangeNotifier {
  int _score = 100;

  int get score => _score;

  void resetScore() {
    _score = 100;
    notifyListeners();
  }

  void answerYes() {
    notifyListeners();
  }

  void answerNo() {
    _score -= 10;

    if (_score < 0) {
      _score = 0;
    }

    notifyListeners();
  }

  bool get isEliminated => _score == 0;
}