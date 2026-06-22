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
  Timer? _askerTimer;
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
          await matchRef.update({
            'status': 'finished',
            'winner': isAsker ? answererUid : askerUid,
            'score': score,
            'endedByTimeout': true,
            'endedAt': FieldValue.serverTimestamp(),
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

  Future<void> _exitMatch(String uid) async {
    final snap = await matchRef.get();
    if (!snap.exists) return;

    final data = snap.data() as Map<String, dynamic>;
    final player1 = data['player1'];
    final player2 = data['player2'];
    final opponent = uid == player1 ? player2 : player1;

    await matchRef.update({
      'status': 'finished',
      'winner': opponent,
      'exitReason': 'player_left',
      'endedAt': FieldValue.serverTimestamp(),
    });
  }

  // Visual demonstration of dialog structure requested by user preferences
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
          await _exitMatch(uid);
          return true; // Returning true allows the route stack to safely pop exactly once
        }
        return false; // Blocks pop if user selected "NO"
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Match"),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            // safely passes back control loop to WillPopScope
            onPressed: () async {
              final shouldQuit = await _showQuitConfirmationDialog();

              if (!shouldQuit) return;

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

            final isAsker = askerUid != null && askerUid.toString() == uid;
            final isAnswerer =
                answererUid != null && answererUid.toString() == uid;

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
                        // safely passes control loop to WillPopScope
                        onPressed: () async {
                          final shouldQuit =
                              await _showQuitConfirmationDialog();

                          if (!shouldQuit) return;

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
                Expanded(
                  child: MessageStreamView(
                    messagesRef: messagesRef,
                    matchRef: matchRef,
                    data: data,
                    uid: uid,
                    isAsker: isAsker,
                    isAnswerer: isAnswerer,
                    onTriggerTimer: (askerMode) =>
                        _startTimer(isAsker: askerMode),
                    onIncrementNoAnswer: () => _noAnswers++,
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
            );
          },
        ),
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
