import 'package:flutter/material.dart';
import '../../online/online_users_screen.dart'; // Ensure this points to where OnlineUsersScreen lives

class LevelSelectionScreen extends StatelessWidget {
  const LevelSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Preserving your exact match configurations
    final tiers = [
      {'name': 'Beginner', 'stake': 50, 'color': Colors.green},
      {'name': 'Easy', 'stake': 100, 'color': Colors.blue},
      {'name': 'Normal', 'stake': 200, 'color': Colors.orange},
      {'name': 'Hard', 'stake': 350, 'color': Colors.red},
      {'name': 'Expert', 'stake': 500, 'color': Colors.purple},
    ];

    return Scaffold(
      backgroundColor: const Color(
        0xFF0F172A,
      ), // Matches your primary slate background
      appBar: AppBar(
        title: const Text('Select Challenge Level'),
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        centerTitle: true,
        // 🟢 EXPLICIT BACK BUTTON FORCE:
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
          ),
          onPressed: () {
            Navigator.pop(
              context,
            ); // Pops this screen off the stack and returns to Home
          },
        ),
      ),
      body: SafeArea(
        // SingleChildScrollView used here to guarantee responsiveness on small screens
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Choose Your Stakes",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                "Both players stake entry coins. Winner takes the pool!",
                style: TextStyle(fontSize: 14, color: Colors.white54),
              ),
              const SizedBox(height: 20),

              // Map your tiers into beautiful full-width interactive cards
              ...tiers.map((tier) {
                final name = tier['name'] as String;
                final stake = tier['stake'] as int;
                final color = tier['color'] as Color;

                return Card(
                  color: const Color(
                    0xFF1E293B,
                  ), // Matches your previous bottom sheet color tone
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    side: BorderSide(color: color.withOpacity(0.3), width: 1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.shield, color: color, size: 28),
                    ),
                    title: Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 18,
                      ),
                    ),
                    // 🟢 CORRECT
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        "Stake: $stake coins   |   Pool: ${stake * 2} coins",
                        style: TextStyle(color: Colors.grey[400], fontSize: 13),
                      ),
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white54,
                      size: 16,
                    ),
                    onTap: () {
                      // Navigate directly to your dynamic OnlineUsersScreen setup
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const OnlineUsersScreen(),
                          // If your OnlineUsersScreen later accepts arguments, pass them here:
                          // builder: (_) => OnlineUsersScreen(challengeLevel: name, challengeStake: stake),
                        ),
                      );
                    },
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
