import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import '../../core/services/coin_service.dart';

class MatchScreen extends StatefulWidget {
  final String matchId;

  const MatchScreen({super.key, required this.matchId});

  @override
  State<MatchScreen> createState() => _MatchScreenState();
}

class _MatchScreenState extends State<MatchScreen> {
  final TextEditingController _controller = TextEditingController();
  final TextEditingController _guessController = TextEditingController();

  bool _synced = false;

  Timer? _askerTimer;
  Timer? _answererTimer;
  int _timeLeft = 45;
  late DocumentReference matchRef;
  bool _coinsAwarded = false;
  final coinService = CoinService();
  int _noAnswers = 0;

  String? _lastQuestionId;
  String? _lastAnswerId;

  void _startTimer({required bool isAsker}) {
    _askerTimer?.cancel();
    _answererTimer?.cancel();

    setState(() {
      _timeLeft = 45;
    });

    final timer = Timer.periodic(const Duration(seconds: 1), (t) async {
      setState(() {
        _timeLeft--;
      });

      if (_timeLeft <= 0) {
        t.cancel();

        final match = await FirebaseFirestore.instance
            .collection('matches')
            .doc(widget.matchId)
            .get();

        final data = match.data() as Map<String, dynamic>;

        final askerUid = data['askerUid'];
        final answererUid = data['answererUid'];
        final score = data['score'] ?? 100;

        if (isAsker) {
          // ASKER FAILED → LOSES
          await matchRef.update({'status': 'finished', 'winner': answererUid});
        } else {
          // ANSWERER FAILED → LOSES, ASKER WINS
          await matchRef.update({
            'status': 'finished',
            'winner': askerUid,
            'score': score,
          });
        }
      }
    });

    if (isAsker) {
      _askerTimer = timer;
    } else {
      _answererTimer = timer;
    }
  }

  void _stopTimers() {
    _askerTimer?.cancel();
    _answererTimer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    matchRef = FirebaseFirestore.instance
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

          final score = data['score'] ?? 100;
          final opponentUid = uid == data['player1']
              ? data['player2']
              : data['player1'];

          final myRematch = data['${uid}_rematch'];
          final opponentRematch = data['${opponentUid}_rematch'];
          final opponentName = uid == data['player1']
              ? data['player2Name']
              : data['player1Name'];

          if (player1Ready && player2Ready && rolesLocked && !gameStarted) {
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
          final winner = data['winner'];
          final status = data['status'];

          if (status == 'finished' && !_coinsAwarded) {
            _coinsAwarded = true;

            WidgetsBinding.instance.addPostFrameCallback((_) {
              CoinService().applyMatchCoins(
                uid: FirebaseAuth.instance.currentUser!.uid,
                noAnswers: _noAnswers,
                finalScore: (data['score'] ?? 0),
              );
            });
          }
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
                              "⏱️ $_timeLeft seconds left",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: _timeLeft <= 10
                                    ? Colors.red
                                    : Colors.black,
                              ),
                            ),

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
                                  ? "Your score: $score"
                                  : "Player ${data['player1Name'] ?? ''} score: $score",
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

