import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SetupGameView extends StatelessWidget {
  final DocumentReference matchRef;
  final Map<String, dynamic> data;
  final String uid;

  const SetupGameView({
    super.key,
    required this.matchRef,
    required this.data,
    required this.uid,
  });

  @override
  Widget build(BuildContext context) {
    final gameStarted = data['gameStarted'] ?? false;
    final rolesLocked = data['rolesLocked'] ?? false;
    final player1Ready = data['player1Ready'] ?? false;
    final player2Ready = data['player2Ready'] ?? false;

    if (gameStarted || rolesLocked) return const SizedBox.shrink();

    final isPlayer1 = data['player1'] == uid;
    final isAmIReady = isPlayer1 ? player1Ready : player2Ready;

    return SafeArea(
      // Ensures content respects system gesture navigation bars
      child: Padding(
        // Increased bottom padding to 50.0 to heavily force the buttons up the screen
        padding: const EdgeInsets.only(
          bottom: 50.0,
          left: 24.0,
          right: 24.0,
          top: 10.0,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isAmIReady)
              SizedBox(
                width: double.infinity,
                height: 54, // Slightly taller button for easier tapping
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () async {
                    final field = isPlayer1 ? 'player1Ready' : 'player2Ready';
                    await matchRef.update({field: true});
                  },
                  child: const Text(
                    "READY",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              )
            else if (!player1Ready || !player2Ready)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                child: Text(
                  "Waiting for opponent to be ready...",
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
              ),

            if (player1Ready &&
                player2Ready &&
                !gameStarted &&
                !rolesLocked) ...[
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "START MATCH",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  // Inside setup_game_view.dart -> START MATCH ElevatedButton:
                  // Inside setup_game_view.dart -> START MATCH ElevatedButton
                  onPressed: () async {
                    final d =
                        (await matchRef.get()).data() as Map<String, dynamic>;
                    final p1Uid = d['player1'];
                    final p2Uid = d['player2'];

                    // 1. Fetch the dynamically assigned level configuration fields from the document
                    final int stakePerPlayer = d['stakePerPlayer'] ?? 50;
                    final int totalPool = d['bountyPool'] ?? 100;

                    // 2. Deduct the dynamic stake amount from Player 1's wallet
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(p1Uid)
                        .update({
                          'coins': FieldValue.increment(-stakePerPlayer),
                        });

                    // 3. Deduct the dynamic stake amount from Player 2's wallet
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(p2Uid)
                        .update({
                          'coins': FieldValue.increment(-stakePerPlayer),
                        });

                    // 4. Initialize the match state with the dynamically assigned fields
                    await matchRef.update({
                      'rolesLocked': true,
                      'gameStarted': true,
                      'askerUid': uid,
                      'answererUid': uid == p1Uid ? p2Uid : p1Uid,
                      'status': 'active',
                      'turn': 'asker',
                      'bountyPool': totalPool,
                    });
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
