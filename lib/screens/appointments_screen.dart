import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'appointment_detail_screen.dart';
import '../services/firebase_appointment_service.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  List<Map<String, dynamic>> _appointments = [];
  bool _isLoading = true;
  String? _error;
  String _selectedFilter = 'All';
  final TextEditingController _searchController = TextEditingController();
  final FirebaseAppointmentService _firebaseService = FirebaseAppointmentService();
  Stream<List<Map<String, dynamic>>>? _appointmentsStream;

  static GlobalKey<_AppointmentsScreenState> globalKey = GlobalKey<_AppointmentsScreenState>();

  @override
  void initState() {
    super.initState();
    _setupRealTimeListener();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _setupRealTimeListener() {
    // Set up real-time listener for appointments
    _appointmentsStream = _firebaseService.subscribeToAppointments();
    
    // Listen to the stream
    _appointmentsStream!.listen((appointments) {
      if (mounted) {
        setState(() {
          _appointments = appointments;
          _isLoading = false;
          _error = null;
        });
      }
    }, onError: (error) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load appointments: $error';
          _isLoading = false;
        });
      }
    });
  }

  void _onSearchChanged() {
    setState(() {}); // Triggers rebuild for search
  }

  Future<void> _fetchAppointments() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final appointments = await _firebaseService.getAllAppointments();
      // Map Firebase fields to UI fields
      _appointments = appointments.map((appt) => {
        'id': appt['id'] ?? '',
        'patientName': appt['pet_name'] ?? '',
        'ownerName': appt['user_name'] ?? '',
        'date': _formatTimestamp(appt['appointment_time']),
        'time': _formatTimeOfDay(appt['appointment_time']),
        'type': appt['purpose'] ?? '',
        'status': appt['status'] ?? '',
        'petType': appt['species'] ?? '',
        'breed': appt['breed'] ?? '',
        'age': appt['age'] ?? '',
        'phone': appt['user_phone'] ?? '',
        'email': appt['user_email'] ?? '',
        'purpose': appt['purpose'] ?? '',
        'history': appt['history'] ?? '',
        'symptom': appt['symptom'] ?? '',
        'priority': appt['priority'] ?? 'normal',
        'payment_status': appt['payment_status'] ?? '',
        'assigned_doctor': appt['assigned_doctor'] ?? '',
        'assigned_doctor_name': appt['assigned_doctor_name'] ?? '',
        'doctor_response': appt['doctor_response'] ?? '',
        'accepted_at': appt['accepted_at'] ?? null,
        'rejected_at': appt['rejected_at'] ?? null,
        'appointment_time': appt['appointment_time'] ?? null, // Store the original timestamp
      }).toList();
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load appointments: $e';
        _isLoading = false;
      });
    }
  }

  // Helper method to format Timestamp to date string
  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return '';
    
    try {
      DateTime dateTime;
      if (timestamp is Timestamp) {
        dateTime = timestamp.toDate();
      } else if (timestamp is String) {
        dateTime = DateTime.parse(timestamp);
      } else {
        return '';
      }
      
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } catch (e) {
      return '';
    }
  }
  
  // Helper method to format Timestamp to time string
  String _formatTimeOfDay(dynamic timestamp) {
    if (timestamp == null) return '';
    
    try {
      DateTime dateTime;
      if (timestamp is Timestamp) {
        dateTime = timestamp.toDate();
      } else if (timestamp is String) {
        dateTime = DateTime.parse(timestamp);
      } else {
        return '';
      }
      
      return TimeOfDay.fromDateTime(dateTime).format(context);
    } catch (e) {
      return '';
    }
  }

  List<Map<String, dynamic>> get _filteredAppointments {
    String query = _searchController.text.toLowerCase();
    return _appointments.where((appt) {
      // Ensure status is not null before calling toLowerCase()
      final String status = appt['status'] as String? ?? '';
      final matchesStatus = _selectedFilter == 'All' || (status.toLowerCase() == _selectedFilter.toLowerCase());
      
      // Ensure all strings are not null before calling toLowerCase() and contains()
      final String patientName = appt['patientName'] as String? ?? '';
      final String ownerName = appt['ownerName'] as String? ?? '';
      final String type = appt['type'] as String? ?? '';
      final String petType = appt['petType'] as String? ?? '';
      final String breed = appt['breed'] as String? ?? '';
      
      final matchesSearch = query.isEmpty ||
        patientName.toLowerCase().contains(query) ||
        ownerName.toLowerCase().contains(query) ||
        type.toLowerCase().contains(query) ||
        petType.toLowerCase().contains(query) ||
        breed.toLowerCase().contains(query);
        
      return matchesStatus && matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Appointments',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.teal,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.teal),
            onPressed: () {
              // Force refresh appointments
              _fetchAppointments();
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_list, color: Colors.teal),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _appointmentsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && _isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasError || _error != null) {
            return Center(
              child: Text(
                'Error: ${snapshot.error ?? _error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }
          
          // Use the stream data if available, otherwise use the stored appointments
          final appointments = snapshot.hasData ? snapshot.data! : _appointments;
          
          // Apply filtering
          final filteredAppointments = appointments.where((appt) {
            final query = _searchController.text.toLowerCase();
            final status = appt['status'] as String? ?? '';
            final petName = appt['pet_name'] as String? ?? '';
            final patientName = appt['patientName'] as String? ?? '';
            final userName = appt['user_name'] as String? ?? '';
            final ownerName = appt['ownerName'] as String? ?? '';
            final purpose = appt['purpose'] as String? ?? '';
            final species = appt['species'] as String? ?? '';
            final petType = appt['petType'] as String? ?? '';
            final breed = appt['breed'] as String? ?? '';
            
            final matchesStatus = _selectedFilter == 'All' || 
                status.toLowerCase() == _selectedFilter.toLowerCase();
            final matchesSearch = query.isEmpty ||
              petName.toLowerCase().contains(query) ||
              patientName.toLowerCase().contains(query) ||
              userName.toLowerCase().contains(query) ||
              ownerName.toLowerCase().contains(query) ||
              purpose.toLowerCase().contains(query) ||
              species.toLowerCase().contains(query) ||
              petType.toLowerCase().contains(query) ||
              breed.toLowerCase().contains(query);
            return matchesStatus && matchesSearch;
          }).toList();
          
          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search appointments...',
                          prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: filteredAppointments.isEmpty
                    ? Center(child: Text('No appointments found.', style: TextStyle(color: Colors.grey[600], fontSize: 16)))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: filteredAppointments.length,
                        itemBuilder: (context, index) {
                          final appointment = filteredAppointments[index];
                          return _buildAppointmentCard(appointment);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAppointmentCard(Map<String, dynamic> appointment) {
    // Safe extraction of all fields with default values
    final String status = appointment['status'] as String? ?? '';
    final String priority = appointment['priority'] as String? ?? 'normal';
    final String petName = appointment['pet_name'] as String? ?? appointment['patientName'] as String? ?? 'Unknown Pet';
    final String species = appointment['species'] as String? ?? appointment['petType'] as String? ?? '';
    final String breed = appointment['breed'] as String? ?? '';
    final String purpose = appointment['purpose'] as String? ?? '';
    final String ownerName = appointment['user_name'] as String? ?? appointment['ownerName'] as String? ?? 'Unknown Owner';
    
    final statusColor = _getStatusColor(status);
    final priorityColor = _getPriorityColor(priority);
    final isPending = status == 'pending';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AppointmentDetailScreen(appointment: appointment),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                petName,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.teal,
                                ),
                              ),
                              if (priority != 'normal') ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: priorityColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: priorityColor),
                                  ),
                                  child: Text(
                                    priority.toUpperCase(),
                                    style: TextStyle(
                                      color: priorityColor,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          Text(
                            '${appointment['species'] as String? ?? appointment['petType'] as String? ?? ''} • ${appointment['breed'] as String? ?? ''}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                          if (appointment['purpose'] != null && appointment['purpose'].toString().isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text(
                                'Purpose: ${appointment['purpose'] as String? ?? ''}',
                                style: TextStyle(color: Colors.grey[700], fontSize: 13),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: statusColor),
                      ),
                      child: Text(
                        appointment['status'] as String? ?? '',
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.person, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      appointment['ownerName'] as String? ?? '',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.phone, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      appointment['phone'] as String? ?? '',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.email, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      appointment['email'] as String? ?? '',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      '${appointment['date'] as String? ?? ''} at ${appointment['time'] as String? ?? ''}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.medical_services, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      appointment['type'] as String? ?? '',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                // Accept/Reject buttons for pending appointments
                if (isPending) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _acceptAppointment(appointment['id']),
                          icon: const Icon(Icons.check, size: 18),
                          label: const Text('Accept'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _rejectAppointment(appointment['id']),
                          icon: const Icon(Icons.close, size: 18),
                          label: const Text('Reject'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
      case 'confirmed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'rejected':
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'urgent':
        return Colors.orange;
      case 'emergency':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  Future<void> _acceptAppointment(String appointmentId) async {
    try {
      final success = await _firebaseService.acceptAppointment(appointmentId);
      if (success) {
        // Reset filter to show all appointments and force refresh
        setState(() {
          _selectedFilter = 'All'; // Reset filter to show all appointments
          _isLoading = true; // Trigger loading state
        });
        
        // Force refresh appointments
        _setupRealTimeListener();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Appointment accepted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to accept appointment'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _rejectAppointment(String appointmentId) async {
    try {
      final success = await _firebaseService.rejectAppointment(appointmentId);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Appointment rejected'),
            backgroundColor: Colors.orange,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to reject appointment'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Appointments'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            'All',
            'Pending',
            'Accepted',
            'Rejected',
            'Confirmed',
            'Cancelled',
          ].map((filter) => RadioListTile<String>(
            title: Text(filter),
            value: filter,
            groupValue: _selectedFilter,
            onChanged: (value) {
              setState(() {
                _selectedFilter = value!;
              });
              Navigator.pop(context);
            },
          )).toList(),
        ),
      ),
    );
  }

  static void refreshAppointments() {
    globalKey.currentState?._fetchAppointments();
  }
}