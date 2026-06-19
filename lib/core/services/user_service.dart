import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserService {
  final _db = FirebaseFirestore.instance;

  Future<void> createUserIfNotExists(User user) async {
    final ref = _db.collection('users').doc(user.uid);

    final doc = await ref.get();

    if (doc.exists) return;

    final playerId = _generatePlayerId(user.displayName ?? 'player');

    await ref.set({
      'uid': user.uid,
      'displayName': user.displayName,
      'email': user.email,
      'photoUrl': user.photoURL,
      'playerId': playerId,

      'isOnline': true,
      'lastSeen': FieldValue.serverTimestamp(),

      'wins': 0,
      'losses': 0,
      'score': 0,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  String _generatePlayerId(String name) {
    final short = name.replaceAll(' ', '').toLowerCase();
    final random = DateTime.now().millisecondsSinceEpoch % 9000 + 1000;
    return '$short#$random';
  }
}
