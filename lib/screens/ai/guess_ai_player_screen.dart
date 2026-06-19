import 'package:flutter/material.dart';

class GuessAiPlayerScreen
    extends StatelessWidget {
  const GuessAiPlayerScreen({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Guess AI Player',
        ),
      ),
      body: const Center(
        child: Text(
          'Coming Soon',
          style: TextStyle(
            fontSize: 24,
          ),
        ),
      ),
    );
  }
}