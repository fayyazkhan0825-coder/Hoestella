import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/app_user.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<AppUser?> authStateWithProfile() async* {
    await for (final user in _auth.authStateChanges()) {
      if (user == null) {
        yield null;
      } else {
        final docRef = _db.collection('users').doc(user.uid);
        final doc = await docRef.get();

        if (!doc.exists) {
          // Auto-create a basic profile for first-time logins
          final appUser = AppUser(
            id: user.uid,
            name: user.email ?? '',
            email: user.email ?? '',
            role: UserRole.student,
          );

          await docRef.set(appUser.toMap());
          yield appUser;
        } else {
          yield AppUser.fromMap(doc.id, doc.data()!);
        }
      }
    }
  }

  Future<AppUser?> signIn({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = credential.user;
    if (user == null) return null;

    final doc = await _db.collection('users').doc(user.uid).get();
    if (!doc.exists) return null;
    return AppUser.fromMap(doc.id, doc.data()!);
  }

  Future<AppUser?> signUp({
    required String email,
    required String password,
    required String name,
    required UserRole role,
    String? roomNumber,
    String? phone,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = credential.user;
    if (user == null) return null;

    final appUser = AppUser(
      id: user.uid,
      name: name,
      email: email,
      role: role,
      roomNumber: roomNumber,
      phone: phone,
    );

    await _db.collection('users').doc(user.uid).set(appUser.toMap());
    return appUser;
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Update phone verification status in Firestore
  Future<void> updatePhoneVerificationStatus(String uid) async {
    try {
      await _db.collection('users').doc(uid).update({
        'phoneVerified': true,
      });
    } catch (e) {
      throw Exception('Failed to update phone verification: $e');
    }
  }
}

