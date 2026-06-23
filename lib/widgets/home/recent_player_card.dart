import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:guess_the_footballer/screens/matchmaking/match_screen.dart';

class RecentPlayerCard extends StatelessWidget {
  const RecentPlayerCard({super.key});

  // Reusable method to accept the challenge right from the dashboard card
  Future<void> _acceptChallenge(
    BuildContext context,
    String challengeId,
    String fromUid,
    Map<String, dynamic> challengeData,
  ) async {
    final firestore = FirebaseFirestore.instance;
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final String matchLevel = challengeData['level'] ?? 'Normal';
    final int dynamicStake = challengeData['stakePerPlayer'] ?? 200;
    final int dynamicPool = challengeData['bountyPool'] ?? 400;

    // 1. Create the active match room document
    final matchRef = await firestore.collection('matches').add({
      'player1': fromUid,
      'player2': uid,
      'status': 'active',
      'player1Ready': false,
      'player2Ready': false,
      'level': matchLevel,
      'stakePerPlayer': dynamicStake,
      'bountyPool': dynamicPool,
      'rolesLocked': false,
      'gameStarted': false,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // 2. Update the invitation challenge status
    await firestore.collection('challenges').doc(challengeId).update({
      'status': 'accepted',
      'matchStatus': 'active',
      'matchId': matchRef.id,
      'acceptedBy': uid,
      'acceptedAt': FieldValue.serverTimestamp(),
    });

    // 3. Rout the user straight into battle
    if (context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => MatchScreen(matchId: matchRef.id)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;

    if (currentUid == null) return const SizedBox.shrink();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('challenges')
          .where('toUid', isEqualTo: currentUid)
          .where('type', isEqualTo: 'game_challenge')
          .where('status', isEqualTo: 'pending')
          .limit(1) // Keep the UI tight by pulling the most urgent one
          .snapshots(),
      builder: (context, snapshot) {
        // Fallback or loading state
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Card(
            elevation: 2,
            color: const Color(0xFF1E293B),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: const ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.blueGrey,
                child: Icon(Icons.sports_soccer, color: Colors.white),
              ),
              title: Text(
                "No Pending Invites",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              subtitle: Text(
                "Challenge a friend to start playing!",
                style: TextStyle(color: Colors.white54),
              ),
            ),
          );
        }

        final doc = snapshot.data!.docs.first;
        final data = doc.data() as Map<String, dynamic>;

        final challengerName = data['fromName'] ?? 'Someone';
        final matchLevel = data['level'] ?? 'Normal';
        final stakeAmount = data['stakePerPlayer'] ?? 200;

        return Card(
          elevation: 8,
          color: const Color(0xFF1E1B4B), // Noticeable alert indigo tone
          shape: RoundedRectangleBorder(
            side: const BorderSide(color: Colors.amber, width: 1.5),
            borderRadius: BorderRadius.circular(16),
          ),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.amber,
              child: Icon(Icons.gavel, color: Colors.black),
            ),
            title: Text(
              "$challengerName Challenged You!",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            subtitle: Text(
              "Level: $matchLevel ($stakeAmount Coins)",
              style: const TextStyle(color: Colors.amberAccent),
            ),
            trailing: const Icon(
              Icons.play_circle_fill,
              color: Colors.green,
              size: 32,
            ),
            onTap: () =>
                _acceptChallenge(context, doc.id, data['fromUid'] ?? '', data),
          ),
        );
      },
    );
  }
}
