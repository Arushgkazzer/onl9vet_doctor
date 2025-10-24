import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'appointments_screen.dart';
import 'patients_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;
  bool _showChangePassword = false;
  String _selectedLanguage = 'English';
  final List<String> _languages = ['English', 'Hindi'];

  // Add doctor metadata fields
  Map<String, dynamic>? _doctorMeta;
  String? _doctorEmail;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _fetchDoctorMeta();
  }

  Future<void> _fetchDoctorMeta() async {
    final user = AuthService().currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      setState(() {
        _doctorMeta = doc.data();
        _doctorEmail = user.email;
      });
    }
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final user = AuthService().currentUser;
    if (user != null) {
      try {
        final snap = await FirebaseFirestore.instance.collection('user_settings').doc(user.uid).get();
        final data = snap.data() ?? {};
        setState(() {
          _notificationsEnabled = data['notifications_enabled'] ?? true;
          _darkModeEnabled = data['dark_mode_enabled'] ?? false;
          _selectedLanguage = data['language'] ?? 'English';
        });
        // Save to local storage as well
        await prefs.setBool('notificationsEnabled', _notificationsEnabled);
        await prefs.setBool('darkModeEnabled', _darkModeEnabled);
        await prefs.setString('selectedLanguage', _selectedLanguage);
      } catch (e) {
        // Fallback to local storage if backend fetch fails
        setState(() {
          _notificationsEnabled = prefs.getBool('notificationsEnabled') ?? true;
          _darkModeEnabled = prefs.getBool('darkModeEnabled') ?? false;
          _selectedLanguage = prefs.getString('selectedLanguage') ?? 'English';
        });
      }
    } else {
      setState(() {
        _notificationsEnabled = prefs.getBool('notificationsEnabled') ?? true;
        _darkModeEnabled = prefs.getBool('darkModeEnabled') ?? false;
        _selectedLanguage = prefs.getString('selectedLanguage') ?? 'English';
      });
    }
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notificationsEnabled', _notificationsEnabled);
    await prefs.setBool('darkModeEnabled', _darkModeEnabled);
    await prefs.setString('selectedLanguage', _selectedLanguage);
    final user = AuthService().currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('user_settings').doc(user.uid).set({
        'user_id': user.uid,
        'notifications_enabled': _notificationsEnabled,
        'dark_mode_enabled': _darkModeEnabled,
        'language': _selectedLanguage,
      }, SetOptions(merge: true));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.teal,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.teal),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => Dialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: StatefulBuilder(
                      builder: (context, setState) => Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.settings, color: Colors.orange),
                              const SizedBox(width: 8),
                              Text('Settings', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal)),
                            ],
                          ),
                          const SizedBox(height: 24),
                          SwitchListTile(
                            value: _notificationsEnabled,
                            onChanged: (val) async {
                              setState(() => _notificationsEnabled = val);
                              await _saveSettings();
                            },
                            title: const Text('Enable Notifications'),
                            activeColor: Colors.orange,
                          ),
                          SwitchListTile(
                            value: _darkModeEnabled,
                            onChanged: (val) async {
                              setState(() => _darkModeEnabled = val);
                              if (val) {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Coming Soon'),
                                    content: const Text('This feature is coming soon.'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.of(context).pop(),
                                        child: const Text('OK'),
                                      ),
                                    ],
                                  ),
                                );
                              }
                              await _saveSettings();
                            },
                            title: const Text('Dark Mode'),
                            activeColor: Colors.orange,
                          ),
                          ListTile(
                            leading: const Icon(Icons.lock, color: Colors.teal),
                            title: const Text('Change Password'),
                            onTap: () {
                              Navigator.of(context).pop();
                              _showChangePasswordDialog(context);
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.language, color: Colors.teal),
                            title: const Text('Language'),
                            trailing: DropdownButton<String>(
                              value: _selectedLanguage,
                              items: _languages.map((lang) => DropdownMenuItem(value: lang, child: Text(lang))).toList(),
                              onChanged: (val) async {
                                if (val != null) {
                                  setState(() => _selectedLanguage = val);
                                  await _saveSettings();
                                }
                              },
                            ),
                          ),
                          ListTile(
                            leading: const Icon(Icons.privacy_tip, color: Colors.teal),
                            title: const Text('Privacy Policy'),
                            onTap: () {
                              Navigator.of(context).pop();
                              _showPrivacyPolicyDialog(context);
                            },
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('Close'),
                            ),
                          ),
                          const Divider(),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              icon: const Icon(Icons.logout, color: Colors.red),
                              label: const Text('Logout', style: TextStyle(color: Colors.red)),
                              onPressed: () async {
                                Navigator.of(context).pop();
                                setState(() => _isLoading = true);
                                await _authService.signOut();
                                if (mounted) {
                                  setState(() => _isLoading = false);
                                  Navigator.of(context).pushAndRemoveUntil(
                                    MaterialPageRoute(builder: (_) => DoctorLoginScreen()),
                                    (route) => false,
                                  );
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildProfileHeader(),
            const SizedBox(height: 16),
            _buildDoctorInfoCard(),
            const SizedBox(height: 16),
            _buildStatsCard(),
            const SizedBox(height: 16),
            _buildMenuItems(),
            const SizedBox(height: 16),
            _buildLogoutButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    final name = _doctorMeta?['name'] ?? 'Doctor';
    final specialization = _doctorMeta?['specialization'] ?? '';
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
              Icons.medical_services,
              size: 50,
              color: Colors.orange,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            name,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.teal,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            specialization,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.green),
            ),
            child: const Text(
              'Available',
              style: TextStyle(
                color: Colors.green,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorInfoCard() {
    final name = _doctorMeta?['name'] ?? 'Doctor';
    final email = _doctorEmail ?? '';
    final number = _doctorMeta?['number'] ?? '';
    final specialization = _doctorMeta?['specialization'] ?? '';
    final experience = _doctorMeta?['experience'] ?? '';
    final license = _doctorMeta?['license'] ?? '';
    final method = _doctorMeta?['method'] ?? '';
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
                'Personal Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow('Name', name),
          _buildInfoRow('Email', email),
          _buildInfoRow('Phone', number),
          _buildInfoRow('Specialization', specialization),
          _buildInfoRow('Experience', experience),
          _buildInfoRow('License', license),
          _buildInfoRow('Mode of Communication', method),
        ],
      ),
    );
  }

  Widget _buildStatsCard() {
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
              Icon(Icons.analytics, color: Colors.orange),
              const SizedBox(width: 8),
              Text(
                'Statistics',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem('Today', '5', 'Appointments'),
              ),
              Expanded(
                child: _buildStatItem('This Week', '32', 'Appointments'),
              ),
              Expanded(
                child: _buildStatItem('Total', '1,247', 'Patients'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, String subtitle) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.orange,
          ),
        ),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[500],
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItems() {
    final menuItems = [
      {
        'icon': Icons.calendar_today,
        'title': 'My Schedule',
        'subtitle': 'View and manage appointments',
        'color': Colors.blue,
      },
      {
        'icon': Icons.medical_services,
        'title': 'Medical Records',
        'subtitle': 'Access patient records',
        'color': Colors.green,
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
              Icon(Icons.menu, color: Colors.orange),
              const SizedBox(width: 8),
              Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...menuItems.map((item) => _buildMenuItem(item)).toList(),
        ],
      ),
    );
  }

  Widget _buildMenuItem(Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            if (item['title'] == 'My Schedule') {
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AppointmentsScreen()));
            } else if (item['title'] == 'Medical Records') {
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PatientsScreen()));
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: item['color'].withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    item['icon'],
                    color: item['color'],
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['title'],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        item['subtitle'],
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey[400],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleLogout,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text(
                'Logout',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
      ),
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

  Future<void> _handleLogout() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _authService.signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => DoctorLoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error logging out: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showChangePasswordDialog(BuildContext context) {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: oldPasswordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Old Password'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: newPasswordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'New Password'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // You can add real password change logic here
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Password changed!'), backgroundColor: Colors.green),
              );
            },
            child: const Text('Change'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Policy'),
        content: const SingleChildScrollView(
          child: Text('''
- Purpose of Platform
This platform enables registered veterinary professionals to provide remote consultations to animal owners regarding general health, nutrition, and care. It is not intended to replace in-person examinations or emergency services.

- Eligibility and Registration
Only licensed veterinary practitioners with valid credentials may register and offer consultations. You agree to provide accurate, up-to-date professional information and maintain compliance with applicable veterinary regulations.

- Nature of Teleconsultation
Consultations are conducted via chat, voice, or video. The advice provided is based solely on the information shared by the animal owner. No physical examination or diagnostic testing is possible through this platform.

- Scope and Limitations
- You must clearly communicate the limitations of teleconsultation to the pet owner.
- You shall not provide services for wildlife species, in accordance with the Wildlife (Protection) Act, 1972.
- This service is not to be used for vetrolegal or official legal documentation.

- Emergency Protocol
You must advise clients to seek immediate in-person care in case of emergencies. The platform is not equipped to handle life-threatening conditions.

- Consent and Documentation
By initiating or accepting a consultation, you confirm that informed consent has been obtained from the animal owner. You are responsible for maintaining appropriate consultation records as per regulatory guidelines.

- Data Privacy and Confidentiality
You agree to maintain the confidentiality of all client and patient information in accordance with applicable data protection laws and the platform's privacy policy.

- Professional Conduct
You agree to uphold ethical standards, avoid conflicts of interest, and refrain from prescribing medications without sufficient information or legal authority.

- Platform Usage and Availability
You are responsible for updating your availability and responding to consultations in a timely manner. The platform reserves the right to suspend or terminate access in case of misuse or non-compliance.

- Fees and Remuneration
Consultation fees and payment terms will be governed by your agreement with the platform. You are responsible for any applicable taxes or professional liabilities.

- Liability Disclaimer
The platform is a facilitator and does not assume liability for the advice provided. You are solely responsible for the professional guidance you offer.

- Amendments
These terms may be updated periodically. Continued use of the platform constitutes acceptance of the revised terms.
'''),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
} 