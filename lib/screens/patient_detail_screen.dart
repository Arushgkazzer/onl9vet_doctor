import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'add_appointment_screen.dart';

class PatientDetailScreen extends StatefulWidget {
  final String patientId;
  const PatientDetailScreen({super.key, required this.patientId});

  @override
  State<PatientDetailScreen> createState() => _PatientDetailScreenState();
}

class _PatientDetailScreenState extends State<PatientDetailScreen> {
  Map<String, dynamic>? patient;
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _medicalHistory = [];
  bool _isMedicalHistoryLoading = false;
  String? _medicalHistoryError;

  @override
  void initState() {
    super.initState();
    _fetchPatient();
  }

  Future<void> _fetchPatient() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final doc = await FirebaseFirestore.instance.collection('patients').doc(widget.patientId).get();
      setState(() {
        patient = doc.data();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load patient: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchMedicalHistory() async {
    setState(() {
      _isMedicalHistoryLoading = true;
      _medicalHistoryError = null;
    });
    try {
      final snap = await FirebaseFirestore.instance
          .collection('medical_records')
          .where('patient_id', isEqualTo: patient!['id'])
          .get();
      setState(() {
        _medicalHistory = snap.docs.map((d) => ({...d.data(), 'id': d.id})).toList();
        _isMedicalHistoryLoading = false;
      });
    } catch (e) {
      setState(() {
        _medicalHistoryError = 'Failed to load medical records: $e';
        _isMedicalHistoryLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Patient Details')),
        body: Center(child: Text(_error!, style: const TextStyle(color: Colors.red))),
      );
    }
    if (patient == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Patient Details')),
        body: const Center(child: Text('Patient not found.')),
      );
    }
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Patient Details',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.teal,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.teal),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderCard(),
            const SizedBox(height: 16),
            _buildPatientInfoCard(),
            const SizedBox(height: 16),
            _buildOwnerInfoCard(),
            const SizedBox(height: 16),
            _buildMedicalHistoryCard(),
            const SizedBox(height: 16),
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    final statusColor = _getStatusColor(patient!['status']);
    final petIcon = _getPetIcon(patient!['petType']);
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.orange.withOpacity(0.1),
            child: Icon(
              petIcon,
              size: 50,
              color: Colors.orange,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            patient!['name'],
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.teal,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${patient!['petType']} • ${patient!['breed']}',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: statusColor),
            ),
            child: Text(
              patient!['status'],
              style: TextStyle(
                color: statusColor,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.pets, color: Colors.orange),
              const SizedBox(width: 8),
              Text(
                'Patient Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow('Name', patient!['name']),
          _buildInfoRow('Type', patient!['petType']),
          _buildInfoRow('Breed', patient!['breed']),
          _buildInfoRow('Age', patient!['age']),
          _buildInfoRow('Last Visit', patient!['lastVisit']),
          if (patient!['nextAppointment'] != null)
            _buildInfoRow('Next Appointment', patient!['nextAppointment']),
        ],
      ),
    );
  }

  Widget _buildOwnerInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person, color: Colors.orange),
              const SizedBox(width: 8),
              Text(
                'Owner Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow('Name', patient!['ownerName']),
          _buildInfoRow('Phone', '+1 (555) 123-4567'),
          _buildInfoRow('Email', '${patient!['ownerName'].toLowerCase().replaceAll(' ', '.')}@email.com'),
          _buildInfoRow('Address', '123 Main St, City, State 12345'),
        ],
      ),
    );
  }

  Widget _buildMedicalHistoryCard() {
    final medicalHistory = [
      {
        'date': '2024-01-10',
        'type': 'Check-up',
        'diagnosis': 'Healthy',
        'treatment': 'Routine vaccination',
      },
      {
        'date': '2023-12-15',
        'type': 'Emergency',
        'diagnosis': 'Minor injury',
        'treatment': 'Wound cleaning and antibiotics',
      },
      {
        'date': '2023-11-20',
        'type': 'Check-up',
        'diagnosis': 'Healthy',
        'treatment': 'Annual physical examination',
      },
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.medical_services, color: Colors.orange),
              const SizedBox(width: 8),
              Text(
                'Medical History',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...medicalHistory.map((record) => _buildMedicalRecord(record)).toList(),
        ],
      ),
    );
  }

  Widget _buildMedicalRecord(Map<String, dynamic> record) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                record['date'],
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.teal,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  record['type'],
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.orange,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Diagnosis: ${record['diagnosis']}',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Text(
            'Treatment: ${record['treatment']}',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () async {
              final result = await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => AddAppointmentScreen(
                    initialPatientName: patient!['name'],
                    initialPetType: patient!['petType'],
                    initialBreed: patient!['breed'],
                    initialAge: patient!['age']?.toString(),
                  ),
                ),
              );
              if (result == true) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Appointment scheduled!'), backgroundColor: Colors.green),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Schedule Appointment',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () async {
                  await _fetchMedicalHistory();
                  showDialog(
                    context: context,
                    builder: (context) => Dialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.medical_services, color: Colors.orange),
                                const SizedBox(width: 8),
                                Text(
                                  'Medical Records',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.teal,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            if (_isMedicalHistoryLoading)
                              const Center(child: CircularProgressIndicator()),
                            if (_medicalHistoryError != null)
                              Text(_medicalHistoryError!, style: const TextStyle(color: Colors.red)),
                            if (!_isMedicalHistoryLoading && _medicalHistoryError == null && _medicalHistory.isEmpty)
                              const Text('No medical records found.'),
                            if (!_isMedicalHistoryLoading && _medicalHistoryError == null && _medicalHistory.isNotEmpty)
                              ..._medicalHistory.map((record) => _buildMedicalRecord(record)).toList(),
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text('Close'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: Colors.teal),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Medical Records',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton(
                onPressed: () async {
                  final phone = patient!['ownerPhone'] ?? '+1 (555) 123-4567';
                  final telUri = Uri(scheme: 'tel', path: phone.replaceAll(RegExp(r'[^0-9+]'), ''));
                  if (await canLaunchUrl(telUri)) {
                    await launchUrl(telUri);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Could not open dialer.'), backgroundColor: Colors.red),
                    );
                  }
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: Colors.green),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Contact Owner',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getPetIcon(String petType) {
    switch (petType.toLowerCase()) {
      case 'dog':
        return Icons.pets;
      case 'cat':
        return Icons.pets;
      case 'bird':
        return Icons.flutter_dash;
      case 'fish':
        return Icons.water;
      default:
        return Icons.pets;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'inactive':
        return Colors.grey;
      case 'emergency':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
} 