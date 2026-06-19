import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../friends/friends_screen.dart';
import '../../core/services/auth_service.dart';
import '../ai/ai_guess_player_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Guess The Footballer'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => FriendsScreen()),
              );
            },
            icon: const Icon(Icons.people),
          ),
          IconButton(
            onPressed: () async {
              await AuthService().signOut();
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),

            CircleAvatar(
              radius: 40,
              backgroundImage: user?.photoURL != null
                  ? NetworkImage(user!.photoURL!)
                  : null,
            ),

            const SizedBox(height: 10),

            Text(
              user?.displayName ?? 'Unknown User',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 5),

            Text(user?.email ?? '', style: const TextStyle(color: Colors.grey)),

            const SizedBox(height: 25),

            const Icon(Icons.sports_soccer, size: 80),

            const SizedBox(height: 20),

            const Text(
              'Choose Game Mode',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 40),

            // 🔥 NEW CLEAN PvP ENTRY
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => FriendsScreen()),
                  );
                },
                child: const Text('Play 1 vs 1 (Invite Players)'),
              ),
            ),

            const SizedBox(height: 15),

            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AiGuessPlayerScreen(),
                    ),
                  );
                },
                child: const Text('AI Guesses Your Player'),
              ),
            ),

            const SizedBox(height: 15),

            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => FriendsScreen()),
                  );
                },
                child: const Text('Friends'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
