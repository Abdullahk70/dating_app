import 'package:cloud_firestore/cloud_firestore.dart';

class Admin {
  String id;
  String email;
  String username;
  Timestamp createdAt;

  Admin({
    required this.id,
    required this.email,
    required this.username,
    required this.createdAt,
  });

  // Convert Admin object to Map for saving in Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'createdAt': createdAt,
    };
  }

  // Create Admin object from Map (for fetching from Firestore)
  factory Admin.fromMap(Map<String, dynamic> map) {
    return Admin(
      id: map['id'] ?? '',
      email: map['email'] ?? '',
      username: map['username'] ?? '',
      createdAt: map['createdAt'] ?? Timestamp.now(),
    );
  }
}
