import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/admin_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Signup with email and password
  Future<User?> signUpWithEmailPassword(String email, String password) async {
    try {
      final UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = userCredential.user;
      if (user != null) {
        Admin admin = Admin(
          id: user.uid,
          email: user.email!,
          username: "Admin",
          createdAt: Timestamp.now(),
        );

        // You can store the admin object in a separate collection if needed
        await _firestore.collection('Users').doc(user.uid).set(admin.toMap());

        print("Signup and Admin creation successful!");
      }
      return userCredential.user;
    } catch (e) {
      print(e);
      return null;
    }
  }

  // Login with email and password
  Future<User?> loginWithEmailPassword(String email, String password) async {
    try {
      final UserCredential userCredential =
          await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } catch (e) {
      print(e);
      return null;
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Get current user
  User? getCurrentUser() {
    return _auth.currentUser;
  }
}
