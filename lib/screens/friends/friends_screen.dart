import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../matchmaking/match_screen.dart';

class FriendsScreen extends StatelessWidget {
  // Added constructor parameters to capture incoming level selections from HomeScreen
  final String? challengeLevel;
  final int? challengeStake;

  FriendsScreen({super.key, this.challengeLevel, this.challengeStake});

  final uid = FirebaseAuth.instance.currentUser!.uid;

  // FIX: Capture the exact time this screen session started
  final DateTime sessionStartTime = DateTime.now();

  // ================= USERS =================
  Stream<QuerySnapshot> getUsers() {
    return FirebaseFirestore.instance.collection('users').snapshots();
  }

  Stream<QuerySnapshot> incomingChallenges() {
    return FirebaseFirestore.instance
        .collection('challenges')
        .where('toUid', isEqualTo: uid)
        .where('type', isEqualTo: 'game_challenge')
        .where('status', isEqualTo: 'pending')
        .snapshots();
  }

  // ================= SENT CHALLENGES =================
  Stream<QuerySnapshot> mySentChallenges() {
    return FirebaseFirestore.instance
        .collection('challenges')
        .where('fromUid', isEqualTo: uid)
        .where('status', isEqualTo: 'pending')
        .where('type', isEqualTo: 'game_challenge')
        .snapshots();
  }

  // ================= ACCEPTED (FIXED WITH TIMESTAMP) =================
  Stream<QuerySnapshot> acceptedByOthers() {
    return FirebaseFirestore.instance
        .collection('challenges')
        .where('fromUid', isEqualTo: uid)
        .where('type', isEqualTo: 'game_challenge')
        .where('status', isEqualTo: 'accepted')
        .where('matchStatus', isEqualTo: 'active')
        // FIX: Only show challenges sent during this screen session
        .where(
          'createdAt',
          isGreaterThanOrEqualTo: Timestamp.fromDate(sessionStartTime),
        )
        .snapshots();
  }

  // ================= CHECK FRIEND =================
  Future<bool> isFriend(String otherUid) async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('friends')
        .doc(otherUid)
        .get();

