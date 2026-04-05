import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/app_user.dart';

class FirestoreUserService {
  final CollectionReference<Map<String, dynamic>> _usersRef =
      FirebaseFirestore.instance.collection('users');

  Future<void> upsertUser(AppUser user) async {
    await _usersRef.doc(user.id).set(user.toMap(), SetOptions(merge: true));
  }

  Stream<List<AppUser>> streamUsersByRole(UserRole role) {
    return _usersRef.where('role', isEqualTo: role.name).snapshots().map(
          (snap) => snap.docs
              .map((d) => AppUser.fromMap(d.id, d.data()))
              .toList(growable: false),
        );
  }
}