              if (status == 'finished')
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
                      if (winner == uid)
                        const Text(
                          "🏆 YOU GUESSED THE PLAYER!",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      else
                        const Text(
                          "🎯 OPPONENT GUESSED THE PLAYER!",
                          style: TextStyle(
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

              if (status == 'finished')
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
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 10),

                      const Text("Would you like to play again?"),

                      const SizedBox(height: 15),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton(
                            onPressed: () async {
                              await matchRef.update({
                                '${uid}_rematch': 'requested',
                              });
                            },
                            child: const Text("YES"),
                          ),

                          const SizedBox(width: 20),

                          ElevatedButton(
                            onPressed: () async {
                              await matchRef.update({
                                '${uid}_rematch': 'declined',
                                'status': 'finished', // 👈 ADD THIS
                              });
                            },
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
                              await matchRef.update({
                                '${uid}_rematch': 'accepted',
                              });

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
                            onPressed: () async {
                              await matchRef.update({
                                '${uid}_rematch': 'declined',
                                'status': 'finished', // 👈 ADD THIS
                              });
                            },
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
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text("SEARCH NEW OPPONENT"),
                      ),
                    ],
                  ),
                ),

              if (rolesLocked && isAsker && status != 'finished')
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

                    // 🔥 BEST PLACE (runs once per stream update)
                    final latestMessage = docs.isNotEmpty
                        ? docs.last.data() as Map<String, dynamic>
                        : null;

                    if (latestMessage != null &&
                        latestMessage['type'] == 'question') {
                      if (isAnswerer &&
                          _lastQuestionId != latestMessage['questionId']) {
                        _lastQuestionId = latestMessage['questionId'];

                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          _startTimer(isAsker: false);
                        });
                      }
                    }

                    for (var doc in docs) {
                      final data = doc.data() as Map<String, dynamic>;

                      // ANSWER ARRIVED → START ASKER TIMER
                      if (data['type'] == 'answer' &&
                          data['questionId'] != null) {
                        if (_lastAnswerId != doc.id && isAsker) {
                          _lastAnswerId = doc.id;

                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            _startTimer(isAsker: true);
                          });
                        }
                      }
                    }

                    return ListView.builder(
                      itemCount: docs.length,
                      itemBuilder: (context, i) {
                        final msg = docs[i].data() as Map<String, dynamic>;

                        final questionId = msg['questionId'] ?? docs[i].id;

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

                        if (msg['type'] == 'guess' && isAnswerer) {
                          final guessId = docs[i].id;

                          final secret = (data['secretPlayer'] ?? '')
                              .toString()
                              .toLowerCase()
                              .replaceAll(RegExp(r'[^a-z\s]'), '')
                              .trim();

                          final guessText = (msg['text'] ?? '')
                              .toString()
                              .toLowerCase()
                              .replaceAll(RegExp(r'[^a-z\s]'), '')
                              .trim();

                          final isCorrectGuess =
                              secret == guessText ||
                              guessText.contains(secret) ||
                              secret.contains(guessText);

                          return Card(
                            color: Colors.orange[100],
                            child: ListTile(
                              title: Text("Opponent guessed: ${msg['text']}"),
                              subtitle: const Text("Confirm result"),

                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.check,
                                      color: Colors.green,
                                    ),
                                    onPressed: isCorrectGuess
                                        ? () async {
                                            await matchRef.update({
                                              'winner': data['askerUid'],
                                              'winningGuess': guessText,
                                              'status': 'finished',
                                            });

                                            await messagesRef.add({
                                              'type': 'guess_response',
                                              'guessId': guessId,
                                              'response': 'confirmed',
                                              'createdAt':
                                                  FieldValue.serverTimestamp(),
                                            });
                                          }
                                        : null, // ❌ disabled if wrong
                                  ),

                                  IconButton(
                                    icon: const Icon(
                                      Icons.close,
                                      color: Colors.red,
                                    ),
                                    onPressed: !isCorrectGuess
                                        ? () async {
                                            final currentScore =
                                                data['score'] ?? 100;

                                            await matchRef.update({
                                              'score': currentScore - 10,
                                            });

                                            await messagesRef.add({
                                              'type': 'guess_response',
                                              'guessId': guessId,
                                              'response': 'declined',
                                              'createdAt':
                                                  FieldValue.serverTimestamp(),
                                            });
                                          }
                                        : null, // ❌ disabled if correct
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        if (msg['type'] == 'guess_response' && isAsker) {
                          return Card(
                            color: Colors.grey.shade200,
                            child: ListTile(
                              title: Text("Your guess result"),
                              subtitle: Text(
                                msg['response'] == 'confirmed'
                                    ? "Correct guess 🎉"
                                    : "❌ Incorrect guess",
                              ),
                            ),
                          );
                        }

                        if (msg['type'] == 'question') {
                          if (isAnswerer && questionId != _lastQuestionId) {
                            _lastQuestionId = questionId;

                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              _startTimer(isAsker: false);
                            });
                          }
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
                                                    if (isAsker) {
                                                      _startTimer(
                                                        isAsker: true,
                                                      );
                                                    }
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
                                                    _noAnswers++; // 👈 ADD THIS

                                                    await matchRef.update({
                                                      'score':
                                                          (data['score'] ??
                                                              100) -
                                                          10,
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

              // ASK
              if (rolesLocked && isAsker && status != 'finished')
                Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            decoration: const InputDecoration(
                              hintText: "Ask a question...",
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

                            await matchRef.update({
                              'lastQuestionTime': FieldValue.serverTimestamp(),
                            });

                            _controller.clear();

                            _stopTimers(); // 👈 STOP HERE
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        child: const Text("GUESS THE PLAYER"),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (_) {
                              return AlertDialog(
                                title: const Text("Guess The Footballer"),

                                content: TextField(
                                  controller: _guessController,
                                  decoration: const InputDecoration(
                                    hintText: "Enter footballer name",
                                  ),
                                ),

                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                    },
                                    child: const Text("CANCEL"),
                                  ),

                                  ElevatedButton(
                                    onPressed: () async {
                                      if (_guessController.text.isEmpty) return;

                                      _stopTimers();

                                      await FirebaseFirestore.instance
                                          .collection('users')
                                          .doc(uid)
                                          .update({
                                            'coins': FieldValue.increment(
                                              score,
                                            ),
                                          });
                                      if (!_coinsAwarded) {
                                        _coinsAwarded = true;
                                        await coinService
                                            .awardCoinsFromFinalScore(score);
                                      } // 👈 STOP TIMER ON GUESS

                                      await messagesRef.add({
                                        'from': uid,
                                        'type': 'guess',
                                        'text': _guessController.text
                                            .trim()
                                            .toLowerCase(),
                                        'status': 'pending',
                                        'createdAt':
                                            FieldValue.serverTimestamp(),
                                      });

                                      _guessController.clear();
                                      Navigator.pop(context);
                                    },
                                    child: const Text("SUBMIT"),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),

              if (rolesLocked && isAnswerer)
                Container(
                  margin: const EdgeInsets.all(10),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "🛡️ Your locked in player is: ${data['secretPlayer'] ?? 'Not set'}",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),

              // ANSWER
              if (rolesLocked &&
                  isAnswerer &&
                  !(isLockedIn == true) &&
                  status != 'finished')
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

  @override
  void dispose() {
    _askerTimer?.cancel();
    _answererTimer?.cancel();
    super.dispose();
  }
}