    return doc.exists;
  }

  // ================= ADD FRIEND =================
  Future<void> addFriend(String otherUid) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('friends')
        .doc(otherUid)
        .set({'uid': otherUid});
  }

  // ================= SEND CHALLENGE (UPDATED FIELDS) =================
  Future<void> sendChallenge(String otherUid, String name) async {
    final docRef = FirebaseFirestore.instance.collection('challenges').doc();

    // Attach dynamic level states to pass them cleanly through the pipeline
    final currentLevel = challengeLevel ?? 'Normal';
    final currentStake = challengeStake ?? 200;

    await docRef.set({
      'id': docRef.id,
      'fromUid': uid,
      'fromName': FirebaseAuth.instance.currentUser!.displayName ?? "Player",
      'toUid': otherUid,
      'toName': name,

      'status': 'pending',
      'type': 'game_challenge',

      // Dynamic game setups passed through the invitation snapshot
      'level': currentLevel,
      'stakePerPlayer': currentStake,
      'bountyPool': currentStake * 2,

      // IMPORTANT: prevents re-trigger loops
      'matchId': null,
      'acceptedAt': null,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // ================= ACCEPT (UPDATED WITH DYNAMIC COINS) =================
  Future<void> acceptChallenge(
    String challengeId,
    String fromUid,
    String toUid,
    Map<String, dynamic> challengeData, // Pass full map payload here
    BuildContext context,
  ) async {
    final firestore = FirebaseFirestore.instance;

    // Pull tier configuration from the original challenge intent data
    final String matchLevel = challengeData['level'] ?? 'Normal';
    final int dynamicStake = challengeData['stakePerPlayer'] ?? 200;
    final int dynamicPool = challengeData['bountyPool'] ?? 400;

    // 1. CREATE MATCH WITH DYNAMIC RULES LATCHED
    final matchRef = await firestore.collection('matches').add({
      'player1': fromUid,
      'player2': toUid,
      'status': 'active',

      'player1Ready': false,
      'player2Ready': false,

      // High-stakes ecosystem configuration parameters
      'level': matchLevel,
      'stakePerPlayer': dynamicStake,
      'bountyPool': dynamicPool,

      'rolesLocked': false,
      'gameStarted': false,

      'askerUid': null,
      'answererUid': null,

      'createdAt': FieldValue.serverTimestamp(),
    });

    // 2. UPDATE CHALLENGE
    await firestore.collection('challenges').doc(challengeId).update({
      'status': 'accepted',
      'matchStatus': 'active',
      'matchId': matchRef.id,
    });

    // 3. NAVIGATE IMMEDIATELY
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => MatchScreen(matchId: matchRef.id)),
    );
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Play 1v1")),

      body: Column(
        children: [
          // ================= WAITING =================
          StreamBuilder<QuerySnapshot>(
            stream: mySentChallenges(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox();

              final rawDocs = snapshot.data!.docs;

              final docs = {for (var d in rawDocs) d.id: d}.values.toList();
              if (docs.isEmpty) return const SizedBox();

              return Column(
                children: docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;

                  return Card(
                    color: Colors.yellow[100],
                    child: ListTile(
                      title: Text("Waiting for ${data['toName']} to accept"),
                      subtitle: Text(
                        "Level: ${data['level'] ?? 'Normal'} (${data['stakePerPlayer'] ?? 200} coins)",
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),

          // ================= ACCEPTED =================
          StreamBuilder<QuerySnapshot>(
            stream: acceptedByOthers(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox();

              final rawDocs = snapshot.data!.docs;

              final docs = {for (var d in rawDocs) d.id: d}.values.toList();
              if (docs.isEmpty) return const SizedBox();

              return Column(
                children: docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;

                  return Card(
                    color: Colors.green[100],
                    child: ListTile(
                      title: const Text("Challenge accepted"),
                      subtitle: const Text("Tap CONTINUE"),

                      trailing: ElevatedButton(
                        child: const Text("CONTINUE"),
                        onPressed: () {
                          final matchId = data['matchId'];

                          if (matchId == null) return;

                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                              builder: (_) => MatchScreen(matchId: matchId),
                            ),
                            (route) => false,
                          );
                        },
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),

          // ================= INCOMING CHALLENGES =================
          StreamBuilder<QuerySnapshot>(
            stream: incomingChallenges(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox();

              final rawDocs = snapshot.data!.docs;

              final docs = {for (var d in rawDocs) d.id: d}.values.toList();
              if (docs.isEmpty) return const SizedBox();

              return Column(
                children: docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final currentLevelName = data['level'] ?? 'Normal';
                  final currentStakeAmount = data['stakePerPlayer'] ?? 200;

                  return Card(
                    color: Colors.blue[100],
                    child: ListTile(
                      title: Text(
                        "${data['fromName']} challenged you ($currentLevelName)",
                      ),
                      subtitle: Text("Stakes: $currentStakeAmount Coins"),

                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ElevatedButton(
                            child: const Text("ACCEPT"),
                            onPressed: () async {
                              // Forward data packet payload directly over into dynamic initialization parser
                              await acceptChallenge(
                                doc.id,
                                data['fromUid'] ?? '',
                                uid,
                                data,
                                context,
                              );
                            },
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            child: const Text("DECLINE"),
                            onPressed: () {
                              FirebaseFirestore.instance
                                  .collection('challenges')
                                  .doc(doc.id)
                                  .update({'status': 'declined'});
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),

          const Divider(),

          // ================= USERS =================
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: getUsers(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final users = snapshot.data!.docs
                    .where((u) => u.id != uid)
                    .toList();

                return ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final data = users[index].data() as Map<String, dynamic>;

                    final otherUid = users[index].id;
                    final name = data['displayName'] ?? 'Unknown';

                    return FutureBuilder<bool>(
                      future: isFriend(otherUid),
                      builder: (context, snap) {
                        final friend = snap.data ?? false;

                        return ListTile(
                          title: Text(name),

                          trailing: ElevatedButton(
                            child: Text(friend ? "Challenge" : "Add Friend"),
                            onPressed: () {
                              if (friend) {
                                sendChallenge(otherUid, name);
                              } else {
                                addFriend(otherUid);
                              }
                            },
                          ),
                        );
                      },
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
