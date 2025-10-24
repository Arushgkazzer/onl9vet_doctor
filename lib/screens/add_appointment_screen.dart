import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddAppointmentScreen extends StatefulWidget {
  final String? initialPatientName;
  final String? initialPetType;
  final String? initialBreed;
  final String? initialAge;
  const AddAppointmentScreen({Key? key, this.initialPatientName, this.initialPetType, this.initialBreed, this.initialAge}) : super(key: key);

  @override
  State<AddAppointmentScreen> createState() => _AddAppointmentScreenState();
}

class _AddAppointmentScreenState extends State<AddAppointmentScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _patientNameController;
  late TextEditingController _petTypeController;
  late TextEditingController _breedController;
  late TextEditingController _ageController;
  final _purposeController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _patientNameController = TextEditingController(text: widget.initialPatientName ?? '');
    _petTypeController = TextEditingController(text: widget.initialPetType ?? '');
    _breedController = TextEditingController(text: widget.initialBreed ?? '');
    _ageController = TextEditingController(text: widget.initialAge ?? '');
  }

  @override
  void dispose() {
    _patientNameController.dispose();
    _petTypeController.dispose();
    _breedController.dispose();
    _ageController.dispose();
    _purposeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(now.year + 2),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields and select date/time'), backgroundColor: Colors.red),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      final appointmentDateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );
      final uid = FirebaseAuth.instance.currentUser?.uid;
      final docRef = FirebaseFirestore.instance.collection('appointments').doc();
      await docRef.set({
        'id': docRef.id,
        'user_id': uid,
        'user_name': _patientNameController.text.trim(),
        'species': _petTypeController.text.trim(),
        'breed': _breedController.text.trim(),
        'age': _ageController.text.trim(),
        'purpose': _purposeController.text.trim(),
        'history': _notesController.text.trim(),
        'appointment_time': Timestamp.fromDate(appointmentDateTime),
        'status': 'pending',
        'created_at': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        Navigator.of(context).pop(true); // Return true to indicate success
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Appointment added!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add appointment: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Appointment'),
        backgroundColor: Colors.teal,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _patientNameController,
                decoration: const InputDecoration(labelText: 'Patient Name', prefixIcon: Icon(Icons.person)),
                validator: (v) => v == null || v.isEmpty ? 'Enter patient name' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _petTypeController,
                decoration: const InputDecoration(labelText: 'Pet Type', prefixIcon: Icon(Icons.pets)),
                validator: (v) => v == null || v.isEmpty ? 'Enter pet type' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _breedController,
                decoration: const InputDecoration(labelText: 'Breed', prefixIcon: Icon(Icons.category)),
                validator: (v) => v == null || v.isEmpty ? 'Enter breed' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _ageController,
                decoration: const InputDecoration(labelText: 'Age', prefixIcon: Icon(Icons.cake)),
                keyboardType: TextInputType.number,
                validator: (v) => v == null || v.isEmpty ? 'Enter age' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: _pickDate,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Date',
                          prefixIcon: Icon(Icons.calendar_today),
                        ),
                        child: Text(_selectedDate == null
                            ? 'Select date'
                            : '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: _pickTime,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Time',
                          prefixIcon: Icon(Icons.access_time),
                        ),
                        child: Text(_selectedTime == null
                            ? 'Select time'
                            : _selectedTime!.format(context)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _purposeController,
                decoration: const InputDecoration(labelText: 'Purpose', prefixIcon: Icon(Icons.info)),
                validator: (v) => v == null || v.isEmpty ? 'Enter purpose' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(labelText: 'Notes/History', prefixIcon: Icon(Icons.notes)),
                maxLines: 3,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
                child: _isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Add Appointment'),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 