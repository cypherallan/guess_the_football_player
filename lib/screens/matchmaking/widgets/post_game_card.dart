import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

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
        ? data['player2Name']
        : data['player1Name'];

    if (status != 'finished') return const SizedBox.shrink();

    return Column(
      children: [
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
                "Secret player: ${data['secretPlayer']}",
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 10),
              Text(
                "Final score: ${data['score']}",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        Container(
          margin: const EdgeInsets.all(10),
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            border: Border.all(),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
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
                    onPressed: () async =>
                        await matchRef.update({'${uid}_rematch': 'requested'}),
                    child: const Text("YES"),
                  ),
                  const SizedBox(width: 20),
                  ElevatedButton(
                    onPressed: () async => await matchRef.update({
                      '${uid}_rematch': 'declined',
                      'status': 'finished',
                    }),
                    child: const Text("NO"),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (opponentRematch == 'requested' && myRematch == null)
          Container(
            margin: const EdgeInsets.all(10),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Text(
                  "🎮 $opponentName wants to play again",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: () async {
                        await matchRef.update({'${uid}_rematch': 'accepted'});
                        final d = await matchRef.get();
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
                      child: const Text("YES"),
                    ),
                    const SizedBox(width: 20),
                    ElevatedButton(
                      onPressed: () async => await matchRef.update({
                        '${uid}_rematch': 'declined',
                        'status': 'finished',
                      }),
                      child: const Text("NO"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        if (opponentRematch == 'declined')
          Container(
            margin: const EdgeInsets.all(10),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.red.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Text(
                  "❌ $opponentName does not want to play again",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("SEARCH NEW OPPONENT"),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
