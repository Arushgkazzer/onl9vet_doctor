import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'video_call_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _firestore = FirebaseFirestore.instance;
    _auth = FirebaseAuth.instance;
    _subscribeToChannel();
  }

  void _subscribeToChannel() {
    final messagesRef = _firestore
        .collection('chats')
        .doc(widget.appointmentId)
        .collection('messages')
        .orderBy('timestamp');

    _subscription = messagesRef.snapshots().listen((snapshot) {
      final items = snapshot.docs.map((d) => d.data()).toList();
      final formatted = items.map((m) {
        final text = (m['text'] as String?) ?? '';
        final sender = (m['sender'] as String?) ?? 'User';
        final tsField = m['timestamp'];
        final ts = tsField is Timestamp ? tsField.toDate() : DateTime.tryParse(tsField?.toString() ?? '') ?? DateTime.now();
        final isMe = (m['senderId'] == _auth.currentUser?.uid);
        return _ChatMessage(text: text, sender: sender, isMe: isMe, timestamp: ts);
      }).toList();
      setState(() {
        _messages
          ..clear()
          ..addAll(formatted);
      });
      _scrollToBottom();
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    _messageController.clear();
    final uid = _auth.currentUser?.uid;
    final email = _auth.currentUser?.email ?? 'Doctor';
    final docRef = _firestore.collection('chats').doc(widget.appointmentId).collection('messages').doc();
    await docRef.set({
      'id': docRef.id,
      'text': text,
      'sender': email,
      'senderId': uid,
      'timestamp': FieldValue.serverTimestamp(),
    });
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
            padding: const EdgeInsets.symmetric(horizontal: 8),
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
              icon: const Icon(Icons.video_call, size: 20, color: Colors.white),
              label: const Text('Start Call', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
              child: Row(
                children: [
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
                    child: const Text('Send'),
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

  _ChatMessage({required this.text, required this.sender, required this.isMe, required this.timestamp});
}


