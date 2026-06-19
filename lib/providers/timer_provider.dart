import 'dart:async';
import 'package:flutter/material.dart';

class TimerProvider extends ChangeNotifier {
  Timer? _timer;

  int _remainingSeconds = 60;

  int get remainingSeconds => _remainingSeconds;

  bool get isRunning => _timer != null;

  void startTimer() {
    stopTimer();

    _remainingSeconds = 60;

    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
          notifyListeners();
        } else {
          stopTimer();
        }
      },
    );
  }

  void stopTimer() {
    _timer?.cancel();
    _timer = null;
    notifyListeners();
  }

  void resetTimer() {
    stopTimer();
    _remainingSeconds = 60;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}