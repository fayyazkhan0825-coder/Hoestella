import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/announcement.dart';

class AnnouncementService {
  final CollectionReference<Map<String, dynamic>> _annRef =
      FirebaseFirestore.instance.collection('announcements');

  Future<void> createAnnouncement(Announcement ann) async {
    await _annRef.add(ann.toMap());
  }

  Stream<List<Announcement>> streamAnnouncements() {
    return _annRef
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => Announcement.fromMap(d.id, d.data()))
              .toList(growable: false),
        );
  }
}

