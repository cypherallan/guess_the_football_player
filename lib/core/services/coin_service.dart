import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CoinService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String get uid => _auth.currentUser!.uid;

  // GET COINS STREAM (Keep this to display live balance on home/profile screens)
  Stream<int> getCoinsStream() {
    return _db.collection('users').doc(uid).snapshots().map((doc) {
      return doc.data()?['coins'] ?? 0;
    });
  }
}
