import 'package:flutter/material.dart';
import '../../screens/ai/ai_game_engine_screen.dart.dart';

class AiGuessPlayerScreen extends StatelessWidget {
  final String chosenLevel;
  final int chosenStake;

  // 🟢 Update constructor to require these values from the level screen
  const AiGuessPlayerScreen({
    super.key,
    required this.chosenLevel,
    required this.chosenStake,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('AI Challenge Mode'),
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                "Choose Your Role",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Stakes match your 1v1 tier levels. Roles will alternate if you play again!",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white54, fontSize: 14),
              ),
              const SizedBox(height: 40),
              _buildRoleCard(
                context,
                title: "Be the Guesser",
                description:
                    "The AI selects a mystery football player and provides clues. You guess the name!",
                icon: Icons.psychology_rounded,
                color: Colors.blueAccent,
                initialRole: "guesser",
              ),
              const SizedBox(height: 20),
              _buildRoleCard(
                context,
                title: "Be the Mastermind",
                description:
                    "You choose a football player and provide hints. See if the AI can read your mind!",
                icon: Icons.gavel_rounded,
                color: Colors.orangeAccent,
                initialRole: "mastermind",
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required String initialRole,
  }) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AiGameEngineScreen(
              currentRole: initialRole,
              challengeLevel: chosenLevel, // 🟢 Passes down the custom level
              challengeStake: chosenStake, // 🟢 Passes down the custom stake
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.4), width: 1.5),
        ),
        child: Row(
          children: [
            Icon(icon, size: 50, color: color),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
