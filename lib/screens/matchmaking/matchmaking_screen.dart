import 'package:flutter/material.dart';
import '../../core/services/matchmaking_service.dart';
import 'match_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MatchmakingScreen extends StatefulWidget {
  const MatchmakingScreen({super.key});

  @override
  State<MatchmakingScreen> createState() => _MatchmakingScreenState();
}

class _MatchmakingScreenState extends State<MatchmakingScreen> {
  final MatchmakingService _matchmakingService = MatchmakingService();

  @override
  void initState() {
    super.initState();
    joinQueue();
  }

  Future<void> joinQueue() async {
    await _matchmakingService.joinQueue();

    final uid = FirebaseAuth.instance.currentUser!.uid;

    FirebaseFirestore.instance.collection('matches').snapshots().listen((
      snapshot,
    ) {
      for (final doc in snapshot.docs) {
        final data = doc.data();

        if (data['player1'] == uid || data['player2'] == uid) {
          if (!mounted) return;

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => MatchScreen(matchId: doc.id)),
          );

          return;
        }
      }
    });

    await Future.delayed(const Duration(seconds: 2));

    await _matchmakingService.findMatch();
  }

  @override
  void dispose() {
    _matchmakingService.leaveQueue();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Finding Opponent')),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text(
              'Searching for an opponent...',
              style: TextStyle(fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }
}
