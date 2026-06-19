import 'package:cloud_firestore/cloud_firestore.dart';

class FriendService {
  final _db = FirebaseFirestore.instance;

  Future<void> sendFriendRequest({
    required String fromUid,
    required String toPlayerId,
  }) async {
    final users = await _db
        .collection('users')
        .where('playerId', isEqualTo: toPlayerId)
        .limit(1)
        .get();

    if (users.docs.isEmpty) {
      throw Exception("Player not found");
    }

    final toUid = users.docs.first.id;

    await _db.collection('friend_requests').add({
      'fromUid': fromUid,
      'toUid': toUid,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> acceptFriendRequest({
    required String requestId,
    required String fromUid,
    required String toUid,
  }) async {
    await _db.collection('friend_requests').doc(requestId).update({
      'status': 'accepted',
    });

    await _db
        .collection('friends')
        .doc(fromUid)
        .collection('list')
        .doc(toUid)
        .set({'friendUid': toUid, 'addedAt': FieldValue.serverTimestamp()});

    await _db
        .collection('friends')
        .doc(toUid)
        .collection('list')
        .doc(fromUid)
        .set({'friendUid': fromUid, 'addedAt': FieldValue.serverTimestamp()});
  }
}
