import 'package:flutter/material.dart';

class GameStatusCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool rolesLocked;
  final int timeLeft;
  final bool isAsker;
  final int score;

  const GameStatusCard({
    super.key,
    required this.data,
    required this.rolesLocked,
    required this.timeLeft,
    required this.isAsker,
    required this.score,
  });

  @override
  Widget build(BuildContext context) {
    final player1Ready = data['player1Ready'] ?? false;
    final player2Ready = data['player2Ready'] ?? false;

    return Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          Text("Player 1: ${data['player1Name'] ?? ''}"),
          Text("Player 2: ${data['player2Name'] ?? ''}"),
          const SizedBox(height: 10),
          Text("Ready: $player1Ready"),
          Text("Ready: $player2Ready"),
          const SizedBox(height: 10),
          if (rolesLocked)
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "⏱️ $timeLeft seconds left",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: timeLeft <= 10 ? Colors.red : Colors.black,
                    ),
                  ),
                  Text(
                    isAsker
                        ? "🔥 YOU ASK THE QUESTIONS"
                        : "🛡️ YOU ANSWER THE QUESTIONS",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    isAsker
                        ? "Your score: $score"
                        : "Player ${data['player1Name'] ?? ''} score: $score",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            )
          else
            const Text("Waiting for game to start..."),
        ],
      ),
    );
  }
}
