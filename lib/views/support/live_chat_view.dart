import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../widgets/common_header.dart';
import '../../widgets/dismiss_keyboard.dart';

class LiveChatView extends StatefulWidget {
  const LiveChatView({Key? key}) : super(key: key);

  @override
  State<LiveChatView> createState() => _LiveChatViewState();
}

class _LiveChatViewState extends State<LiveChatView> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String? _currentRoomId;
  bool _isSending = false;
  bool _didMarkRead = false;
  bool _isMarkingMessageRead = false;
  bool _isNearBottom = true;
  bool _forceScrollOnSend = false;
  String? _lastSeenMessageId;
  Timer? _markReadTimer;
  bool _hasAutoScrolledToBottom = true;

  static const double _autoScrollThreshold = 120;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
  }

  @override
  void dispose() {
    _markReadTimer?.cancel();
    _scrollController.removeListener(_handleScroll);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage({
    required String roomId,
    required String userId,
  }) async {
    final text = _messageController.text.trim();
    if (text.isEmpty) {
      return;
    }
    if (_isSending) {
      return;
    }

    setState(() {
      _isSending = true;
    });

    try {
      final roomRef =
          FirebaseFirestore.instance.collection('service_chat_rooms').doc(roomId);
      final roomSnap = await roomRef.get();
      if (!roomSnap.exists) {
        await roomRef.set({
          'roomId': roomId,
          'userId': userId,
          'userUnreadCount': 0,
          'ownerUnreadCount': 0,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      final messageRef = roomRef.collection('messages').doc();
      await messageRef.set({
        'messageId': messageRef.id,
        'roomId': roomId,
        'userId': userId,
        'senderId': userId,
        'senderRole': 'user',
        'text': text,
        'createdAt': FieldValue.serverTimestamp(),
        'readByUserAt': null,
        'readByOwnerAt': null,
      });

      _messageController.clear();
      _forceScrollOnSend = true;
      _scrollToBottom();
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    _isNearBottom = position.pixels <= _autoScrollThreshold;
  }

  Future<void> _markAsRead(String roomId) async {
    if (_didMarkRead) return;
    _didMarkRead = true;
    await FirebaseFirestore.instance
        .collection('service_chat_rooms')
        .doc(roomId)
        .set({
      'userLastReadAt': FieldValue.serverTimestamp(),
      'userUnreadCount': 0,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> _markMessagesAsRead(List<QueryDocumentSnapshot> docs) async {
    if (_isMarkingMessageRead) return;
    final batch = FirebaseFirestore.instance.batch();
    int updatedCount = 0;
    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final senderRole = (data['senderRole'] ?? '').toString();
      final alreadyRead = data['readByUserAt'] != null;
      if (senderRole == 'owner' && !alreadyRead) {
        batch.update(doc.reference, {
          'readByUserAt': FieldValue.serverTimestamp(),
        });
        updatedCount++;
      }
    }
    if (updatedCount == 0) {
      return;
    }
    _isMarkingMessageRead = true;
    try {
      await batch.commit();
    } finally {
      _isMarkingMessageRead = false;
    }
  }

  void _scheduleMarkRead(String roomId, List<QueryDocumentSnapshot> docs) {
    _markReadTimer?.cancel();
    _markReadTimer = Timer(const Duration(milliseconds: 200), () {
      if (!mounted) return;
      _markAsRead(roomId);
      _markMessagesAsRead(docs);
    });
  }

  void _handleNewSnapshot(String roomId, List<QueryDocumentSnapshot> docs) {
    if (docs.isEmpty) return;
    final latestId = docs.last.id;
    if (latestId == _lastSeenMessageId) return;
    _lastSeenMessageId = latestId;

    final shouldScroll = _forceScrollOnSend || _isNearBottom;
    if (shouldScroll) {
      _forceScrollOnSend = false;
      _scrollToBottom();
    }
    if (shouldScroll) {
      _scheduleMarkRead(roomId, docs);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        appBar: const CommonHeader(title: 'ライブチャット'),
        backgroundColor: Colors.grey[50],
        body: const Center(
          child: Text('ログインが必要です'),
        ),
      );
    }

    return Scaffold(
      appBar: const CommonHeader(
        title: 'ライブチャット',
      ),
      backgroundColor: Colors.grey[50],
      body: DismissKeyboard(
        child: _buildChatBody(user),
      ),
    );
  }

  Widget _buildChatBody(User user) {
    final roomId = user.uid;
    if (_currentRoomId != roomId) {
      _currentRoomId = roomId;
      _didMarkRead = false;
      _markReadTimer?.cancel();
      _lastSeenMessageId = null;
      _forceScrollOnSend = false;
      _hasAutoScrolledToBottom = true;
    }

    final messagesStream = FirebaseFirestore.instance
        .collection('service_chat_rooms')
        .doc(roomId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .snapshots();

    return Column(
      children: [
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: messagesStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              final docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty) {
                return const Center(
                  child: Text('メッセージはまだありません'),
                );
              }

              _handleNewSnapshot(roomId, docs);

              return ListView.separated(
                controller: _scrollController,
                reverse: true,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                itemCount: docs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  final senderId = (data['senderId'] ?? '').toString();
                  final text = (data['text'] ?? '').toString();
                  final createdAt = data['createdAt'];
                  final timeText = _formatTime(createdAt);
                  final isMe = senderId == user.uid;
                  final statusText = isMe && data['readByOwnerAt'] != null
                      ? '既読'
                      : null;
                  return _ChatBubble(
                    message: _ChatMessage(
                      text: text,
                      time: timeText,
                      isMe: isMe,
                    ),
                    statusText: statusText,
                  );
                },
              );
            },
          ),
        ),
        SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Color(0xFFE0E0E0)),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    minLines: 1,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'メッセージを入力',
                      hintStyle: const TextStyle(fontSize: 13),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _isSending
                      ? null
                      : () => _sendMessage(
                            roomId: roomId,
                            userId: user.uid,
                          ),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: _isSending
                          ? const Color(0xFFFF6B35).withOpacity(0.6)
                          : const Color(0xFFFF6B35),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.send,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

String _formatTime(dynamic createdAt) {
  final time = _toDateTime(createdAt);
  if (time == null) return '';
  final hour = time.hour.toString().padLeft(2, '0');
  final minute = time.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

DateTime? _toDateTime(dynamic value) {
  if (value is Timestamp) {
    return value.toDate();
  }
  if (value is String) {
    return DateTime.tryParse(value);
  }
  if (value is DateTime) {
    return value;
  }
  return null;
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({
    required this.message,
    this.statusText,
  });

  final _ChatMessage message;
  final String? statusText;

  @override
  Widget build(BuildContext context) {
    final alignment =
        message.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final bubbleColor =
        message.isMe ? const Color(0xFFFF6B35) : Colors.white;
    final textColor = message.isMe ? Colors.white : Colors.black87;
    final border = message.isMe
        ? null
        : Border.all(color: const Color(0xFFE0E0E0));

    return Column(
      crossAxisAlignment: alignment,
      children: [
        Align(
          alignment:
              message.isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 260),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: BorderRadius.circular(16),
                border: border,
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: textColor,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                message.time,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
              if (statusText != null) ...[
                const SizedBox(width: 6),
                Text(
                  statusText!,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ChatMessage {
  const _ChatMessage({
    required this.text,
    required this.time,
    required this.isMe,
  });

  final String text;
  final String time;
  final bool isMe;
}
