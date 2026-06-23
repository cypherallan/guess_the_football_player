import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:guess_the_footballer/screens/matchmaking/match_screen.dart';

class FeaturedGameCard extends StatelessWidget {
  const FeaturedGameCard({super.key});

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

    await firestore.collection('challenges').doc(challengeId).update({
      'status': 'accepted',
      'matchStatus': 'active',
      'matchId': matchRef.id,
      'acceptedBy': uid,
      'acceptedAt': FieldValue.serverTimestamp(),
    });

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
          .limit(1)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          // Fallback view when the user has clean notifications
          return Card(
            color: Colors.grey[800],
            child: const Padding(
              padding: EdgeInsets.all(20),
              child: Row(
                children: [
                  Icon(Icons.sports_soccer, color: Colors.white24, size: 50),
                  SizedBox(width: 15),
                  Expanded(
                    child: Text(
                      'No Ongoing Battles\nInvite a friend to start!',
                      style: TextStyle(
                        color: Colors.white38,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final doc = snapshot.data!.docs.first;
        final data = doc.data() as Map<String, dynamic>;

        final challengerName = data['fromName'] ?? 'Player';
        final matchLevel = data['level'] ?? 'Normal';

        return Card(
          color: Colors.green[700],
          elevation: 6,
          child: InkWell(
            onTap: () =>
                _acceptChallenge(context, doc.id, data['fromUid'] ?? '', data),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const Icon(Icons.flash_on, color: Colors.amber, size: 50),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CHALLENGE FROM $challengerName'.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.amber,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Level: $matchLevel Match\nTap to Accept & Play!',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, color: Colors.white),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
