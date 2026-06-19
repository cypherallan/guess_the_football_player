import 'package:flutter/material.dart';

class AiGuessPlayerScreen
    extends StatelessWidget {
  const AiGuessPlayerScreen({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'AI Guesses Your Player',
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