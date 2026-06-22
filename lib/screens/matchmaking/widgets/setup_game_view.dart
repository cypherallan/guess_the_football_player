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

    return Column(
      children: [
        if (!gameStarted && !rolesLocked)
          ElevatedButton(
            onPressed: () async {
              final d = (await matchRef.get()).data() as Map<String, dynamic>;
              if (d['player1'] == uid) {
                await matchRef.update({'player1Ready': true});
              } else {
                await matchRef.update({'player2Ready': true});
              }
            },
            child: const Text("READY"),
          ),
        if (player1Ready && player2Ready && !gameStarted && !rolesLocked)
          Center(
            child: ElevatedButton(
              child: const Text("START MATCH"),
              onPressed: () async {
                final d = (await matchRef.get()).data() as Map<String, dynamic>;
                await matchRef.update({
                  'rolesLocked': true,
                  'gameStarted': true,
                  'askerUid': uid,
                  'answererUid': uid == d['player1']
                      ? d['player2']
                      : d['player1'],
                  'status': 'active',
                });
              },
            ),
          ),
      ],
    );
  }
}
