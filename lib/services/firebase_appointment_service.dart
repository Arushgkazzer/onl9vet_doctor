import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseAppointmentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Helper to get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Helper to check if user is authenticated
  bool get isAuthenticated => _auth.currentUser != null;

  // Helper to get current user
  User? get currentUser => _auth.currentUser;

  // ==================== USERS OPERATIONS ====================

  // Get current user profile
  Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    if (!isAuthenticated) return null;
    
    try {
      final doc = await _firestore
          .collection('users')
          .doc(currentUserId)
          .get();
      
      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
    }
  }

  // Update user profile
  Future<bool> updateUserProfile(Map<String, dynamic> updates) async {
    if (!isAuthenticated) return false;
    
    try {
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .update(updates);
      return true;
    } catch (e) {
      print('Error updating user profile: $e');
      return false;
    }
  }

  // Update doctor availability status
  Future<bool> updateDoctorAvailability(String status) async {
    if (!isAuthenticated) return false;
    
    try {
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .update({
            'availability_status': status,
            'role': 'doctor',
          });
      return true;
    } catch (e) {
      print('Error updating doctor availability: $e');
      return false;
    }
  }

  // ==================== APPOINTMENTS OPERATIONS (DOCTOR VIEW) ====================

  // Get all appointments (for doctors)
  Future<List<Map<String, dynamic>>> getAllAppointments() async {
    if (!isAuthenticated) return [];
    
    try {
      final querySnapshot = await _firestore
          .collection('appointments')
          .orderBy('appointment_time', descending: true)
          .get();
      
      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('Error getting all appointments: $e');
      return [];
    }
  }

  // Get appointments assigned to current doctor
  Future<List<Map<String, dynamic>>> getMyAppointments() async {
    if (!isAuthenticated) return [];
    
    try {
      final querySnapshot = await _firestore
          .collection('appointments')
          .where('assigned_doctor', isEqualTo: currentUserId)
          .orderBy('appointment_time', descending: true)
          .get();
      
      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('Error getting my appointments: $e');
      return [];
    }
  }

  // Get pending appointments (for doctors) - REAL-TIME LISTENER
  Stream<List<Map<String, dynamic>>> getPendingAppointmentsStream() {
    return _firestore
        .collection('appointments')
        .where('status', isEqualTo: 'pending')
        .orderBy('appointment_time', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  // Get pending appointments (one-time fetch)
  Future<List<Map<String, dynamic>>> getPendingAppointments() async {
    if (!isAuthenticated) return [];
    
    try {
      final querySnapshot = await _firestore
          .collection('appointments')
          .where('status', isEqualTo: 'pending')
          .orderBy('appointment_time', descending: false)
          .get();
      
      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('Error getting pending appointments: $e');
      return [];
    }
  }

  // Accept appointment (assign doctor to appointment)
  Future<bool> acceptAppointment(String appointmentId, {String? doctorResponse}) async {
    if (!isAuthenticated) return false;
    
    try {
      final userProfile = await getCurrentUserProfile();
      final doctorName = userProfile?['name'] ?? 'Dr. Unknown';
      
      await _firestore
          .collection('appointments')
          .doc(appointmentId)
          .update({
            'status': 'accepted',
            'assigned_doctor': currentUserId,
            'assigned_doctor_name': doctorName,
            'accepted_at': FieldValue.serverTimestamp(),
            'doctor_response': doctorResponse ?? 'Appointment accepted. I will contact you soon.',
          });
      return true;
    } catch (e) {
      print('Error accepting appointment: $e');
      return false;
    }
  }

  // Reject appointment
  Future<bool> rejectAppointment(String appointmentId, {String? doctorResponse}) async {
    if (!isAuthenticated) return false;
    
    try {
      final userProfile = await getCurrentUserProfile();
      final doctorName = userProfile?['name'] ?? 'Dr. Unknown';
      
      await _firestore
          .collection('appointments')
          .doc(appointmentId)
          .update({
            'status': 'rejected',
            'assigned_doctor': currentUserId,
            'assigned_doctor_name': doctorName,
            'rejected_at': FieldValue.serverTimestamp(),
            'doctor_response': doctorResponse ?? 'Appointment rejected due to scheduling conflicts.',
          });
      return true;
    } catch (e) {
      print('Error rejecting appointment: $e');
      return false;
    }
  }

  // Update appointment status
  Future<bool> updateAppointmentStatus(String appointmentId, String status) async {
    if (!isAuthenticated) return false;
    
    try {
      await _firestore
          .collection('appointments')
          .doc(appointmentId)
          .update({'status': status});
      return true;
    } catch (e) {
      print('Error updating appointment status: $e');
      return false;
    }
  }

  // Update appointment with diagnosis and prescription
  Future<bool> updateAppointmentDetails(String appointmentId, Map<String, dynamic> updates) async {
    if (!isAuthenticated) return false;
    
    try {
      await _firestore
          .collection('appointments')
          .doc(appointmentId)
          .update({
            ...updates,
            'updated_at': FieldValue.serverTimestamp(),
          });
      return true;
    } catch (e) {
      print('Error updating appointment details: $e');
      return false;
    }
  }

  // Mark chat as completed and keep in history
  Future<bool> completeChatSession(String appointmentId, Map<String, dynamic> prescriptionData) async {
    if (!isAuthenticated) return false;
    
    try {
      // Update appointment status and add prescription
      await _firestore
          .collection('appointments')
          .doc(appointmentId)
          .update({
            'status': 'completed',
            'prescription': prescriptionData,
            'chat_ended_at': FieldValue.serverTimestamp(),
            'completed_by': currentUserId,
            'updated_at': FieldValue.serverTimestamp(),
          });
      
      // Mark chat as completed but keep messages for history
      await _firestore
          .collection('chats')
          .doc(appointmentId)
          .set({
            'status': 'completed',
            'completed_at': FieldValue.serverTimestamp(),
            'completed_by': currentUserId,
          }, SetOptions(merge: true));
      
      return true;
    } catch (e) {
      print('Error completing chat session: $e');
      return false;
    }
  }

  // Get a specific appointment
  Future<Map<String, dynamic>?> getAppointment(String appointmentId) async {
    if (!isAuthenticated) return null;
    
    try {
      final doc = await _firestore
          .collection('appointments')
          .doc(appointmentId)
          .get();
      
      if (doc.exists) {
        final data = doc.data()!;
        data['id'] = doc.id;
        return data;
      }
      return null;
    } catch (e) {
      print('Error getting appointment: $e');
      return null;
    }
  }

  // ==================== PATIENTS OPERATIONS ====================

  // Get all patients (pets) - for doctors to view
  Future<List<Map<String, dynamic>>> getAllPatients() async {
    if (!isAuthenticated) return [];
    
    try {
      final querySnapshot = await _firestore
          .collection('pets')
          .orderBy('created_at', descending: true)
          .get();
      
      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('Error getting all patients: $e');
      return [];
    }
  }

  // Get patients for a specific appointment
  Future<List<Map<String, dynamic>>> getPatientsForAppointment(String appointmentId) async {
    if (!isAuthenticated) return [];
    
    try {
      final appointment = await getAppointment(appointmentId);
      if (appointment == null) return [];
      
      final querySnapshot = await _firestore
          .collection('pets')
          .where('owner_id', isEqualTo: appointment['user_id'])
          .get();
      
      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('Error getting patients for appointment: $e');
      return [];
    }
  }

  // ==================== DOCTOR OPERATIONS ====================

  // Check if current user is a doctor
  Future<bool> isDoctor() async {
    if (!isAuthenticated) return false;
    
    try {
      final doc = await _firestore
          .collection('users')
          .doc(currentUserId)
          .get();
      
      if (doc.exists) {
        return doc.data()?['role'] == 'doctor';
      }
      return false;
    } catch (e) {
      print('Error checking doctor role: $e');
      return false;
    }
  }

  // Get all doctors
  Future<List<Map<String, dynamic>>> getDoctors() async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'doctor')
          .orderBy('name')
          .get();
      
      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('Error getting doctors: $e');
      return [];
    }
  }

  // Get available doctors
  Future<List<Map<String, dynamic>>> getAvailableDoctors() async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'doctor')
          .where('availability_status', isEqualTo: 'available')
          .orderBy('name')
          .get();
      
      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('Error getting available doctors: $e');
      return [];
    }
  }

  // ==================== STATISTICS OPERATIONS ====================

  // Get appointment statistics for doctor
  Future<Map<String, dynamic>> getAppointmentStats() async {
    if (!isAuthenticated) return {};
    
    try {
      final totalQuery = await _firestore
          .collection('appointments')
          .where('assigned_doctor', isEqualTo: currentUserId)
          .get();
      
      final pendingQuery = await _firestore
          .collection('appointments')
          .where('assigned_doctor', isEqualTo: currentUserId)
          .where('status', isEqualTo: 'pending')
          .get();
      
      final completedQuery = await _firestore
          .collection('appointments')
          .where('assigned_doctor', isEqualTo: currentUserId)
          .where('status', isEqualTo: 'completed')
          .get();
      
      return {
        'total': totalQuery.docs.length,
        'pending': pendingQuery.docs.length,
        'completed': completedQuery.docs.length,
      };
    } catch (e) {
      print('Error getting appointment stats: $e');
      return {};
    }
  }

  // ==================== REAL-TIME SUBSCRIPTIONS ====================

  // Subscribe to appointments changes
  Stream<List<Map<String, dynamic>>> subscribeToAppointments() {
    return _firestore
        .collection('appointments')
        .orderBy('appointment_time', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  // Subscribe to my appointments changes
  Stream<List<Map<String, dynamic>>> subscribeToMyAppointments() {
    return _firestore
        .collection('appointments')
        .where('assigned_doctor', isEqualTo: currentUserId)
        .orderBy('appointment_time', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  // Subscribe to pending appointments changes - REAL-TIME LISTENER
  Stream<List<Map<String, dynamic>>> subscribeToPendingAppointments() {
    return _firestore
        .collection('appointments')
        .where('status', isEqualTo: 'pending')
        .orderBy('appointment_time', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  // Subscribe to doctor notifications
  Stream<List<Map<String, dynamic>>> subscribeToDoctorNotifications() {
    return _firestore
        .collection('doctor_notifications')
        .where('read', isEqualTo: false)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  // Mark notification as read
  Future<bool> markNotificationAsRead(String notificationId) async {
    try {
      await _firestore
          .collection('doctor_notifications')
          .doc(notificationId)
          .update({'read': true});
      return true;
    } catch (e) {
      print('Error marking notification as read: $e');
      return false;
    }
  }

  // ==================== AUTHENTICATION ====================

  // Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // This would need Google Sign-In implementation
      // For now, return null as placeholder
      return null;
    } catch (e) {
      print('Error signing in with Google: $e');
      return null;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print('Error signing out: $e');
    }
  }
}
