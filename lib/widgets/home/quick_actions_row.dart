import 'package:flutter/material.dart';

class QuickActionsRow extends StatelessWidget {
  const QuickActionsRow({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        Icon(Icons.people),
        Icon(Icons.emoji_events),
        Icon(Icons.notifications),
        Icon(Icons.settings),
      ],
    );
  }
}
