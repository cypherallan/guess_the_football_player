import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CoinService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String get uid => _auth.currentUser!.uid;

  // GET COINS STREAM
  Stream<int> getCoinsStream() {
    return _db.collection('users').doc(uid).snapshots().map((doc) {
      return doc.data()?['coins'] ?? 0;
    });
  }

  // 💰 ADD COINS FROM FINAL SCORE
  Future<void> awardCoinsFromFinalScore(int finalScore) async {
    await _db.collection('users').doc(uid).update({
      'coins': FieldValue.increment(finalScore),
    });
  }

  Future<void> applyMatchCoins({
    required String uid,
    required int noAnswers,
    required int finalScore,
  }) async {
    final userRef = FirebaseFirestore.instance.collection('users').doc(uid);

    await FirebaseFirestore.instance.runTransaction((tx) async {
      final snap = await tx.get(userRef);

      final currentCoins = (snap['coins'] ?? 1000) as int;

      final penalty = noAnswers * 10;

      final newCoins = (currentCoins - penalty) + finalScore;

      tx.update(userRef, {'coins': newCoins});
    });
  }
}
