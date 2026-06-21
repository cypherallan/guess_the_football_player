import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<UserCredential?> signInWithGoogle() async {
    try {
      // WINDOWS
      if (Platform.isWindows) {
        final userCredential = await _auth.signInAnonymously();

        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .set({
              'uid': userCredential.user!.uid,
              'displayName': 'Windows Test User',
              'email': 'windows@test.local',
              'photoUrl': '',
              'playerId': 'WIN-${userCredential.user!.uid.substring(0, 6)}',
              'isOnline': true,
              'wins': 0,
              'losses': 0,
              'score': 0,
              'coins': 1000,
              'createdAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));

        return userCredential;
      }

      // ANDROID / MOBILE (v7 API)
      await GoogleSignIn.instance.initialize(
        serverClientId:
            '852476349759-auqj0gequklqf7eoq431nc44r823s32c.apps.googleusercontent.com',
      );

      final GoogleSignInAccount googleUser = await GoogleSignIn.instance
          .authenticate();

      final googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      return await _auth.signInWithCredential(credential);
    } catch (e, stack) {
      print('GOOGLE ERROR: $e');
      print(stack);
      rethrow;
    }
  }

  Future<void> signOut() async {
    await GoogleSignIn.instance.disconnect();
    await _auth.signOut();
  }
}
