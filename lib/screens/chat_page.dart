import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/services/mock_database.dart';

class ChatPage extends StatefulWidget {
  final Map<String, dynamic>? worker;
  final String? bookingId;

  const ChatPage({super.key, this.worker, this.bookingId});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  Map<String, dynamic>? _workerInfo;
  bool _isLoadingWorker = false;

  @override
  void initState() {
    super.initState();
    _workerInfo = widget.worker;
    if (_workerInfo == null && widget.bookingId != null) {
      _fetchWorkerInfo(); 
    }
  }

  Future<void> _fetchWorkerInfo() async {
    setState(() => _isLoadingWorker = true);
    try {
      // 1. Get the booking to find the worker_id
      final booking = await MockDatabase.instance.client
          .from('bookings')
          .select('worker_id')
          .eq('id', widget.bookingId!)
          .maybeSingle();

      if (booking != null && booking['worker_id'] != null) {
        // 2. Get the worker's user_id
        final workerRec = await MockDatabase.instance.client
            .from('workers')
            .select('user_id')
            .eq('id', booking['worker_id'])
            .maybeSingle();

        if (workerRec != null) {
          // 3. Get the actual user profile (name, pic)
          final userProfile = await MockDatabase.instance.client
              .from('users')
              .select('name, profile_pic')
              .eq('id', workerRec['user_id'])
              .maybeSingle();

          if (mounted) {
            setState(() {
              _workerInfo = userProfile;
              _isLoadingWorker = false;
            });
          }
          return;
        }
      }
    } catch (e) {
      debugPrint("Error fetching worker info: $e");
    }
    if (mounted) setState(() => _isLoadingWorker = false);
  }

  Stream<List<Map<String, dynamic>>> get _messageStream =>
      MockDatabase.instance.client
          .from('messages')
          .stream(primaryKey: ['id'])
          .eq('booking_id', widget.bookingId ?? '')
          .order('created_at', ascending: true);

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || widget.bookingId == null) return;

    final user = MockDatabase.instance.auth.currentUser;
    if (user == null) return;

    try {
      await MockDatabase.instance.client.from('messages').insert({
        'booking_id': widget.bookingId,
        'sender_id': user['id'],
        'text': text,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      });
      _messageController.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to send: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF01102B),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.white24,
              backgroundImage: _workerInfo?['profile_pic'] != null
                  ? NetworkImage(_workerInfo!['profile_pic'])
                  : null,
              child: (_workerInfo?['profile_pic'] == null && !_isLoadingWorker)
                  ? const Icon(Icons.person, color: Colors.white, size: 20)
                  : _isLoadingWorker 
                    ? const SizedBox(width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : null,
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _workerInfo?['name'] ?? (_isLoadingWorker ? 'Loading...' : 'Technician'),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  _isLoadingWorker ? 'Fetching details...' : 'Online',
                  style: TextStyle(
                    fontSize: 11, 
                    color: _isLoadingWorker ? Colors.white70 : Colors.greenAccent
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.call_outlined),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _messageStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                }

                final messages = snapshot.data ?? [];
                
                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[200]),
                        const SizedBox(height: 16),
                        Text(
                          "No messages yet.\nSay hello to your technician!",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey[400], fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final currentUserId = MockDatabase.instance.auth.currentUser?['id'];
                    final isMe = msg['sender_id'] == currentUserId;
                    
                    return _buildMessageBubble({
                      ...msg,
                      'is_me': isMe,
                      'time': DateTime.parse(msg['created_at']).toLocal(),
                    });
                  },
                );
              },
            ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> msg) {
    final bool isMe = msg['is_me'];
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFF01102B) : const Color(0xFFF6F6F6),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isMe ? 20 : 0),
            bottomRight: Radius.circular(isMe ? 0 : 20),
          ),
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              msg['text'],
              style: TextStyle(
                color: isMe ? Colors.white : Colors.black87,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('h:mm a').format(msg['time']),
              style: TextStyle(
                color: isMe ? Colors.white70 : Colors.grey[500],
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF6F6F6),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _messageController,
                  decoration: const InputDecoration(
                    hintText: 'Type a message...',
                    border: InputBorder.none,
                    hintStyle: TextStyle(fontSize: 14),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: _sendMessage,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: Color(0xFF01102B),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
