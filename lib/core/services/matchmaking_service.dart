import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MatchmakingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// ⚠️ NOTE: This is NOT safe matchmaking logic yet, but OK for your current stage
  Stream<QuerySnapshot> watchForMatch(String uid) {
    return FirebaseFirestore.instance
        .collection('matches')
        .where('player1', isEqualTo: uid)
        .snapshots();
  }

  /// Add player to matchmaking queue
  Future<void> joinQueue() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    await _firestore.collection('matchmaking').doc(user.uid).set({
      'uid': user.uid,
      'displayName': user.displayName ?? 'Unknown Player',
      'photoUrl': user.photoURL ?? '',
      'searching': true,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  /// Find opponent and create match
  Future<String?> findMatch() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return null;

    final snapshot = await _firestore
        .collection('matchmaking')
        .where('searching', isEqualTo: true)
        .get();

    if (snapshot.docs.length < 2) {
      return null;
    }

    final opponent = snapshot.docs.firstWhere((doc) => doc.id != user.uid);

    final opponentId = opponent.id;

    // 🔥 FETCH REAL USER PROFILE FROM FIRESTORE USERS COLLECTION
    final opponentUserDoc = await _firestore
        .collection('users')
        .doc(opponentId)
        .get();

    final opponentUserData = opponentUserDoc.data();

    final opponentName = opponentUserData?['displayName'] ?? 'Player 2';

    final matchRef = await _firestore.collection('matches').add({
      'player1': user.uid,
      'player2': opponent.id,

      'player1Name': user.displayName ?? 'Player 1',
      'player2Name': opponentName,

      'player1Ready': false,
      'player2Ready': false,

      'currentTurn': user.uid,

      'status': 'waiting',
      'winner': null,

      'createdAt': FieldValue.serverTimestamp(),
    });

    await _firestore.collection('matchmaking').doc(user.uid).delete();
    await _firestore.collection('matchmaking').doc(opponent.id).delete();

    return matchRef.id;
  }

  /// Leave matchmaking queue
  Future<void> leaveQueue() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    await _firestore.collection('matchmaking').doc(user.uid).delete();
  }
}
