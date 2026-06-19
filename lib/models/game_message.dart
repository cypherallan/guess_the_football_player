class GameMessage {
  final String senderId;
  final String message;
  final String type;
  final DateTime createdAt;

  GameMessage({
    required this.senderId,
    required this.message,
    required this.type,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'message': message,
      'type': type,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory GameMessage.fromMap(Map<String, dynamic> map) {
    return GameMessage(
      senderId: map['senderId'] ?? '',
      message: map['message'] ?? '',
      type: map['type'] ?? '',
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}