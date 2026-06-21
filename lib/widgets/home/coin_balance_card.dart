import 'package:flutter/material.dart';

class CoinBalanceCard extends StatelessWidget {
  final int coins;

  const CoinBalanceCard({super.key, required this.coins});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blueGrey.shade900,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Badge: Gold 🥇",
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
          const Icon(Icons.emoji_events, color: Colors.amber, size: 45),
        ],
      ),
    );
  }
}
