import 'package:flutter/material.dart';
import '../services/firebase_appointment_service.dart';
import 'package:lottie/lottie.dart';
import 'video_call_screen.dart';
import 'chat_screen.dart';

class AppointmentDetailScreen extends StatefulWidget {
  final Map<String, dynamic> appointment;

  const AppointmentDetailScreen({super.key, required this.appointment});

  @override
  State<AppointmentDetailScreen> createState() => _AppointmentDetailScreenState();
}

class _AppointmentDetailScreenState extends State<AppointmentDetailScreen> with SingleTickerProviderStateMixin {
  late Map<String, dynamic> appointment;
  bool _isUpdating = false;
  AnimationController? _successController;
  bool _showSuccess = false;

  @override
  void initState() {
    super.initState();
    appointment = Map<String, dynamic>.from(widget.appointment);
    _successController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
  }

  @override
  void dispose() {
    _successController?.dispose();
    super.dispose();
  }

  Future<void> _updateStatus(String newStatus) async {
    setState(() { _isUpdating = true; });
    try {
      await FirebaseAppointmentService().updateAppointmentStatus(appointment['id'].toString(), newStatus);
      setState(() {
        appointment['status'] = newStatus;
        _isUpdating = false;
        _showSuccess = true;
      });
      _successController?.forward(from: 0);
      await Future.delayed(const Duration(milliseconds: 1200));
      setState(() { _showSuccess = false; });
      if (newStatus == 'cancelled' || newStatus == 'completed') {
        Future.delayed(const Duration(milliseconds: 300), () {
          Navigator.of(context).pop(true); // Pop and signal refresh
        });
      }
    } catch (e) {
      setState(() { _isUpdating = false; });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update status: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _showActionDialog(BuildContext context, String action, String status) async {
    Color color;
    String verb;
    IconData icon;
    switch (status) {
      case 'confirmed':
        color = Colors.green;
        verb = 'confirm';
        icon = Icons.check_circle_outline;
        break;
      case 'completed':
        color = Colors.teal;
        verb = 'mark as completed';
        icon = Icons.verified;
        break;
      case 'cancelled':
        color = Colors.red;
        verb = 'cancel';
        icon = Icons.cancel_outlined;
        break;
      default:
        color = Colors.blueGrey;
        verb = 'update';
        icon = Icons.info_outline;
    }
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 8),
            Text('${action[0].toUpperCase()}${action.substring(1)} Appointment'),
          ],
        ),
        content: Text('Are you sure you want to $verb this appointment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(context);
              _updateStatus(status);
            },
            child: Text('Yes, $verb'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Appointment Details',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.teal,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.teal),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderCard(),
                const SizedBox(height: 16),
                _buildPatientInfoCard(),
                const SizedBox(height: 16),
                _buildAppointmentInfoCard(),
                const SizedBox(height: 24),
                _buildActionButtons(context),
              ],
            ),
          ),
          if (_isUpdating)
            Container(
              color: Colors.black.withOpacity(0.2),
              child: const Center(child: CircularProgressIndicator()),
            ),
          if (_showSuccess)
            Center(
              child: ScaleTransition(
                scale: CurvedAnimation(parent: _successController!, curve: Curves.elasticOut),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(60),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.2),
                        blurRadius: 24,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Lottie.asset(
                    'assets/lottie/success_check.json',
                    width: 100,
                    height: 100,
                    repeat: false,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeaderCard() {
    final statusColor = _getStatusColor(appointment['status']);
    final statusIcon = _getStatusIcon(appointment['status']);
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
            radius: 40,
            backgroundColor: statusColor.withOpacity(0.08),
            child: Icon(
              statusIcon,
              size: 40,
              color: statusColor,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            appointment['patientName']?.toString() ?? appointment['pet_name']?.toString() ?? 'Unknown Patient',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.teal,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            appointment['type']?.toString() ?? appointment['purpose']?.toString() ?? 'Consultation',
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
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(statusIcon, color: statusColor, size: 18),
                const SizedBox(width: 6),
                Text(
                  (appointment['status'] ?? 'Unknown').toString().toUpperCase(),
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
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
              const Icon(Icons.pets, color: Colors.orange),
              const SizedBox(width: 8),
              const Text(
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
          _buildInfoRow('Pet Name', appointment['patientName'] ?? appointment['pet_name']),
          _buildInfoRow('Pet Type', appointment['petType'] ?? appointment['species']),
          _buildInfoRow('Breed', appointment['breed']),
          _buildInfoRow('Age', appointment['age']),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.person, color: Colors.orange),
              const SizedBox(width: 8),
              const Text(
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
          _buildInfoRow('Owner Name', appointment['ownerName'] ?? appointment['user_name']),
        ],
      ),
    );
  }

  Widget _buildAppointmentInfoCard() {
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
              const Icon(Icons.calendar_today, color: Colors.orange),
              const SizedBox(width: 8),
              const Text(
                'Appointment Details',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow('Date', appointment['date'] ?? appointment['appointment_date']),
          _buildInfoRow('Time', appointment['time'] ?? appointment['appointment_time']),
          _buildInfoRow('Type', appointment['type'] ?? appointment['purpose']),
          _buildInfoRow('Status', appointment['status']),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, dynamic value) {
    final String displayValue = value?.toString() ?? 'Not specified';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
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
              displayValue,
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

  Widget _buildActionButtons(BuildContext context) {
    final status = (appointment['status'] ?? '').toLowerCase();
    final now = DateTime.now();
    final apptTime = appointment['appointmentTime'] is DateTime
        ? appointment['appointmentTime']
        : (appointment['appointmentTime'] != null ? DateTime.tryParse(appointment['appointmentTime'].toString()) : null);
    final canStartVideo = status == 'confirmed' && apptTime != null &&
        now.isAfter(apptTime.subtract(const Duration(minutes: 5))) &&
        now.isBefore(apptTime.add(const Duration(minutes: 30)));
    
    // Always show chat button for all appointments regardless of status
    Widget chatButton = SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        icon: const Icon(Icons.chat_bubble_outline, color: Colors.teal),
        label: const Text('Open Chat', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
        onPressed: _isUpdating ? null : () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatScreen(
                appointmentId: (appointment['id'] ?? '').toString(),
                patientName: (appointment['patientName'] ?? appointment['user_name'] ?? 'Patient').toString(),
              ),
            ),
          );
        },
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.teal),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
    
    // For completed or cancelled appointments, just show the chat button
    if (status == 'completed' || status == 'cancelled') {
      return Column(
        children: [
          chatButton,
        ],
      );
    }
    
    // For appointments that can start video
    if (canStartVideo) {
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.video_call, color: Colors.white),
              label: const Text('Start Video Call', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              onPressed: _isUpdating ? null : () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => VideoCallScreen(
                      appointmentId: (appointment['id'] ?? '').toString(),
                      vetName: (appointment['vetName'] ?? appointment['ownerName'] ?? 'Doctor').toString(),
                      appointmentTime: apptTime ?? DateTime.now(),
                      isVet: true,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 2,
              ),
            ),
          ),
          const SizedBox(height: 12),
          chatButton,
          const SizedBox(height: 20),
          _buildStatusActionRow(context, status),
        ],
      );
    }
    
    // For other appointments, show chat button and status actions
    return Column(
      children: [
        chatButton,
        const SizedBox(height: 20),
        _buildStatusActionRow(context, status),
      ],
    );
  }

  Widget _buildStatusActionRow(BuildContext context, String status) {
    if (status == 'pending') {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.check_circle_outline, color: Colors.white),
              label: const Text('Confirm', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              onPressed: _isUpdating ? null : () => _showActionDialog(context, 'confirm', 'confirmed'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 2,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: OutlinedButton.icon(
              icon: const Icon(Icons.cancel_outlined, color: Colors.red),
              label: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
              onPressed: _isUpdating ? null : () => _showActionDialog(context, 'cancel', 'cancelled'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: const BorderSide(color: Colors.red),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      );
    }
    if (status == 'confirmed') {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.verified, color: Colors.white),
              label: const Text('Complete', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              onPressed: _isUpdating ? null : () => _showActionDialog(context, 'complete', 'completed'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 2,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: OutlinedButton.icon(
              icon: const Icon(Icons.cancel_outlined, color: Colors.red),
              label: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
              onPressed: _isUpdating ? null : () => _showActionDialog(context, 'cancel', 'cancelled'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: const BorderSide(color: Colors.red),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      );
    }
    // Show a default action if status is null or unknown
    if (status != 'pending' && status != 'confirmed' && status != 'completed' && status != 'cancelled') {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.check_circle_outline, color: Colors.white),
              label: const Text('Confirm', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              onPressed: _isUpdating ? null : () => _showActionDialog(context, 'confirm', 'confirmed'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 2,
              ),
            ),
          ),
        ],
      );
    }
    return const SizedBox.shrink();
  }

  Color _getStatusColor(String? status) {
    if (status == null) return Colors.grey;
    
    switch (status.toLowerCase()) {
      case 'confirmed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      case 'completed':
        return Colors.blueGrey;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String? status) {
    if (status == null) return Icons.info_outline;
    
    switch (status.toLowerCase()) {
      case 'confirmed':
        return Icons.check_circle_outline;
      case 'pending':
        return Icons.hourglass_top;
      case 'cancelled':
        return Icons.cancel_outlined;
      case 'completed':
        return Icons.verified;
      default:
        return Icons.info_outline;
    }
  }
}