import 'package:cloud_firestore/cloud_firestore.dart';

enum OutpassStatus { pending, approved, rejected }

class OutpassRequest {
  final String id;
  final String studentId;
  final String studentName;
  final String roomNumber;
  final String reason;
  final DateTime exitDateTime;
  final DateTime returnDateTime;
  final String parentPhone;
  final OutpassStatus status;
  final String? wardenRemarks;
  final DateTime createdAt;
  final DateTime? approvedAt;
  final DateTime? exitMarkedAt;
  final DateTime? entryMarkedAt;

  OutpassRequest({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.roomNumber,
    required this.reason,
    required this.exitDateTime,
    required this.returnDateTime,
    required this.parentPhone,
    required this.status,
    required this.createdAt,
    this.wardenRemarks,
    this.approvedAt,
    this.exitMarkedAt,
    this.entryMarkedAt,
  });

  factory OutpassRequest.fromMap(String id, Map<String, dynamic> data) {
    return OutpassRequest(
      id: id,
      studentId: data['studentId'] as String,
      studentName: data['studentName'] as String,
      roomNumber: data['roomNumber'] as String,
      reason: data['reason'] as String,
      exitDateTime: (data['exitDate'] as Timestamp).toDate(),
      returnDateTime: (data['returnDate'] as Timestamp).toDate(),
      parentPhone: data['parentPhone'] as String,
      status: _statusFromString(data['status'] as String),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      wardenRemarks: data['wardenRemarks'] as String?,
      approvedAt:
          data['approvedAt'] != null ? (data['approvedAt'] as Timestamp).toDate() : null,
      exitMarkedAt:
          data['exitMarkedAt'] != null ? (data['exitMarkedAt'] as Timestamp).toDate() : null,
      entryMarkedAt:
          data['entryMarkedAt'] != null ? (data['entryMarkedAt'] as Timestamp).toDate() : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'studentName': studentName,
      'roomNumber': roomNumber,
      'reason': reason,
      'exitDate': exitDateTime,
      'returnDate': returnDateTime,
      'parentPhone': parentPhone,
      'status': status.name,
      'createdAt': createdAt,
      'wardenRemarks': wardenRemarks,
      'approvedAt': approvedAt,
      'exitMarkedAt': exitMarkedAt,
      'entryMarkedAt': entryMarkedAt,
    };
  }

  OutpassRequest copyWith({
    OutpassStatus? status,
    String? wardenRemarks,
    DateTime? approvedAt,
    DateTime? exitMarkedAt,
    DateTime? entryMarkedAt,
  }) {
    return OutpassRequest(
      id: id,
      studentId: studentId,
      studentName: studentName,
      roomNumber: roomNumber,
      reason: reason,
      exitDateTime: exitDateTime,
      returnDateTime: returnDateTime,
      parentPhone: parentPhone,
      status: status ?? this.status,
      createdAt: createdAt,
      wardenRemarks: wardenRemarks ?? this.wardenRemarks,
      approvedAt: approvedAt ?? this.approvedAt,
      exitMarkedAt: exitMarkedAt ?? this.exitMarkedAt,
      entryMarkedAt: entryMarkedAt ?? this.entryMarkedAt,
    );
  }

  static OutpassStatus _statusFromString(String value) {
    switch (value) {
      case 'approved':
        return OutpassStatus.approved;
      case 'rejected':
        return OutpassStatus.rejected;
      case 'pending':
      default:
        return OutpassStatus.pending;
    }
  }
}

