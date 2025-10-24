import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DoctorRegistrationService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Register a new doctor
  Future<bool> registerDoctor({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String licenseNumber,
    required String specialization,
    required int experienceYears,
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      await _firestore.collection('users').doc(cred.user!.uid).set({
        'id': cred.user!.uid,
        'name': name,
        'email': email,
        'phone': phone,
        'role': 'doctor',
        'license_number': licenseNumber,
        'specialization': specialization,
        'experience_years': experienceYears,
        'availability_status': 'available',
        'created_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      return true;
    } catch (e) {
      print('Error registering doctor: $e');
      return false;
    }
  }

  // Get all doctors (for admin purposes)
  Future<List<Map<String, dynamic>>> getAllDoctors() async {
    try {
      final snap = await _firestore.collection('users').where('role', isEqualTo: 'doctor').orderBy('name').get();
      return snap.docs.map((d) => ({...d.data(), 'id': d.id})).toList();
    } catch (e) {
      print('Error getting all doctors: $e');
      return [];
    }
  }

  // Get available doctors
  Future<List<Map<String, dynamic>>> getAvailableDoctors() async {
    try {
      final snap = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'doctor')
          .where('availability_status', isEqualTo: 'available')
          .orderBy('name')
          .get();
      return snap.docs.map((d) => ({...d.data(), 'id': d.id})).toList();
    } catch (e) {
      print('Error getting available doctors: $e');
      return [];
    }
  }

  // Get doctor by ID
  Future<Map<String, dynamic>?> getDoctorById(String doctorId) async {
    try {
      final doc = await _firestore.collection('users').doc(doctorId).get();
      return doc.data();
    } catch (e) {
      print('Error getting doctor by ID: $e');
      return null;
    }
  }

  // Update doctor profile
  Future<bool> updateDoctorProfile(String doctorId, Map<String, dynamic> updates) async {
    try {
      await _firestore.collection('users').doc(doctorId).set(updates, SetOptions(merge: true));
      return true;
    } catch (e) {
      print('Error updating doctor profile: $e');
      return false;
    }
  }

  // Update doctor availability status
  Future<bool> updateDoctorAvailability(String doctorId, String status) async {
    try {
      await _firestore.collection('users').doc(doctorId).set({'availability_status': status}, SetOptions(merge: true));
      return true;
    } catch (e) {
      print('Error updating doctor availability: $e');
      return false;
    }
  }

  // Get doctor statistics
  Future<Map<String, dynamic>> getDoctorStats(String doctorId) async {
    try {
      final total = await _firestore.collection('appointments').where('assigned_doctor', isEqualTo: doctorId).get();
      final pending = await _firestore
          .collection('appointments')
          .where('assigned_doctor', isEqualTo: doctorId)
          .where('status', isEqualTo: 'pending')
          .get();
      final completed = await _firestore
          .collection('appointments')
          .where('assigned_doctor', isEqualTo: doctorId)
          .where('status', isEqualTo: 'completed')
          .get();
      return {
        'total': total.docs.length,
        'pending': pending.docs.length,
        'completed': completed.docs.length,
      };
    } catch (e) {
      print('Error getting doctor stats: $e');
      return {};
    }
  }

  // Verify doctor credentials (for login)
  Future<bool> verifyDoctorCredentials(String email, String password) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(email: email, password: password);
      final doc = await _firestore.collection('users').doc(cred.user!.uid).get();
      return (doc.data()?['role'] == 'doctor');
    } catch (e) {
      print('Error verifying doctor credentials: $e');
      return false;
    }
  }

  // Get doctor's appointments
  Future<List<Map<String, dynamic>>> getDoctorAppointments(String doctorId) async {
    try {
      final snap = await _firestore
          .collection('appointments')
          .where('assigned_doctor', isEqualTo: doctorId)
          .orderBy('appointment_time', descending: true)
          .get();
      return snap.docs.map((d) => ({...d.data(), 'id': d.id})).toList();
    } catch (e) {
      print('Error getting doctor appointments: $e');
      return [];
    }
  }

  // Subscribe to doctor changes
  // Realtime doctor changes can be implemented via Firestore snapshots when needed
}

