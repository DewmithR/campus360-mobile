import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_user.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  final RegExp _nsbmStudentRegex =
      RegExp(r'^[a-zA-Z0-9._%+-]+@students\.nsbm\.ac\.lk$');

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String sid,
    required String batch,
    required String degree,
    required String faculty,
    required String phone,
  }) async {
    if (!_nsbmStudentRegex.hasMatch(email)) {
      throw FirebaseAuthException(
        code: 'invalid-email',
        message: 'Only NSBM student emails are allowed.',
      );
    }

    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = credential.user!;

    try {
      await user.sendEmailVerification();
    } catch (_) {}

    final appUser = AppUser(
      uid: user.uid,
      name: name,
      email: email,
      role: 'student',
      sid: sid,
      batch: batch,
      degree: degree,
      faculty: faculty,
      phone: phone,
      streakCount: 0,
      lastAdmitDate: null,
      createdAt: DateTime.now(),
    );

    await _firestore.collection('users').doc(user.uid).set(appUser.toMap());
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = credential.user!;

    if (!user.emailVerified) {
      await _auth.signOut();
      throw FirebaseAuthException(
        code: 'email-not-verified',
        message: 'Please verify your email before logging in.',
      );
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).delete();
      await user.delete();
    }
  }
}
