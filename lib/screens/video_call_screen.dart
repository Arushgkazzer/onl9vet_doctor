import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class VideoCallScreen extends StatefulWidget {
  final String appointmentId;
  final String vetName;
  final DateTime appointmentTime;
  final bool isVet;

  const VideoCallScreen({
    super.key,
    required this.appointmentId,
    required this.vetName,
    required this.appointmentTime,
    this.isVet = true, // Doctor app defaults to true
  });

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  int? _remoteUid;
  bool _localUserJoined = false;
  late RtcEngine _engine;
  bool _isMuted = false;
  bool _isCameraOff = false;
  bool _isCallEnded = false;
  int _elapsedSeconds = 0;
  late DateTime _callStartTime;
  bool _isChatVisible = false;
  final TextEditingController _chatController = TextEditingController();
  final List<ChatMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _callStartTime = DateTime.now();
    _initializeAgora();
    _startTimer();
  }

  void _startTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (!_isCallEnded) {
        setState(() {
          _elapsedSeconds++;
        });
        _startTimer();
      }
    });
  }

  Future<void> _initializeAgora() async {
    // Request permissions
    await [Permission.microphone, Permission.camera].request();

    // Create RTC Engine
    _engine = createAgoraRtcEngine();
    await _engine.initialize(const RtcEngineContext(
      appId: "5c2964674882441487114bd9811c8d0d",
      channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
    ));

    // Enable video
    await _engine.enableVideo();
    await _engine.startPreview();
    await _engine.setChannelProfile(
      ChannelProfileType.channelProfileLiveBroadcasting,
    );
    await _engine.setClientRole(role: ClientRoleType.clientRoleBroadcaster);

    // Set up event handlers
    _engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (connection, elapsed) {
          setState(() {
            _localUserJoined = true;
          });
        },
        onUserJoined: (connection, remoteUid, elapsed) {
          setState(() {
            _remoteUid = remoteUid;
          });
        },
        onUserOffline: (connection, remoteUid, reason) {
          setState(() {
            _remoteUid = null;
          });
        },
      ),
    );

    try {
      // Using a temporary hardcoded token for development
      // In production, you should generate this token using Firebase Functions
      // or another secure method
      final token = "007eJxTYLhgJPfwQMiJxpCZQvMWXlj+5cCBhLVXbK5sPXrm+Iqr/FsUGCzNzU0tLE1NLZJSzFMtzRKTjA0TLU1TLI0Sk5JNTVL1Jzs3hzAyMkAwCDAxMDIwMTADAJFYHhQ=";
      
      // For a real implementation, you would use Firebase to store and retrieve tokens
      // Example with Firebase:
      // final tokenDoc = await FirebaseFirestore.instance
      //     .collection('agoraTokens')
      //     .doc(widget.appointmentId)
      //     .get();
      // final token = tokenDoc.data()?['token'] as String;
      await _engine.joinChannel(
        token: token,
        channelId: widget.appointmentId,
        uid: 0,
        options: const ChannelMediaOptions(),
      );
    } catch (e) {
      print('Error getting token: $e');
      // Handle error appropriately
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to join video call. Please try again.'),
          ),
        );
      }
    }
  }

  void _sendMessage() {
    if (_chatController.text.trim().isNotEmpty) {
      setState(() {
        _messages.add(
          ChatMessage(
            text: _chatController.text,
            isMe: true,
            timestamp: DateTime.now(),
          ),
        );
        _chatController.clear();
      });
      _scrollToBottom();
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

  @override
  void dispose() {
    _isCallEnded = true;
    _engine.leaveChannel();
    _engine.release();
    _chatController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String _formatDuration(int seconds) {
    final duration = Duration(seconds: seconds);
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final secs = twoDigits(duration.inSeconds.remainder(60));
    return "$hours:$minutes:$secs";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Remote video
          Center(
            child: _remoteVideo(),
          ),
          // Local video
          Align(
            alignment: Alignment.topRight,
            child: Container(
              width: 100,
              height: 150,
              margin: const EdgeInsets.all(16),
              child: _localUserJoined
                  ? AgoraVideoView(
                      controller: VideoViewController(
                        rtcEngine: _engine,
                        canvas: const VideoCanvas(uid: 0),
                      ),
                    )
                  : const CircularProgressIndicator(),
            ),
          ),
          // Call info
          Positioned(
            top: 40,
            left: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Consultation with ${widget.vetName}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Started at ${DateFormat('hh:mm a').format(_callStartTime)}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                Text(
                  'Duration: ${_formatDuration(_elapsedSeconds)}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          // Chat panel
          if (_isChatVisible)
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              width: 300,
              child: Container(
                color: Colors.black.withOpacity(0.8),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      color: Colors.blue,
                      child: Row(
                        children: [
                          const Text(
                            'Chat',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: () {
                              setState(() {
                                _isChatVisible = false;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(8),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final message = _messages[index];
                          return _buildChatMessage(message);
                        },
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _chatController,
                              decoration: const InputDecoration(
                                hintText: 'Type a message...',
                                border: InputBorder.none,
                              ),
                              onSubmitted: (_) => _sendMessage(),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.send),
                            onPressed: _sendMessage,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          // Controls
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildControlButton(
                  icon: _isMuted ? Icons.mic_off : Icons.mic,
                  onPressed: () {
                    setState(() {
                      _isMuted = !_isMuted;
                    });
                    _engine.muteLocalAudioStream(_isMuted);
                  },
                ),
                _buildControlButton(
                  icon: Icons.call_end,
                  backgroundColor: Colors.red,
                  onPressed: () {
                    _isCallEnded = true;
                    Navigator.pop(context);
                  },
                ),
                _buildControlButton(
                  icon: _isCameraOff ? Icons.videocam_off : Icons.videocam,
                  onPressed: () {
                    setState(() {
                      _isCameraOff = !_isCameraOff;
                    });
                    _engine.muteLocalVideoStream(_isCameraOff);
                  },
                ),
                _buildControlButton(
                  icon: Icons.chat,
                  onPressed: () {
                    setState(() {
                      _isChatVisible = !_isChatVisible;
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatMessage(ChatMessage message) {
    return Align(
      alignment: message.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: message.isMe ? Colors.blue : Colors.grey[800],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.text,
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('hh:mm a').format(message.timestamp),
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    Color backgroundColor = Colors.white24,
  }) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: backgroundColor,
      ),
      child: IconButton(
        icon: Icon(icon),
        color: Colors.white,
        onPressed: onPressed,
      ),
    );
  }

  Widget _remoteVideo() {
    if (_remoteUid != null) {
      return AgoraVideoView(
        controller: VideoViewController.remote(
          rtcEngine: _engine,
          canvas: VideoCanvas(uid: _remoteUid),
          connection: RtcConnection(channelId: widget.appointmentId),
        ),
      );
    } else {
      return const Center(
        child: Text(
          'Waiting for the other participant...',
          style: TextStyle(color: Colors.white),
        ),
      );
    }
  }
}

class ChatMessage {
  final String text;
  final bool isMe;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isMe,
    required this.timestamp,
  });
}