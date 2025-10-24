import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final fb.FirebaseAuth _auth = fb.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Current Firebase user
  fb.User? get currentUser => _auth.currentUser;

  // Email/password sign-in
  Future<fb.UserCredential> signInWithEmailAndPassword(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  // Email/password sign-up and create user profile with role=doctor
  Future<fb.UserCredential> signUpWithEmailAndPassword(String email, String password, String name) async {
    final cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
    await _firestore.collection('users').doc(cred.user!.uid).set({
      'id': cred.user!.uid,
      'name': name,
      'email': email,
      'role': 'doctor',
      'created_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    return cred;
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Send reset password email
  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // Update user profile fields in Firestore
  Future<void> updateUserProfile({String? name, String? email}) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (email != null) updates['email'] = email;
    if (updates.isEmpty) return;
    await _firestore.collection('users').doc(uid).set(updates, SetOptions(merge: true));
  }

  // Get profile from Firestore
  Future<Map<String, dynamic>?> getUserProfile() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    final snap = await _firestore.collection('users').doc(uid).get();
    return snap.data();
  }

  // Google Sign-In with Firebase
  Future<void> signInWithGoogle() async {
    final googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) throw Exception('Google sign-in aborted');
    final googleAuth = await googleUser.authentication;
    final credential = fb.GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    final cred = await _auth.signInWithCredential(credential);
    // Ensure Firestore user doc exists
    await _firestore.collection('users').doc(cred.user!.uid).set({
      'id': cred.user!.uid,
      'name': cred.user!.displayName,
      'email': cred.user!.email,
      'role': 'doctor',
      'created_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // Check if user has doctor role in Firestore
  Future<bool> isDoctor() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return false;
    final snap = await _firestore.collection('users').doc(uid).get();
    return (snap.data()?['role'] as String?) == 'doctor';
  }
}