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

        if (isAsker) {
          await matchRef.update({'status': 'finished', 'winner': answererUid});
        } else {
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
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());
          final doc = snapshot.data!;
          if (!doc.exists || doc.data() == null)
            return const Center(child: Text("Loading match..."));

          final data = doc.data() as Map<String, dynamic>;
          final player1Ready = data['player1Ready'] ?? false;
          final player2Ready = data['player2Ready'] ?? false;
          final rolesLocked = data['rolesLocked'] ?? false;
          final gameStarted = data['gameStarted'] ?? false;
          final score = data['score'] ?? 100;
          final askerUid = data['askerUid'];
          final answererUid = data['answererUid'];
          final status = data['status'];

          final isAsker = askerUid != null && askerUid.toString() == uid;
          final isAnswerer =
              answererUid != null && answererUid.toString() == uid;

          if (player1Ready && player2Ready && rolesLocked && !gameStarted) {
            matchRef.update({'gameStarted': true});
          }

          // Friend sync logic execution loop
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
                onMarkCoinsAwarded: () => setState(() => _coinsAwarded = true),
                coinService: coinService,
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
