import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<User?> signInWithEmail(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
          email: email.trim(), password: password.trim());
      return result.user;
    } catch (e) {
      return null;
    }
  }

  Future<String> signUpWithEmail({
    required String email,
    required String password,
    required String nickname,
    required String name,
    required String gender,
  }) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
          email: email.trim(), password: password.trim());

      if (result.user != null) {
        await _db.collection('users').doc(result.user!.uid).set({
          'uid': result.user!.uid,
          'email': email.trim(),
          'nickname': nickname.trim(),
          'name': name.trim(),
          'gender': gender,
          'createdAt': FieldValue.serverTimestamp(),
        });

        await _auth.signOut();
        await Future.delayed(const Duration(milliseconds: 500));
        return "success";
      }
      return "error";
    } on FirebaseAuthException catch (e) {
      return e.code;
    } catch (e) {
      return "error";
    }
  }
}