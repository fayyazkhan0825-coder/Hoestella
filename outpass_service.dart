import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/outpass_request.dart';

class OutpassService {
  final CollectionReference<Map<String, dynamic>> _outpassRef =
      FirebaseFirestore.instance.collection('outpass_requests');

  Future<void> createRequest(OutpassRequest request) async {
    await _outpassRef.add(request.toMap());
  }

  Future<OutpassRequest?> getRequestById(String id) async {
    final doc = await _outpassRef.doc(id).get();
    final data = doc.data();
    if (!doc.exists || data == null) return null;
    return OutpassRequest.fromMap(doc.id, data);
  }

  Stream<List<OutpassRequest>> streamStudentRequests(String studentId) {
    return _outpassRef
        .where('studentId', isEqualTo: studentId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => OutpassRequest.fromMap(d.id, d.data()))
              .toList(growable: false),
        );
  }

  Stream<List<OutpassRequest>> streamPendingForWarden() {
    return _outpassRef
        .where('status', isEqualTo: OutpassStatus.pending.name)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => OutpassRequest.fromMap(d.id, d.data()))
              .toList(growable: false),
        );
  }

  Stream<List<OutpassRequest>> streamApprovedForGuard() {
    return _outpassRef
        .where('status', isEqualTo: OutpassStatus.approved.name)
        .orderBy('exitDate', descending: false)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => OutpassRequest.fromMap(d.id, d.data()))
              .toList(growable: false),
        );
  }

  Stream<List<OutpassRequest>> streamAllForAdmin() {
    return _outpassRef.orderBy('createdAt', descending: true).snapshots().map(
          (snap) => snap.docs
              .map((d) => OutpassRequest.fromMap(d.id, d.data()))
              .toList(growable: false),
        );
  }

  Future<void> updateStatus({
    required String id,
    required OutpassStatus status,
    String? remarks,
  }) async {
    await _outpassRef.doc(id).update({
      'status': status.name,
      'wardenRemarks': remarks,
      'approvedAt': status == OutpassStatus.approved ? FieldValue.serverTimestamp() : null,
    });
  }

  Future<void> markExit(String id) async {
    await _outpassRef.doc(id).update({
      'exitMarkedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> markEntry(String id) async {
    await _outpassRef.doc(id).update({
      'entryMarkedAt': FieldValue.serverTimestamp(),
    });
  }
}

