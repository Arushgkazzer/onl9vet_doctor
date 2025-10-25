import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:async';
import 'dart:io';
import 'video_call_screen.dart';
import 'prescription_screen.dart';
import '../services/firebase_appointment_service.dart';

class ChatScreen extends StatefulWidget {
  final String appointmentId;
  final String patientName;

  const ChatScreen({Key? key, required this.appointmentId, required this.patientName}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];
  late final FirebaseFirestore _firestore;
  late final FirebaseAuth _auth;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subscription;
  bool _isUploading = false;
  String? _doctorName;

  @override
  void initState() {
    super.initState();
    _firestore = FirebaseFirestore.instance;
    _auth = FirebaseAuth.instance;
    _subscribeToChannel();
    _loadDoctorName();
  }

  Future<void> _loadDoctorName() async {
    try {
      final profile = await FirebaseAppointmentService().getCurrentUserProfile();
      setState(() {
        _doctorName = profile?['name'] ?? 'Dr. Unknown';
      });
    } catch (e) {
      setState(() {
        _doctorName = 'Dr. Unknown';
      });
    }
  }

  void _subscribeToChannel() {
    final messagesRef = _firestore
        .collection('chats')
        .doc(widget.appointmentId)
        .collection('messages')
        .orderBy('timestamp', descending: false);

    _subscription = messagesRef.snapshots().listen((snapshot) {
      print('Received ${snapshot.docs.length} messages'); // Debug log
      final items = snapshot.docs.map((d) => {
        'id': d.id,
        ...d.data(),
      }).toList();
      
      final formatted = items.map((m) {
        final text = (m['text'] as String?) ?? '';
        final sender = (m['sender'] as String?) ?? 'User';
        final tsField = m['timestamp'];
        final ts = tsField is Timestamp 
            ? tsField.toDate() 
            : (tsField != null 
                ? DateTime.tryParse(tsField.toString()) ?? DateTime.now()
                : DateTime.now());
        final isMe = (m['senderId'] == _auth.currentUser?.uid);
        final fileUrl = m['fileUrl'] as String?;
        final fileType = m['fileType'] as String?;
        final fileName = m['fileName'] as String?;
        
        print('Message: $text, isMe: $isMe, timestamp: $ts'); // Debug log
        
        return _ChatMessage(
          text: text,
          sender: sender,
          isMe: isMe,
          timestamp: ts,
          fileUrl: fileUrl,
          fileType: fileType,
          fileName: fileName,
        );
      }).toList();
      
      // Sort by timestamp to ensure proper order
      formatted.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      
      setState(() {
        _messages
          ..clear()
          ..addAll(formatted);
      });
      _scrollToBottom();
    }, onError: (error) {
      print('Error listening to messages: $error');
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    
    final uid = _auth.currentUser?.uid;
    final email = _auth.currentUser?.email ?? 'Doctor';
    
    _messageController.clear();
    
    try {
      final docRef = _firestore.collection('chats').doc(widget.appointmentId).collection('messages').doc();
      await docRef.set({
        'id': docRef.id,
        'text': text,
        'sender': email,
        'senderId': uid,
        'timestamp': FieldValue.serverTimestamp(),
        'created_at': DateTime.now().toIso8601String(), // Fallback timestamp
      });
      print('Message sent: $text'); // Debug log
    } catch (e) {
      print('Error sending message: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send message: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        print('Image picked: ${pickedFile.path}'); // Debug log
        await _uploadFile(File(pickedFile.path), 'image');
      }
    } catch (e) {
      print('Error picking image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick image: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _pickDocument() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      if (result != null && result.files.single.path != null) {
        print('Document picked: ${result.files.single.path}'); // Debug log
        await _uploadFile(File(result.files.single.path!), 'document');
      }
    } catch (e) {
      print('Error picking document: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick document: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _uploadFile(File file, String type) async {
    setState(() => _isUploading = true);
    try {
      // Check if file exists and is readable
      if (!await file.exists()) {
        throw Exception('File does not exist: ${file.path}');
      }
      
      // Get file name with proper path handling
      final originalFileName = file.path.split(Platform.pathSeparator).last;
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_$originalFileName';
      
      print('Uploading file: $fileName, type: $type, size: ${await file.length()} bytes'); // Debug log
      
      // Create Firebase Storage reference with user ID for better organization
      final uid = _auth.currentUser?.uid;
      if (uid == null) {
        throw Exception('User not authenticated');
      }
      
      final ref = FirebaseStorage.instance
          .ref()
          .child('chat_files')
          .child(widget.appointmentId)
          .child(fileName);
      
      print('Storage reference path: ${ref.fullPath}'); // Debug log
      
      // Upload file with metadata
      final metadata = SettableMetadata(
        contentType: type == 'image' ? 'image/jpeg' : 'application/pdf',
        customMetadata: {
          'uploadedBy': uid,
          'appointmentId': widget.appointmentId,
          'originalName': originalFileName,
        },
      );
      
      final uploadTask = ref.putFile(file, metadata);
      
      // Monitor upload progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        print('Upload progress: ${(progress * 100).toStringAsFixed(1)}%');
      });
      
      final snapshot = await uploadTask;
      print('Upload completed. State: ${snapshot.state}');
      
      // Get download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();
      print('File uploaded successfully: $downloadUrl'); // Debug log
      
      // Save message to Firestore
      final email = _auth.currentUser?.email ?? 'Doctor';
      final docRef = _firestore.collection('chats').doc(widget.appointmentId).collection('messages').doc();
      
      await docRef.set({
        'id': docRef.id,
        'text': type == 'image' ? '📷 Image shared' : '📄 Document shared',
        'sender': email,
        'senderId': uid,
        'timestamp': FieldValue.serverTimestamp(),
        'created_at': DateTime.now().toIso8601String(), // Fallback timestamp
        'fileUrl': downloadUrl,
        'fileType': type,
        'fileName': originalFileName,
      });
      
      print('File message saved to Firestore'); // Debug log
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${type == 'image' ? 'Image' : 'Document'} shared successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      
    } catch (e) {
      print('Error uploading file: $e'); // Debug log
      String errorMessage = 'Failed to upload file';
      
      if (e.toString().contains('object-not-found')) {
        errorMessage = 'Storage configuration error. Please check Firebase Storage rules.';
      } else if (e.toString().contains('unauthorized')) {
        errorMessage = 'Permission denied. Please check authentication.';
      } else if (e.toString().contains('network')) {
        errorMessage = 'Network error. Please check your connection.';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$errorMessage: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      setState(() => _isUploading = false);
    }
  }

  Future<void> _endChat() async {
    final shouldEnd = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('End Chat'),
        content: const Text('Are you sure you want to end this chat and create a prescription?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
            child: const Text('End Chat', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (shouldEnd == true && _doctorName != null) {
      final result = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (context) => PrescriptionScreen(
            appointmentId: widget.appointmentId,
            patientName: widget.patientName,
            doctorName: _doctorName!,
          ),
        ),
      );
      
      if (result == true) {
        Navigator.of(context).pop(); // Return to previous screen
      }
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat with ${widget.patientName}'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => VideoCallScreen(
                      appointmentId: widget.appointmentId,
                      vetName: widget.patientName,
                      appointmentTime: DateTime.now(),
                      isVet: true,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.video_call, size: 18, color: Colors.white),
              label: const Text('Call', style: TextStyle(color: Colors.white, fontSize: 12)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ElevatedButton.icon(
              onPressed: _endChat,
              icon: const Icon(Icons.medical_services, size: 18, color: Colors.white),
              label: const Text('End Chat', style: TextStyle(color: Colors.white, fontSize: 12)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return Align(
                  alignment: msg.isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: msg.isMe ? Colors.teal : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!msg.isMe)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              msg.sender,
                              style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                            ),
                          ),
                        if (msg.fileUrl != null && msg.fileType == 'image')
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  msg.fileUrl!,
                                  width: 200,
                                  height: 150,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      width: 200,
                                      height: 150,
                                      color: Colors.grey.shade300,
                                      child: const Icon(Icons.error),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                msg.text,
                                style: TextStyle(color: msg.isMe ? Colors.white : Colors.black),
                              ),
                            ],
                          )
                        else if (msg.fileUrl != null && msg.fileType == 'document')
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: msg.isMe ? Colors.white.withOpacity(0.2) : Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.picture_as_pdf,
                                      color: msg.isMe ? Colors.white : Colors.red,
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        msg.fileName ?? 'Document',
                                        style: TextStyle(
                                          color: msg.isMe ? Colors.white : Colors.black,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                msg.text,
                                style: TextStyle(color: msg.isMe ? Colors.white : Colors.black),
                              ),
                            ],
                          )
                        else
                          Text(
                            msg.text,
                            style: TextStyle(color: msg.isMe ? Colors.white : Colors.black),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Column(
                children: [
                  if (_isUploading)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: Colors.teal.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.teal.shade200),
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.teal),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text('Uploading file...', style: TextStyle(color: Colors.teal)),
                        ],
                      ),
                    ),
                  Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.teal.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.teal.shade200),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              onPressed: _isUploading ? null : _pickImage,
                              icon: Icon(Icons.image, color: Colors.teal.shade700),
                              tooltip: 'Share Image',
                            ),
                            IconButton(
                              onPressed: _isUploading ? null : _pickDocument,
                              icon: Icon(Icons.picture_as_pdf, color: Colors.teal.shade700),
                              tooltip: 'Share PDF',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          decoration: const InputDecoration(
                            hintText: 'Type your message...',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _sendMessage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Send'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatMessage {
  final String text;
  final String sender;
  final bool isMe;
  final DateTime timestamp;
  final String? fileUrl;
  final String? fileType;
  final String? fileName;

  _ChatMessage({
    required this.text,
    required this.sender,
    required this.isMe,
    required this.timestamp,
    this.fileUrl,
    this.fileType,
    this.fileName,
  });
}


