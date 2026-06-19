import 'package:flutter/material.dart';

class ResultScreen extends StatelessWidget {
  final bool isCorrect;
  final int score;

  const ResultScreen({
    super.key,
    required this.isCorrect,
    required this.score,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Game Result'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              Icon(
                isCorrect
                    ? Icons.emoji_events
                    : Icons.cancel,
                size: 100,
              ),
              const SizedBox(height: 20),
              Text(
                isCorrect
                    ? 'Correct Guess!'
                    : 'Wrong Guess!',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Final Score: $score',
                style: const TextStyle(
                  fontSize: 22,
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  Navigator.popUntil(
                    context,
                    (route) => route.isFirst,
                  );
                },
                child: const Text(
                  'Back To Home',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}