import 'package:flutter/material.dart';

class AiGameScreen extends StatelessWidget {
  const AiGameScreen({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'AI Match',
        ),
      ),
      body: const Center(
        child: Text(
          'AI Gameplay Coming Soon',
          style: TextStyle(
            fontSize: 24,
          ),
        ),
      ),
    );
  }
}