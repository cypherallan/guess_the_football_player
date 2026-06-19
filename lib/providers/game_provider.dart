import 'package:flutter/material.dart';
import '../models/player_lock.dart';

class GameProvider extends ChangeNotifier {
  PlayerLock? _lockedPlayer;

  String _roomId = '';

  bool _playerLocked = false;

  PlayerLock? get lockedPlayer => _lockedPlayer;

  String get roomId => _roomId;

  bool get playerLocked => _playerLocked;

  void createRoom(String roomId) {
    _roomId = roomId;
    notifyListeners();
  }

  void lockPlayer(String playerName) {
    _lockedPlayer = PlayerLock(
      playerName: playerName,
      lockedAt: DateTime.now(),
    );

    _playerLocked = true;

    notifyListeners();
  }

  bool validateGuess(String guess) {
    if (_lockedPlayer == null) return false;

    return guess.trim().toLowerCase() ==
        _lockedPlayer!.playerName.trim().toLowerCase();
  }

  void resetGame() {
    _lockedPlayer = null;
    _playerLocked = false;
    _roomId = '';
    notifyListeners();
  }
}