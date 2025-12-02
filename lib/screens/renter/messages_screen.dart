import 'package:flutter/material.dart';
import 'package:odiorent/models/chat.dart';
import 'package:odiorent/services/auth_service.dart';
import 'package:odiorent/services/database_service.dart';
import 'package:odiorent/screens/shared/chat_room_screen.dart';
import 'package:timeago/timeago.dart' as timeago;

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  static const Color primaryGreen = Color(0xFF4CAF50);
  static const Color lightGreen = Color(0xFF66BB6A);

  final _dbService = DatabaseService();
  final _authService = AuthService();
  List<Chat> _chats = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadChats();
  }

  Future<void> _loadChats() async {
    final user = _authService.getCurrentUser();
    if (user == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final chatsData = await _dbService.getUserChats(user.id);
      setState(() {
        _chats = chatsData.map((data) => Chat.fromMap(data, user.id)).toList();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading chats: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        backgroundColor: lightGreen,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryGreen))
          : _chats.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.message_outlined, size: 80, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text(
                        'No messages yet',
                        style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Start chatting with landlords',
                        style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadChats,
                  color: primaryGreen,
                  child: ListView.builder(
                    itemCount: _chats.length,
                    itemBuilder: (context, index) {
                      final chat = _chats[index];
                      return _buildChatTile(chat);
                    },
                  ),
                ),
    );
  }

  Widget _buildChatTile(Chat chat) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: CircleAvatar(
        radius: 28,
        backgroundColor: lightGreen.withAlpha(51),
        backgroundImage: chat.otherUserProfilePicture != null
            ? NetworkImage(chat.otherUserProfilePicture!)
            : null,
        child: chat.otherUserProfilePicture == null
            ? Text(
                chat.otherUserDisplayName.isNotEmpty
                    ? chat.otherUserDisplayName[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  color: primaryGreen,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              )
            : null,
      ),
      title: Text(
        chat.otherUserDisplayName,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (chat.propertyName != null)
            Text(
              chat.propertyName!,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          if (chat.lastMessage != null)
            Text(
              chat.lastMessage!,
              style: const TextStyle(fontSize: 14),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
      trailing: chat.lastMessageAt != null
          ? Text(
              timeago.format(chat.lastMessageAt!),
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            )
          : null,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatRoomScreen(
              chatId: chat.id,
              propertyName: chat.propertyName ?? 'Property',
              otherUserName: chat.otherUserDisplayName,
              otherUserProfileUrl: chat.otherUserProfilePicture,
              otherUserId: chat.otherUserId,
            ),
          ),
        ).then((_) => _loadChats()); // Reload chats when returning
      },
    );
  }
}