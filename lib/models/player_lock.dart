class PlayerLock {
  final String playerName;
  final DateTime lockedAt;

  PlayerLock({
    required this.playerName,
    required this.lockedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'playerName': playerName,
      'lockedAt': lockedAt.toIso8601String(),
    };
  }

  factory PlayerLock.fromMap(Map<String, dynamic> map) {
    return PlayerLock(
      playerName: map['playerName'] ?? '',
      lockedAt: DateTime.parse(map['lockedAt']),
    );
  }
}