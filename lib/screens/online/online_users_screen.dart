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
  Future<void> sendInvite(String opponentId, String opponentName) async {
    await FirebaseFirestore.instance.collection('challenges').add({
      'fromUid': uid,
      'fromName': FirebaseAuth.instance.currentUser!.displayName ?? "Player",
      'toUid': opponentId,
      'toName': opponentName,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
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
      print("🔥 ONLINE USER SCREEN ACCEPT PRESSED");

      final firestore = FirebaseFirestore.instance;

      final challengeRef = firestore.collection('challenges').doc(challengeId);
      final snap = await challengeRef.get();

      if (!snap.exists) {
        _processingAccept = false;
        return;
      }

      final data = snap.data() as Map<String, dynamic>;

      if (data['status'] != 'pending') {
        _processingAccept = false;
        return;
      }

      // 1. CREATE MATCH
      final matchRef = await firestore.collection('matches').add({
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

      // 2. WAIT FOR WRITE TO COMPLETE
      await Future.delayed(const Duration(milliseconds: 300));

      // 3. UPDATE CHALLENGE WITH MATCH ID
      await challengeRef.update({
        'status': 'accepted',
        'acceptedBy': uid,
        'matchId': matchRef.id,
      });

      // 3. ADD FRIENDS
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

      await batch.commit();

      // 4. NAVIGATE
      _goToMatch(matchRef.id);
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
        children: [
          // ================= INVITES =================
          StreamBuilder<QuerySnapshot>(
            stream: getIncomingChallenges(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox();

              final invites = snapshot.data!.docs;

              if (invites.isEmpty) return const SizedBox();

              return Expanded(
                child: ListView(
                  children: invites.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;

                    return Card(
                      child: ListTile(
                        title: Text("Invite from ${data['fromName']}"),
                        subtitle: const Text("Tap accept to start match"),

                        trailing: ElevatedButton(
                          onPressed: () async {
                            if (_processingAccept) return;

                            await acceptInvite(
                              doc.id,
                              data['fromUid'],
                              data['fromName'],
                            );
                          },
                          child: const Text("ACCEPT"),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              );
            },
          ),

          const Divider(),

          // ================= ONLINE USERS =================
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

                return ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final data = users[index].data() as Map<String, dynamic>;

                    final opponentId = data['uid'] ?? users[index].id;
                    final opponentName = data['displayName'] ?? 'Unknown';

                    return ListTile(
                      title: Text(opponentName),
                      subtitle: const Text("Online"),

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
