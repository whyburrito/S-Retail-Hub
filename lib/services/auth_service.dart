import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  int _attempts = 0;
  DateTime? _lockUntil;

  Future<String?> login(String email, String password) async {
    if (_lockUntil != null &&
        DateTime.now().isBefore(_lockUntil!)) {
      return "Too many attempts. Try again in 30 seconds.";
    }

    try {
      await _auth.signInWithEmailAndPassword(
          email: email, password: password);

      _attempts = 0;
      return null;
    } on FirebaseAuthException {
      _attempts++;

      if (_attempts >= 3) {
        _lockUntil = DateTime.now().add(
          const Duration(seconds: 30),
        );
        _attempts = 0;
        return "Too many failed attempts. Wait 30 seconds.";
      }

      return "Invalid email or password.";
    }
  }

  Future<String?> register(
      String email, String password, String role) async {
    try {
      UserCredential cred =
      await _auth.createUserWithEmailAndPassword(
          email: email, password: password);

      await _firestore
          .collection('users')
          .doc(cred.user!.uid)
          .set({
        'email': email,
        'role': role,
      });

      return null;
    } on FirebaseAuthException catch (e) {
      return e.message ?? "An unknown error occurred.";
    }
  }

  Future<String> getUserRole() async {
    String uid = _auth.currentUser!.uid;
    DocumentSnapshot doc =
    await _firestore.collection('users').doc(uid).get();
    return doc['role'];
  }

  Future<void> logout() async {
    await _auth.signOut();
  }
}