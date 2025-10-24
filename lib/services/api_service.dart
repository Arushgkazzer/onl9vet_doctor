import 'doctor_registration_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ApiService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DoctorRegistrationService _doctorService = DoctorRegistrationService();

  // Get all appointments (for doctor)
  Future<List<dynamic>> getAppointments() async {
    final doctorId = _auth.currentUser?.uid;
    if (doctorId == null) return [];
    
    final snapshot = await _firestore.collection('appointments').get();
    return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
  }

  // Get my appointments (assigned to current doctor)
  Future<List<dynamic>> getMyAppointments() async {
    final doctorId = _auth.currentUser?.uid;
    if (doctorId == null) return [];
    
    final snapshot = await _firestore
        .collection('appointments')
        .where('doctorId', isEqualTo: doctorId)
        .get();
    return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
  }

  // Get pending appointments
  Future<List<dynamic>> getPendingAppointments() async {
    final snapshot = await _firestore
        .collection('appointments')
        .where('status', isEqualTo: 'pending')
        .get();
    return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
  }
  
  // Update appointment status
  Future<void> updateAppointmentStatus(String appointmentId, String status) async {
    await _firestore.collection('appointments').doc(appointmentId).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Accept appointment (assign doctor to appointment)
  Future<bool> acceptAppointment(String appointmentId) async {
    final doctorId = _auth.currentUser?.uid;
    if (doctorId == null) return false;
    
    await _firestore.collection('appointments').doc(appointmentId).update({
      'status': 'confirmed',
      'doctorId': doctorId,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return true;
  }

  // Update appointment details (diagnosis, prescription, etc.)
  Future<bool> updateAppointmentDetails(String appointmentId, Map<String, dynamic> updates) async {
    try {
      await _firestore.collection('appointments').doc(appointmentId).update({
        ...updates,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Error updating appointment details: $e');
      return false;
    }
  }
  
  // Get all patients (pets)
  Future<List<Map<String, dynamic>>> getPatients() async {
    try {
      final snapshot = await _firestore.collection('patients').get();
      return snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      print('Error getting patients: $e');
      return [];
    }
  }

  // Get patients for a specific appointment
  Future<List<Map<String, dynamic>>> getPatientsForAppointment(String appointmentId) async {
    try {
      final appointmentDoc = await _firestore.collection('appointments').doc(appointmentId).get();
      final patientId = appointmentDoc.data()?['patientId'];
      
      if (patientId == null) return [];
      
      final patientDoc = await _firestore.collection('patients').doc(patientId).get();
      if (!patientDoc.exists) return [];
      
      return [{'id': patientDoc.id, ...patientDoc.data()!}];
    } catch (e) {
      print('Error getting patient for appointment: $e');
      return [];
    }
  }
  
  // Get a specific patient by ID
  Future<Map<String, dynamic>?> getPatient(String patientId) async {
    try {
      final doc = await _firestore.collection('patients').doc(patientId).get();
      if (!doc.exists) return null;
      return {'id': doc.id, ...doc.data()!};
    } catch (e) {
      print('Error getting patient: $e');
      return null;
    }
  }
    
  }

  // Get specific appointment
  Future<Map<String, dynamic>?> getAppointment(String appointmentId) async {
    // If needed, add GET /appointments/{id} in LaravelApi
    return null;
  }

  // Get current user profile
  Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    return await _laravel.me();
  }

  // Update user profile
  Future<bool> updateUserProfile(Map<String, dynamic> updates) async {
    // Add PUT /auth/profile to LaravelApi if needed
    return false;
  }

  // Update doctor availability status
  Future<bool> updateDoctorAvailability(String status) async {
    // Add PUT /doctor/availability to LaravelApi if needed
    return false;
  }

  // Check if user is doctor
  Future<bool> isDoctor() async {
    final me = await _laravel.me();
    return (me['role'] == 'doctor') || (me['doctor'] != null);
  }

  // Get appointment statistics
  Future<Map<String, dynamic>> getAppointmentStats() async {
    // Use /doctor/dashboard if it returns stats
    return await _laravel.dashboard();
  }

  // Realtime subscriptions are not implemented via Laravel backend

  // ==================== DOCTOR REGISTRATION & MANAGEMENT ====================

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
    return await _doctorService.registerDoctor(
      email: email,
      password: password,
      name: name,
      phone: phone,
      licenseNumber: licenseNumber,
      specialization: specialization,
      experienceYears: experienceYears,
    );
  }

  // Get all doctors
  Future<List<Map<String, dynamic>>> getAllDoctors() async {
    return await _doctorService.getAllDoctors();
  }

  // Get available doctors
  Future<List<Map<String, dynamic>>> getAvailableDoctors() async {
    return await _doctorService.getAvailableDoctors();
  }

  // Get doctor by ID
  Future<Map<String, dynamic>?> getDoctorById(String doctorId) async {
    return await _doctorService.getDoctorById(doctorId);
  }

  // Update doctor profile
  Future<bool> updateDoctorProfile(String doctorId, Map<String, dynamic> updates) async {
    return await _doctorService.updateDoctorProfile(doctorId, updates);
  }

  // Update doctor availability
  Future<bool> updateDoctorAvailability(String doctorId, String status) async {
    return await _doctorService.updateDoctorAvailability(doctorId, status);
  }

  // Get doctor statistics
  Future<Map<String, dynamic>> getDoctorStats(String doctorId) async {
    return await _doctorService.getDoctorStats(doctorId);
  }

  // Verify doctor credentials
  Future<bool> verifyDoctorCredentials(String email, String password) async {
    return await _doctorService.verifyDoctorCredentials(email, password);
  }

  // Get doctor's appointments
  Future<List<Map<String, dynamic>>> getDoctorAppointments(String doctorId) async {
    return await _doctorService.getDoctorAppointments(doctorId);
  }

  // Subscribe to doctor changes
  RealtimeChannel subscribeToDoctorChanges(Function(List<Map<String, dynamic>>) onData) {
    return _doctorService.subscribeToDoctorChanges(onData);
  }
}