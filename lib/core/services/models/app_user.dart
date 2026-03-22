import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String uid;
  final String name;
  final String email;
  final String role;
  final String? sid;
  final String? batch;
  final String? degree;
  final String? faculty;
  final String? phone;
  final int streakCount;
  final DateTime? lastAdmitDate;
  final DateTime createdAt;
  final String? currentRoomFaculty;
  final String? currentRoomId;

  AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    this.sid,
    this.batch,
    this.degree,
    this.faculty,
    this.phone,
    required this.streakCount,
    required this.createdAt,
    this.lastAdmitDate,
    this.currentRoomFaculty,
    this.currentRoomId,
  });

  factory AppUser.fromMap(Map<String, dynamic> map, String documentId) {
    return AppUser(
      uid: documentId,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? 'student',
      sid: map['sid'],
      batch: map['batch'],
      degree: map['degree'],
      faculty: map['faculty'],
      phone: map['phone'],
      streakCount: map['streakCount'] ?? 0,
      lastAdmitDate: map['lastAdmitDate'] != null
          ? (map['lastAdmitDate'] as Timestamp).toDate()
          : null,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      currentRoomFaculty: map['currentRoomFaculty'],
      currentRoomId: map['currentRoomId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'role': role,
      'sid': sid,
      'batch': batch,
      'degree': degree,
      'faculty': faculty,
      'phone': phone,
      'streakCount': streakCount,
      'lastAdmitDate': lastAdmitDate,
      'createdAt': createdAt,
      'currentRoomFaculty': currentRoomFaculty,
      'currentRoomId': currentRoomId,
    };
  }
}