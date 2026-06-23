import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../matchmaking/match_screen.dart';

class OnlineUsersScreen extends StatefulWidget {
  const OnlineUsersScreen({super.key});

  @override
  State<OnlineUsersScreen> createState() => _OnlineUsersScreenState();
}

class _OnlineUsersScreenState extends State<OnlineUsersScreen> {
  final uid = FirebaseAuth.instance.currentUser!.uid;

  bool _navigating = false;
  bool _processingAccept = false;

  @override
  void initState() {
    super.initState();
  }

  // ===================== SEND INVITE =====================
  // ===================== SEND INVITE =====================
  Future<void> sendInvite(String opponentId, String opponentName) async {
    try {
      final firestore = FirebaseFirestore.instance;

      // 1. Create a live match lobby room document first
      final matchRef = await firestore.collection('matches').add({
        'player1': uid,
        'player2': null, // Remains null until they click accept!
        'player1Name':
            FirebaseAuth.instance.currentUser!.displayName ?? "Player",
        'player2Name': opponentName,
        'status': 'searching', // Waiting state
        'currentTurn': uid,
        'player1Ready': false,
        'player2Ready': false,
        'rolesLocked': false,
        'friendsSynced': true,
        'createdAt': FieldValue.serverTimestamp(),
        'stakePerPlayer': 50, // Default stake or pass dynamic coins here
        'bountyPool': 100,
      });

      // 2. Broadcast the challenge tracking card with the matchId attached
      await firestore.collection('challenges').add({
        'fromUid': uid,
        'fromName': FirebaseAuth.instance.currentUser!.displayName ?? "Player",
        'toUid': opponentId,
        'toName': opponentName,
        'status': 'pending',
        'type':
            'game_challenge', // Matches the tracking filters we built earlier
        'matchId': matchRef.id, // Essential linkage!
        'createdAt': FieldValue.serverTimestamp(),
        'level': 'Normal', // Default parameters
        'stakePerPlayer': 50,
      });

      // 3. Automatically drop the sender straight into their waiting screen lobby
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => MatchScreen(matchId: matchRef.id)),
          (route) => false,
        );
      }
    } catch (e) {
      debugPrint("ERROR SENDING DIRECT INVITE: $e");
    }
  }

  // ===================== NAVIGATE SAFELY =====================
  void _goToMatch(String matchId) {
    if (_navigating || !mounted) return;

    _navigating = true;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => MatchScreen(matchId: matchId)),
      (route) => false,
    );
  }

  // ===================== ACCEPT INVITE =====================
  Future<void> acceptInvite(
    String challengeId,
    String fromUid,
    String fromName,
  ) async {
    if (_processingAccept) return;

    _processingAccept = true;

    try {
      final firestore = FirebaseFirestore.instance;

      final challengeRef = firestore.collection('challenges').doc(challengeId);

      final matchRefFuture = firestore.collection('matches').add({
        'player1': fromUid,
        'player2': uid,
        'player1Name': fromName,
        'player2Name':
            FirebaseAuth.instance.currentUser!.displayName ?? 'Player',
        'status': 'active',
        'currentTurn': fromUid,
        'player1Ready': false,
        'player2Ready': false,
        'rolesLocked': false,
        'friendsSynced': true,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 🚀 NAVIGATE IMMEDIATELY (NO WAIT)
      matchRefFuture.then((matchRef) {
        _goToMatch(matchRef.id);
      });

      // 🚀 BACKGROUND: update challenge (no blocking UI)
      challengeRef.update({'status': 'accepted', 'acceptedBy': uid});

      // 🚀 BACKGROUND: friends sync
      final batch = firestore.batch();

      batch.set(
        firestore
            .collection('users')
            .doc(uid)
            .collection('friends')
            .doc(fromUid),
        {'uid': fromUid},
      );

      batch.set(
        firestore
            .collection('users')
            .doc(fromUid)
            .collection('friends')
            .doc(uid),
        {'uid': uid},
      );

      batch.commit();
    } catch (e) {
      debugPrint("ACCEPT ERROR: $e");
    } finally {
      _processingAccept = false;
    }
  }

  // ===================== STREAMS =====================
  Stream<QuerySnapshot> getOnlineUsers() {
    return FirebaseFirestore.instance
        .collection('users')
        .where('isOnline', isEqualTo: true)
        .snapshots();
  }

  Stream<QuerySnapshot> getIncomingChallenges() {
    return FirebaseFirestore.instance
        .collection('challenges')
        .where('toUid', isEqualTo: uid)
        .where('status', isEqualTo: 'pending')
        .snapshots();
  }

  // ===================== UI =====================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Online PvP")),

      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ================= INVITES SECTION =================
          StreamBuilder<QuerySnapshot>(
            stream: getIncomingChallenges(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox.shrink();
              final invites = snapshot.data!.docs;
              if (invites.isEmpty) return const SizedBox.shrink();

              //  TO THIS:
              return Container(
                color: Colors.amber.withOpacity(0.05),
                constraints: BoxConstraints(
                  maxHeight:
                      MediaQuery.of(context).size.height *
                      0.35, // Safely caps the height here
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(
                        left: 16.0,
                        top: 12.0,
                        bottom: 4.0,
                      ),
                      child: Text(
                        "INCOMING CHALLENGES",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.amberAccent,
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        children: invites.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          return Card(
                            elevation: 3,
                            child: ListTile(
                              title: Text(
                                "Invite from ${data['fromName']}",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: const Text("Tap accept to start match"),
                              trailing: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                ),
                                onPressed: () async {
                                  if (_processingAccept) return;
                                  await acceptInvite(
                                    doc.id,
                                    data['fromUid'],
                                    data['fromName'],
                                  );
                                },
                                child: const Text(
                                  "ACCEPT",
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const Divider(height: 1),
                  ],
                ),
              );
            },
          ),

          const Padding(
            padding: EdgeInsets.only(left: 16.0, top: 16.0, bottom: 8.0),
            child: Text(
              "ONLINE PLAYERS",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),

          // ================= ONLINE USERS SECTION =================
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: getOnlineUsers(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final users = snapshot.data!.docs
                    .where((doc) => doc.id != uid)
                    .toList();

                if (users.isEmpty) {
                  return const Center(
                    child: Text(
                      "Nobody else is online right now.",
                      style: TextStyle(color: Colors.white38),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final data = users[index].data() as Map<String, dynamic>;
                    final opponentId = data['uid'] ?? users[index].id;
                    final opponentName = data['displayName'] ?? 'Unknown';

                    return ListTile(
                      leading: Stack(
                        children: [
                          const CircleAvatar(child: Icon(Icons.person)),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Theme.of(
                                    context,
                                  ).scaffoldBackgroundColor,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      title: Text(
                        opponentName,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: const Text(
                        "Ready to play",
                        style: TextStyle(
                          color: Colors.greenAccent,
                          fontSize: 12,
                        ),
                      ),
                      trailing: ElevatedButton(
                        onPressed: () => sendInvite(opponentId, opponentName),
                        child: const Text("Invite"),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
