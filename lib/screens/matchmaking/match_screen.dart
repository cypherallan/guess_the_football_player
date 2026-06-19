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

          print("UID: $uid");
          print("ASKER: ${data['askerUid']}");
          print("ANSWERER: ${data['answererUid']}");

          print("MATCH SCREEN OPENED");
          print("MATCH ID: ${widget.matchId}");
          print(data);

          final player1Ready = data['player1Ready'] ?? false;
          final player2Ready = data['player2Ready'] ?? false;
          final rolesLocked = data['rolesLocked'] ?? false;
          final gameStarted = data['gameStarted'] ?? false;

          if (!gameStarted &&
              player1Ready == true &&
              player2Ready == true &&
              rolesLocked == true) {
            matchRef.update({'gameStarted': true});
          }

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

          final askerUid = data['askerUid'];
          final answererUid = data['answererUid'];

          final isAsker = askerUid != null && askerUid.toString() == uid;
          final isAnswerer =
              answererUid != null && answererUid.toString() == uid;

          final isLockedIn = data['isLockedIn'] ?? false;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  children: [
                    Text("Player 1: ${data['player1Name'] ?? ''}"),
                    Text("Player 2: ${data['player2Name'] ?? ''}"),

                    const SizedBox(height: 10),

                    Text("Ready: $player1Ready"),
                    Text("Ready: $player2Ready"),

                    const SizedBox(height: 10),

                    if (rolesLocked)
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isAsker
                                  ? "🔥 YOU ASK THE QUESTIONS"
                                  : "🛡️ YOU ANSWER THE QUESTIONS",
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 10),

                            Text(
                              isAsker
                                  ? "Your score: ${data['score'] ?? 100}"
                                  : "Player score: ${data['score'] ?? 100}",
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      const Text("Waiting for game to start..."),
                  ],
                ),
              ),

              if (rolesLocked && isAsker)
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Text(
                    isLockedIn == true
                        ? "✅ Player locked in"
                        : "⏳ Waiting for opponent to lock in their footballer...",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
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

                        final questionId = docs[i].id;

                        final alreadyAnswered = docs.any((m) {
                          final d = m.data() as Map<String, dynamic>;

                          return d['type'] == 'answer' &&
                              d['questionId'] == questionId;
                        });

                        String? answerGiven;

                        if (alreadyAnswered) {
                          final answerDoc = docs.firstWhere((m) {
                            final d = m.data() as Map<String, dynamic>;

                            return d['type'] == 'answer' &&
                                d['questionId'] == questionId;
                          });

                          answerGiven =
                              (answerDoc.data()
                                  as Map<String, dynamic>)['text'];
                        }

                        if (msg['type'] == 'question') {
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      msg['text'] ?? '',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),

                                  if (isAsker && alreadyAnswered)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: answerGiven == "YES"
                                            ? Colors.green
                                            : Colors.red,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        answerGiven!,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),

                                  if (isAnswerer)
                                    alreadyAnswered
                                        ? SizedBox(
                                            width: 45,
                                            height: 35,
                                            child: ElevatedButton(
                                              onPressed: () {},
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    answerGiven == "YES"
                                                    ? Colors.green
                                                    : Colors.red,
                                              ),
                                              child: Icon(
                                                answerGiven == "YES"
                                                    ? Icons.check
                                                    : Icons.close,
                                                color: Colors.white,
                                                size: 18,
                                              ),
                                            ),
                                          )
                                        : Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              SizedBox(
                                                width: 45,
                                                height: 35,
                                                child: ElevatedButton(
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                        backgroundColor:
                                                            Colors.green,
                                                        padding:
                                                            EdgeInsets.zero,
                                                      ),
                                                  onPressed: () async {
                                                    await messagesRef.add({
                                                      'from': uid,
                                                      'type': 'answer',
                                                      'questionId': questionId,
                                                      'text': 'YES',
                                                      'createdAt':
                                                          FieldValue.serverTimestamp(),
                                                    });
                                                  },
                                                  child: const Icon(
                                                    Icons.check,
                                                    color: Colors.white,
                                                    size: 18,
                                                  ),
                                                ),
                                              ),

                                              const SizedBox(width: 6),

                                              SizedBox(
                                                width: 45,
                                                height: 35,
                                                child: ElevatedButton(
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                        backgroundColor:
                                                            Colors.red,
                                                        padding:
                                                            EdgeInsets.zero,
                                                      ),
                                                  onPressed: () async {
                                                    final match = await matchRef
                                                        .get();

                                                    final currentScore =
                                                        (match
                                                            .data()?['score'] ??
                                                        100);

                                                    await matchRef.update({
                                                      'score':
                                                          (currentScore - 10)
                                                              .clamp(0, 100),
                                                    });

                                                    await messagesRef.add({
                                                      'from': uid,
                                                      'type': 'answer',
                                                      'questionId': questionId,
                                                      'text': 'NO',
                                                      'createdAt':
                                                          FieldValue.serverTimestamp(),
                                                    });
                                                  },
                                                  child: const Icon(
                                                    Icons.close,
                                                    color: Colors.white,
                                                    size: 18,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                ],
                              ),
                            ),
                          );
                        }

                        return const SizedBox.shrink();
                      },
                    );
                  },
                ),
              ),

              const Divider(),

              // READY BUTTON
              if (!gameStarted && !rolesLocked)
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

              if (player1Ready && player2Ready && !gameStarted && !rolesLocked)
                Center(
                  child: ElevatedButton(
                    child: const Text("START MATCH"),
                    onPressed: () async {
                      final d =
                          (await matchRef.get()).data() as Map<String, dynamic>;

                      await matchRef.update({
                        'rolesLocked': true,
                        'askerUid': uid,
                        'answererUid': uid == d['player1']
                            ? d['player2']
                            : d['player1'],
                        'status': 'active',
                      });
                    },
                  ),
                ),

              // ASK
              if (gameStarted && rolesLocked && isAsker)
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
              if (rolesLocked && isAnswerer && !(isLockedIn == true))
                Column(
                  children: [
                    const Text("Choose your secret footballer"),

                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: TextField(
                        controller: _controller,
                        decoration: const InputDecoration(
                          hintText: "e.g Messi or Lionel Messi",
                        ),
                      ),
                    ),

                    ElevatedButton(
                      child: const Text("LOCK IN PLAYER"),
                      onPressed: () async {
                        if (_controller.text.isEmpty) return;

                        await matchRef.update({
                          'secretPlayer': _controller.text.trim().toLowerCase(),
                          'isLockedIn': true,
                        });

                        _controller.clear();
                      },
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
