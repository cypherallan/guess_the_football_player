import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import '../../core/services/coin_service.dart';
import 'widgets/game_status_card.dart';
import 'widgets/post_game_card.dart';
import 'widgets/message_stream_view.dart';
import 'widgets/setup_game_view.dart';
import 'widgets/active_gameplay.dart';
import 'package:guess_the_footballer/screens/home/home_screen.dart';

class MatchScreen extends StatefulWidget {
  final String matchId;
  const MatchScreen({super.key, required this.matchId});

  @override
  State<MatchScreen> createState() => _MatchScreenState();
}

class _MatchScreenState extends State<MatchScreen> {
  bool _synced = false;
  bool _isQuitting = false; // FIX: Add this flag to track the quitter
  Timer? _askerTimer;
  // ... rest of your existing variables
  Timer? _answererTimer;
  int _timeLeft = 45;
  late DocumentReference matchRef;
  bool _coinsAwarded = false;
  final coinService = CoinService();
  int _noAnswers = 0;

  void _startTimer({required bool isAsker}) {
    _askerTimer?.cancel();
    _answererTimer?.cancel();
    setState(() => _timeLeft = 45);

    final timer = Timer.periodic(const Duration(seconds: 1), (t) async {
      setState(() => _timeLeft--);
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

        final current = await matchRef.get();
        final currentData = current.data() as Map<String, dynamic>;

        if (currentData['status'] != 'finished') {
          await _endMatchInFirestore(
            matchId: widget.matchId,
            updateData: {
              'status': 'finished',
              'winner': isAsker ? answererUid : askerUid,
              'score': score,
              'endedByTimeout': true,
              'endedAt': FieldValue.serverTimestamp(),
            },
          );
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

  Future<void> _exitMatch(String uid) async {
    final snap = await matchRef.get();
    if (!snap.exists) return;

    final data = snap.data() as Map<String, dynamic>;
    final player1 = data['player1'];
    final player2 = data['player2'];
    final opponent = uid == player1 ? player2 : player1;

    await _endMatchInFirestore(
      matchId: widget.matchId,
      updateData: {
        'status': 'finished',
        'winner': opponent,
        'exitReason': 'player_left',
        'endedAt': FieldValue.serverTimestamp(),
      },
    );
  }

  Future<void> _endMatchInFirestore({
    required String matchId,
    required Map<String, dynamic> updateData,
  }) async {
    _stopTimers(); // FIX: Force timers to stop locally immediately
    await matchRef.update(updateData);

    final challengeSnap = await FirebaseFirestore.instance
        .collection('challenges')
        .where('matchId', isEqualTo: matchId)
        .get();

    for (var doc in challengeSnap.docs) {
      await doc.reference.update({
        'matchStatus': 'finished',
        'status': 'completed',
      });
    }
  }

  Future<bool> _showQuitConfirmationDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Quit the game?"),
        content: const Text("This will end the match."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("NO"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("YES"),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    matchRef = FirebaseFirestore.instance
        .collection('matches')
        .doc(widget.matchId);
    final messagesRef = matchRef.collection('messages');

    return WillPopScope(
      onWillPop: () async {
        final shouldQuit = await _showQuitConfirmationDialog();
        if (shouldQuit) {
          // FIX: Mark as quitting locally first so this device skips the overlay
          setState(() => _isQuitting = true);

          await _exitMatch(uid);
          return true; // Allows the screen to close instantly
        }
        return false; // Blocks closing if they tap NO
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Match"),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              final shouldQuit = await _showQuitConfirmationDialog();
              if (!shouldQuit) return;

              // FIX: Add this state update here as well!
              setState(() => _isQuitting = true);

              await _exitMatch(uid);
              if (!context.mounted) return;

              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => HomeScreen()),
                (route) => false,
              );
            },
          ),
        ),
        body: StreamBuilder<DocumentSnapshot>(
          stream: matchRef.snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData)
              return const Center(child: CircularProgressIndicator());
            final doc = snapshot.data!;
            if (!doc.exists || doc.data() == null)
              return const Center(child: Text("Loading match..."));

            final data = doc.data() as Map<String, dynamic>;
            final rolesLocked = data['rolesLocked'] ?? false;
            final score = data['score'] ?? 100;
            final askerUid = data['askerUid'];
            final answererUid = data['answererUid'];
            final status = data['status'];
            final exitReason = data['exitReason'];
            if (status == 'finished') {
              _stopTimers();
            }
            // If a rematch starts, reset the local coinsAwarded flag so the new game can award coins again
            if (status == 'active' && _coinsAwarded) {
              _coinsAwarded = false;
            }

            final isAsker = askerUid != null && askerUid.toString() == uid;
            final isAnswerer =
                answererUid != null && answererUid.toString() == uid;

            // Stop background timers immediately if opponent leaves
            if (status == 'finished' && exitReason == 'player_left') {
              _stopTimers();
            }

            if (!_synced && data['friendsSynced'] != true) {
              _synced = true;
              WidgetsBinding.instance.addPostFrameCallback((_) async {
                final p1 = data['player1'];
                final p2 = data['player2'];
                await matchRef.update({'friendsSynced': true});
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(p1)
                    .collection('friends')
                    .doc(p2)
                    .set({'uid': p2});
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(p2)
                    .collection('friends')
                    .doc(p1)
                    .set({'uid': p1});
              });
            }

            //  NEW CODE - PASTE THIS EXACTLY:
            if (status == 'finished' && !_coinsAwarded) {
              _coinsAwarded = true;
              WidgetsBinding.instance.addPostFrameCallback((_) async {
                final finalScore = (data['score'] ?? 100) as int;
                int coinsChange = 0;

                // SCENARIO A: Normal Timeout or Correct Guess finish
                if (exitReason != 'player_left') {
                  if (isAsker) {
                    // Asker logic: Final Score awarded MINUS 10 coins for every "NO" answer received
                    final noAnswersPenalty = _noAnswers * 10;
                    coinsChange = finalScore - noAnswersPenalty;
                  } else if (isAnswerer) {
                    // Answerer logic: Gets 50 coins ONLY if the Asker drops down to 0 points
                    if (finalScore <= 0) {
                      coinsChange = 50;
                    }
                  }
                }
                // SCENARIO B: A Player Quit the Game
                else {
                  final winnerUid = data['winner'];
                  final isIWinner = (winnerUid == uid);

                  if (isIWinner) {
                    // The one who DID NOT quit:
                    if (finalScore > 0) {
                      // If match had a score, award that score as coins
                      coinsChange = finalScore;
                    } else {
                      // If match was at 0 points, award 50 coins
                      coinsChange = 50;
                    }
                  } else {
                    // The one WHO QUIT the game:
                    if (finalScore <= 0) {
                      // If they quit at 0 points, deduct 50 coins (-50)
                      coinsChange = -50;
                    }
                    // (Note: If they quit while score > 0, they get 0 coin change)
                  }
                }

                // Only hit the database if there's an actual addition or deduction to perform
                if (coinsChange != 0) {
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(uid)
                      .update({'coins': FieldValue.increment(coinsChange)});
                }
              });
            }

            return Stack(
              children: [
                // MAIN BACKGROUND CONTENT
                Column(
                  children: [
                    if (status == 'active')
                      Align(
                        alignment: Alignment.topRight,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                            child: const Text("QUIT"),
                            onPressed: () async {
                              final shouldQuit =
                                  await _showQuitConfirmationDialog();
                              if (!shouldQuit) return;

                              // FIX: Mark as quitting locally first so the overlay is ignored
                              setState(() => _isQuitting = true);

                              await _exitMatch(uid);

                              if (!context.mounted) return;

                              Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(builder: (_) => HomeScreen()),
                                (route) => false,
                              );
                            },
                          ),
                        ),
                      ),
                    GameStatusCard(
                      data: data,
                      rolesLocked: rolesLocked,
                      timeLeft: _timeLeft,
                      isAsker: isAsker,
                      score: score,
                    ),
                    PostGameCard(matchRef: matchRef, data: data, uid: uid),
                    const Divider(),
                    // NEW CODE (Replace it with this)
                    Expanded(
                      child: MessageStreamView(
                        messagesRef: messagesRef,
                        matchRef: matchRef,
                        data: data,
                        uid: uid,
                        isAsker: isAsker,
                        isAnswerer: isAnswerer,
                        onTriggerTimer: (isAnswerReceived) {
                          if (isAnswerReceived) {
                            // An answer came in: stop the Answerer's timer countdown and start the Asker's timer!
                            _startTimer(isAsker: true);
                          } else {
                            // A question was received: stop the Asker's countdown, reset time, and start the Answerer's countdown!
                            setState(() {
                              _timeLeft =
                                  45; // Reset countdown fresh to 45 seconds for the answerer
                            });
                            _startTimer(isAsker: false);
                          }
                        },
                        onIncrementNoAnswer: () => _noAnswers++,
                        onStopTimers: _stopTimers,
                      ),
                    ),
                    const Divider(),
                    SetupGameView(matchRef: matchRef, data: data, uid: uid),
                    ActiveGameplay(
                      matchRef: matchRef,
                      messagesRef: messagesRef,
                      data: data,
                      uid: uid,
                      isAsker: isAsker,
                      isAnswerer: isAnswerer,
                      score: score,
                      onStopTimers: _stopTimers,
                      coinsAwarded: _coinsAwarded,
                      onMarkCoinsAwarded: () =>
                          setState(() => _coinsAwarded = true),
                      coinService: coinService,
                    ),
                  ],
                ),

                // FIX: Added !_isQuitting check to hide it from the person who left
                if (status == 'finished' &&
                    exitReason == 'player_left' &&
                    !_isQuitting)
                  Stack(
                    children: [
                      ModalBarrier(
                        dismissible: false,
                        color: Colors.black.withOpacity(0.85),
                      ),
                      // ... your centered card widget

                      // The centered pop-up card
                      Center(
                        child: Card(
                          margin: const EdgeInsets.all(20),
                          elevation: 8,
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.warning_amber_rounded,
                                  color: Colors.red,
                                  size: 48,
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  "Opponent has quit the game",
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  "You have been awarded ${data['score'] ?? 0} points",
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 24),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    minimumSize: const Size(180, 45),
                                  ),
                                  onPressed: () {
                                    Navigator.of(context).pushAndRemoveUntil(
                                      MaterialPageRoute(
                                        builder: (_) => HomeScreen(),
                                      ),
                                      (route) => false,
                                    );
                                  },
                                  child: const Text("Return to Home"),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _askerTimer?.cancel();
    _stopTimers();
    _answererTimer?.cancel();
    super.dispose();
  }
}
