import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../matchmaking/match_screen.dart'; // Adjust this path if your MatchScreen is elsewhere

class SentChallengesSection extends StatelessWidget {
  const SentChallengesSection({super.key});

  // Method to completely delete/cancel the invitation before it starts
  Future<void> _cancelChallenge(String challengeId, String? matchId) async {
    final firestore = FirebaseFirestore.instance;
    await firestore.collection('challenges').doc(challengeId).delete();
    if (matchId != null) {
      await firestore.collection('matches').doc(matchId).delete();
    }
  }

  // Clear accepted notification from dashboard once the player acknowledges it or enters
  Future<void> _clearSettledChallenge(String challengeId) async {
    await FirebaseFirestore.instance
        .collection('challenges')
        .doc(challengeId)
        .delete();
  }

  // Opens an inspection window showing detailed status parameters
  void _showStatusDialog(
    BuildContext context,
    String title,
    String status,
    String challengeId,
    String? matchId,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(
          status == 'accepted'
              ? "Your opponent accepted the terms of engagement! Press 'ENTER MATCH' to join the lobby room."
              : "Waiting for your opponent to open the app and accept your coin stake request...",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CLOSE"),
          ),
          if (status == 'pending')
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
              onPressed: () async {
                await _cancelChallenge(challengeId, matchId);
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text("CANCEL CHALLENGE"),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid == null) return const SizedBox.shrink();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('challenges')
          .where('fromUid', isEqualTo: currentUid)
          .where('type', isEqualTo: 'game_challenge')
          // FIX: Query everything that hasn't been completely finished/closed out yet
          .where('status', whereIn: ['pending', 'accepted'])
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Text(
                "Sent Challenges",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white70,
                ),
              ),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                final doc = snapshot.data!.docs[index];
                final data = doc.data() as Map<String, dynamic>;

                final receiverName = data['toName'] ?? 'Player';
                final matchLevel = data['level'] ?? 'Normal';
                final stakeAmount = data['stakePerPlayer'] ?? 200;
                final matchId = data['matchId'];
                final challengeStatus = data['status'] ?? 'pending';

                final bool isAccepted = challengeStatus == 'accepted';

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  color: isAccepted
                      ? const Color(0xFF064E3B)
                      : const Color(
                          0xFF0F172A,
                        ), // Emerald if accepted, dark slate if waiting
                  shape: RoundedRectangleBorder(
                    side: BorderSide(
                      color: isAccepted
                          ? Colors.greenAccent
                          : Colors.blue.withOpacity(0.4),
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    onTap: () {
                      if (isAccepted && matchId != null) {
                        // Clean up challenge from tracker feed so it doesn't linger forever, then jump in!
                        _clearSettledChallenge(doc.id);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MatchScreen(matchId: matchId),
                          ),
                        );
                      } else {
                        _showStatusDialog(
                          context,
                          "Challenge to $receiverName",
                          challengeStatus,
                          doc.id,
                          matchId,
                        );
                      }
                    },
                    leading: isAccepted
                        ? const Icon(
                            Icons.check_circle,
                            color: Colors.greenAccent,
                            size: 28,
                          )
                        : const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.blueAccent,
                              ),
                            ),
                          ),
                    title: Text(
                      isAccepted
                          ? "Challenge Accepted by $receiverName!"
                          : "Challenged $receiverName",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    subtitle: Text(
                      isAccepted
                          ? "Tap here to instantly start playing!"
                          : "Level: $matchLevel • Stakes: $stakeAmount Coins",
                      style: TextStyle(
                        color: isAccepted ? Colors.white : Colors.white54,
                        fontSize: 13,
                      ),
                    ),
                    trailing: isAccepted
                        ? const Icon(
                            Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 28,
                          )
                        : IconButton(
                            icon: const Icon(
                              Icons.close,
                              color: Colors.redAccent,
                              size: 20,
                            ),
                            onPressed: () => _cancelChallenge(doc.id, matchId),
                          ),
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
          ],
        );
      },
    );
  }
}
