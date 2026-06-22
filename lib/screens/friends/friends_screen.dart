import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../matchmaking/match_screen.dart';

class FriendsScreen extends StatelessWidget {
  FriendsScreen({super.key});

  final uid = FirebaseAuth.instance.currentUser!.uid;

  // ================= USERS =================
  Stream<QuerySnapshot> getUsers() {
    return FirebaseFirestore.instance.collection('users').snapshots();
  }

  Stream<QuerySnapshot> incomingChallenges() {
    return FirebaseFirestore.instance
        .collection('challenges')
        .where('toUid', isEqualTo: uid)
        .snapshots();
  }

  // ================= SENT CHALLENGES =================
  Stream<QuerySnapshot> mySentChallenges() {
    return FirebaseFirestore.instance
        .collection('challenges')
        .where('fromUid', isEqualTo: uid)
        .where('status', isEqualTo: 'pending')
        .snapshots();
  }

  // ================= ACCEPTED (FIXED) =================
  Stream<QuerySnapshot> acceptedByOthers() {
    return FirebaseFirestore.instance
        .collection('challenges')
        .where('participants', arrayContains: uid)
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

  // ================= SEND CHALLENGE =================
  Future<void> sendChallenge(String otherUid, String name) async {
    await FirebaseFirestore.instance.collection('challenges').add({
      'fromUid': uid,
      'fromName': FirebaseAuth.instance.currentUser!.displayName ?? "Player",
      'toUid': otherUid,
      'toName': name,
      'status': 'pending',

      // 🔥 FIX: IMPORTANT
      'participants': [uid, otherUid],

      'matchId': null,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // ================= ACCEPT =================
  Future<void> acceptChallenge(
    String challengeId,
    String fromUid,
    String toUid,
    BuildContext context,
  ) async {
    final firestore = FirebaseFirestore.instance;

    // 1. CREATE MATCH
    final matchRef = await firestore.collection('matches').add({
      'player1': fromUid,
      'player2': toUid,
      'status': 'active',

      'player1Ready': false,
      'player2Ready': false,

      'score': 100,

      'rolesLocked': false,
      'gameStarted': false,

      'askerUid': null,
      'answererUid': null,

      'createdAt': FieldValue.serverTimestamp(),
    });

    // 2. UPDATE CHALLENGE
    await firestore.collection('challenges').doc(challengeId).update({
      'status': 'accepted',
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
                      subtitle: const Text("Challenge sent"),
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
                      title: Text("Challenge accepted"),
                      subtitle: const Text("Tap CONTINUE"),

                      trailing: ElevatedButton(
                        child: const Text("CONTINUE"),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  MatchScreen(matchId: data['matchId']),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),

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

                  return Card(
                    color: Colors.blue[100],
                    child: ListTile(
                      title: Text("${data['fromName']} challenged you"),
                      subtitle: const Text("Accept or decline"),

                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ElevatedButton(
                            child: const Text("ACCEPT"),
                            onPressed: () async {
                              final matchRef = await FirebaseFirestore.instance
                                  .collection('matches')
                                  .add({
                                    'player1': data['fromUid'],
                                    'player2': uid,
                                    'score': 100,
                                    'status': 'active',
                                    'createdAt': FieldValue.serverTimestamp(),
                                  });

                              await FirebaseFirestore.instance
                                  .collection('challenges')
                                  .doc(doc.id)
                                  .update({
                                    'status': 'accepted',
                                    'matchId': matchRef.id,
                                  });

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      MatchScreen(matchId: matchRef.id),
                                ),
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
