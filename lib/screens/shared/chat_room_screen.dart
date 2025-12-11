import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:odiorent/models/message.dart';
import 'package:odiorent/services/firebase_auth_service.dart';
import 'package:odiorent/services/firebase_database_service.dart';
import 'package:timeago/timeago.dart' as timeago;

class ChatRoomScreen extends StatefulWidget {
  final String chatId;
  final String propertyName;
  final String otherUserName;
  final String? otherUserProfileUrl;
  final String otherUserId;
  final String? initialMessage;

  const ChatRoomScreen({
    super.key,
    required this.chatId,
    required this.propertyName,
    required this.otherUserName,
    this.otherUserProfileUrl,
    required this.otherUserId,
    this.initialMessage,
  });

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  static const Color primaryGreen = Color(0xFF4CAF50);
  static const Color lightGreen = Color(0xFF66BB6A);

  final _dbService = FirebaseDatabaseService();
  final _authService = FirebaseAuthService();
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _picker = ImagePicker();

  String? _currentUserId;
  bool _isSending = false;

  // Note: Firebase doesn't have built-in presence/typing indicators like Supabase Realtime
  // You can implement these using Firestore fields if needed
  Timer? _lastSeenTimer;

  @override
  void initState() {
    super.initState();
    _loadCurrentUserAndSetup();
    
    // Set initial message if provided (for new chats)
    if (widget.initialMessage != null) {
      _messageController.text = widget.initialMessage!;
    }
  }

  @override
  void dispose() {
    _lastSeenTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _loadCurrentUserAndSetup() {
    final user = _authService.getCurrentUser();
    if (user != null) {
      _currentUserId = user.uid;
      _setupLastSeenTimer();
      setState(() {});
    }
  }

  void _setupLastSeenTimer() {
    if (_currentUserId == null) return;

    // Mark messages as read
    _dbService.markMessagesAsRead(widget.chatId, _currentUserId!);

    // Update last seen periodically
    _lastSeenTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_currentUserId != null) {
        _dbService.updateUserLastSeen(_currentUserId!);
      }
    });
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage({XFile? attachment}) async {
    final text = _messageController.text.trim();
    if (text.isEmpty && attachment == null || _currentUserId == null) return;
    setState(() => _isSending = true);
    try {
      _messageController.clear();
      await _dbService.sendMessage(
        chatId: widget.chatId,
        senderId: _currentUserId!,
        text: text.isEmpty ? null : text,
        attachmentFile: attachment,
      );
      Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image =
          await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
      if (image != null) await _sendMessage(attachment: image);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundImage: widget.otherUserProfileUrl != null
                  ? NetworkImage(widget.otherUserProfileUrl!)
                  : null,
              child: widget.otherUserProfileUrl == null
                  ? Text(widget.otherUserName.isNotEmpty
                      ? widget.otherUserName[0].toUpperCase()
                      : '?')
                  : null,
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.otherUserName, style: const TextStyle(fontSize: 16)),
                _buildSubtitle(),
              ],
            ),
          ],
        ),
        backgroundColor: lightGreen,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Message>>(
              stream: _dbService.getChatMessages(widget.chatId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const Center(
                      child: CircularProgressIndicator(color: primaryGreen));
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                final messages = snapshot.data ?? [];
                if (messages.isEmpty) {
                  return Center(
                      child: Text('No messages yet!',
                          style: TextStyle(color: Colors.grey[600])));
                }

                WidgetsBinding.instance
                    .addPostFrameCallback((_) => _scrollToBottom());
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.senderId == _currentUserId;
                    return MessageBubble(message: message, isMe: isMe);
                  },
                );
              },
            ),
          ),
          _buildMessageInputBar(),
        ],
      ),
    );
  }

  Widget _buildSubtitle() {
    // Note: Online/typing indicators removed (Supabase Realtime feature)
    // Can be re-implemented with Firestore if needed
    return Text(
      widget.propertyName,
      style: const TextStyle(fontSize: 12, color: Colors.white70),
    );
  }

  Widget _buildMessageInputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          boxShadow: [
            BoxShadow(
                color: Colors.grey.withAlpha(76),
                spreadRadius: 1,
                blurRadius: 5)
          ]),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Row(
          children: [
            IconButton(
                icon: Icon(Icons.attach_file, color: Colors.grey[600]),
                onPressed: _isSending ? null : _pickImage),
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide: BorderSide(color: Colors.grey[300]!)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide:
                          const BorderSide(color: primaryGreen, width: 2)),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
                maxLines: null,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _isSending ? null : _sendMessage(),
              ),
            ),
            const SizedBox(width: 12),
            _isSending
                ? const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: CircularProgressIndicator(color: primaryGreen))
                : Container(
                    decoration: const BoxDecoration(
                        color: primaryGreen, shape: BoxShape.circle),
                    child: IconButton(
                        icon: const Icon(Icons.send, color: Colors.white),
                        onPressed: _sendMessage),
                  ),
          ],
        ),
      ),
    );
  }
}

class MessageBubble extends StatelessWidget {
  final Message message;
  final bool isMe;

  const MessageBubble({super.key, required this.message, required this.isMe});

  static const Color primaryGreen = Color(0xFF4CAF50);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? primaryGreen : Colors.grey[200],
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isMe ? 20 : 0),
            bottomRight: Radius.circular(isMe ? 0 : 20),
          ),
        ),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            _buildMessageContent(),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  timeago.format(message.sentAt),
                  style: TextStyle(
                      color: isMe ? Colors.white70 : Colors.grey[600],
                      fontSize: 11),
                ),
                if (isMe) ...[
                  const SizedBox(width: 8),
                  Icon(
                    message.readAt != null ? Icons.done_all : Icons.done,
                    color:
                        message.readAt != null ? Colors.blue[300] : Colors.white70,
                    size: 16,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageContent() {
    if (message.attachmentType == MessageAttachmentType.image) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12.0),
        child: FadeInImage.assetNetwork(
          placeholder: 'assets/images/logo.png',
          image: message.attachmentUrl!,
          fit: BoxFit.cover,
          imageErrorBuilder: (context, error, stackTrace) =>
              const Icon(Icons.broken_image, color: Colors.white70),
        ),
      );
    }
    return Text(message.text ?? "File",
        style:
            TextStyle(color: isMe ? Colors.white : Colors.black87, fontSize: 15));
  }
}

class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key});
  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller.drive(
          Tween(begin: 0.5, end: 1.0).chain(CurveTween(curve: Curves.easeInOut))),
      child: const Text("typing...",
          style: TextStyle(fontSize: 12, color: Colors.white70)),
    );
  }
}