import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MatchScreen extends StatefulWidget {
  final String matchId;

  const MatchScreen({super.key, required this.matchId});

  @override
  State<MatchScreen> createState() => _MatchScreenState();
}

class _MatchScreenState extends State<MatchScreen> {
  final TextEditingController _controller = TextEditingController();

  bool _synced = false;

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final matchRef = FirebaseFirestore.instance
        .collection('matches')
        .doc(widget.matchId);

    final messagesRef = matchRef.collection('messages');

    return Scaffold(
      appBar: AppBar(title: const Text("Match")),

      body: StreamBuilder<DocumentSnapshot>(
        stream: matchRef.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final doc = snapshot.data!;

          // ✅ FIX 4: proper null-safe handling (NO CAST CRASH)
          if (!doc.exists || doc.data() == null) {
            return const Center(child: Text("Loading match..."));
          }

          final data = doc.data() as Map<String, dynamic>;

          print("MATCH SCREEN OPENED");
          print("MATCH ID: ${widget.matchId}");
          print(data);

          

          // ================= FRIEND SYNC (RUN ONCE ONLY) =================
          if (!_synced && data['friendsSynced'] != true) {
            _synced = true;

            matchRef.update({'friendsSynced': true});

            final p1 = data['player1'];
            final p2 = data['player2'];

            FirebaseFirestore.instance
                .collection('users')
                .doc(p1)
                .collection('friends')
                .doc(p2)
                .set({'uid': p2});

            FirebaseFirestore.instance
                .collection('users')
                .doc(p2)
                .collection('friends')
                .doc(p1)
                .set({'uid': p1});

            print("🟢 Friends synced in match screen");
          }

          final player1Ready = data['player1Ready'] ?? false;
          final player2Ready = data['player2Ready'] ?? false;
          final rolesLocked = data['rolesLocked'] ?? false;

          final askerUid = data['askerUid'];
          final answererUid = data['answererUid'];

          final isAsker = uid == askerUid;
          final isAnswerer = uid == answererUid;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  children: [
                    Text("Player 1: ${data['player1Name'] ?? ''}"),
                    Text("Ready: $player1Ready"),
                    const SizedBox(height: 10),
                    Text("Player 2: ${data['player2Name'] ?? ''}"),
                    Text("Ready: $player2Ready"),
                  ],
                ),
              ),

              const Divider(),

              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: messagesRef.orderBy('createdAt').snapshots(),
                  builder: (context, snap) {
                    if (!snap.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final docs = snap.data!.docs;

                    return ListView.builder(
                      itemCount: docs.length,
                      itemBuilder: (context, i) {
                        final msg = docs[i].data() as Map<String, dynamic>;

                        return ListTile(
                          title: Text(msg['text'] ?? ''),
                          subtitle: Text(msg['type'] ?? ''),
                        );
                      },
                    );
                  },
                ),
              ),

              const Divider(),

              // READY BUTTON
              if (!rolesLocked)
                ElevatedButton(
                  onPressed: () async {
                    final d =
                        (await matchRef.get()).data() as Map<String, dynamic>;

                    if (d['player1'] == uid) {
                      await matchRef.update({'player1Ready': true});
                    } else {
                      await matchRef.update({'player2Ready': true});
                    }
                  },
                  child: const Text("READY"),
                ),

              // ROLE SELECTION
              if (player1Ready && player2Ready && !rolesLocked)
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          final d =
                              (await matchRef.get()).data()
                                  as Map<String, dynamic>;

                          await matchRef.update({
                            'rolesLocked': true,
                            'askerUid': uid,
                            'answererUid': uid == d['player1']
                                ? d['player2']
                                : d['player1'],
                            'status': 'active',
                          });
                        },
                        child: const Text("ASK QUESTIONS"),
                      ),
                    ),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          final d =
                              (await matchRef.get()).data()
                                  as Map<String, dynamic>;

                          await matchRef.update({
                            'rolesLocked': true,
                            'answererUid': uid,
                            'askerUid': uid == d['player1']
                                ? d['player2']
                                : d['player1'],
                            'status': 'active',
                          });
                        },
                        child: const Text("ANSWER QUESTIONS"),
                      ),
                    ),
                  ],
                ),

              // ASK
              if (rolesLocked && isAsker)
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        decoration: const InputDecoration(
                          hintText: "Ask question...",
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: () async {
                        if (_controller.text.isEmpty) return;

                        await messagesRef.add({
                          'from': uid,
                          'type': 'question',
                          'text': _controller.text,
                          'createdAt': FieldValue.serverTimestamp(),
                        });

                        _controller.clear();
                      },
                    ),
                  ],
                ),

              // ANSWER
              if (rolesLocked && isAnswerer)
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          await messagesRef.add({
                            'from': uid,
                            'type': 'answer',
                            'text': "YES",
                            'createdAt': FieldValue.serverTimestamp(),
                          });
                        },
                        child: const Text("YES"),
                      ),
                    ),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          await messagesRef.add({
                            'from': uid,
                            'type': 'answer',
                            'text': "NO",
                            'createdAt': FieldValue.serverTimestamp(),
                          });
                        },
                        child: const Text("NO"),
                      ),
                    ),
                  ],
                ),
            ],
          );
        },
      ),
    );
  }
}
