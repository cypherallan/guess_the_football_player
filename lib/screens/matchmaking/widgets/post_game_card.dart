import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:guess_the_footballer/screens/home/home_screen.dart'; // Ensure this import matches your project structure

class PostGameCard extends StatelessWidget {
  final DocumentReference matchRef;
  final Map<String, dynamic> data;
  final String uid;

  const PostGameCard({
    super.key,
    required this.matchRef,
    required this.data,
    required this.uid,
  });

  @override
  Widget build(BuildContext context) {
    final winner = data['winner'];
    final status = data['status'];
    final opponentUid = uid == data['player1']
        ? data['player2']
        : data['player1'];
    final myRematch = data['${uid}_rematch'];
    final opponentRematch = data['${opponentUid}_rematch'];
    final opponentName = uid == data['player1']
        ? (data['player2Name'] ?? "Opponent")
        : (data['player1Name'] ?? "Opponent");

    if (status != 'finished') return const SizedBox.shrink();

    // --- AUTOMATIC ROUTING BACK TO HOME IF ANYONE DECLINED ---
    if (myRematch == 'declined' || opponentRematch == 'declined') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => HomeScreen()),
            (route) => false,
          );
        }
      });
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        // 1. GAME RESULTS BANNER (Always visible when finished)
        Container(
          width: double.infinity,
          margin: const EdgeInsets.all(10),
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.amber.shade100,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              Text(
                winner == uid
                    ? "🏆 YOU GUESSED THE PLAYER!"
                    : "🎯 OPPONENT GUESSED THE PLAYER!",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Secret player: ${data['secretPlayer'] ?? 'N/A'}",
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 10),
              Text(
                "Final score: ${data['score'] ?? 0}",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),

        // 2. DYNAMIC REMATCH AREA (Switches based on current decisions)
        Container(
          margin: const EdgeInsets.all(10),
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Builder(
            builder: (context) {
              // CASE A: Opponent has asked, but you haven't decided yet
              if (opponentRematch == 'requested' && myRematch == null) {
                return Column(
                  children: [
                    Text(
                      "🎮 $opponentName wants to play again!",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 15),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                          ),
                          onPressed: () async {
                            await matchRef.update({
                              '${uid}_rematch': 'accepted',
                            });
                            final d = await matchRef.get();

                            // Swap roles and reset match back to active playground cleanly
                            await matchRef.update({
                              'status': 'active',
                              'winner': null,
                              'winningGuess': null,
                              'secretPlayer': null,
                              'isLockedIn': false,
                              'score': 100,
                              '${d['player1']}_rematch': null,
                              '${d['player2']}_rematch': null,
                              'askerUid': d['answererUid'],
                              'answererUid': d['askerUid'],
                            });
                          },
                          child: const Text(
                            "ACCEPT",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 20),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                          onPressed: () async {
                            await matchRef.update({
                              '${uid}_rematch': 'declined',
                            });
                          },
                          child: const Text(
                            "DENY",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              }

              // CASE B: You tapped YES, but opponent hasn't responded yet
              if (myRematch == 'requested' && opponentRematch == null) {
                return const Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 15),
                    Text(
                      "Waiting for opponent to accept...",
                      style: TextStyle(fontStyle: FontStyle.italic),
                    ),
                  ],
                );
              }

              // CASE C: Default view (No one has made a choice yet)
              return Column(
                children: [
                  const Text(
                    "Match ended",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  const Text("Would you like to play again?"),
                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: () async => await matchRef.update({
                          '${uid}_rematch': 'requested',
                        }),
                        child: const Text("YES"),
                      ),
                      const SizedBox(width: 20),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade300,
                        ),
                        onPressed: () async => await matchRef.update({
                          '${uid}_rematch': 'declined',
                        }),
                        child: const Text(
                          "NO",
                          style: TextStyle(color: Colors.black),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
