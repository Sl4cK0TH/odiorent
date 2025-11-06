class Message {
  final String? id;
  final String chatId;
  final String senderId;
  final String senderEmail;
  final String content;
  final DateTime timestamp;

  Message({
    this.id,
    required this.chatId,
    required this.senderId,
    required this.senderEmail,
    required this.content,
    required this.timestamp,
  });

  // Convert Message to Map (for inserting to database)
  Map<String, dynamic> toMap() {
    return {
      'chat_id': chatId,
      'sender_id': senderId,
      'sender_email': senderEmail,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  // Create Message from Map (from database)
  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      id: map['id']?.toString(),
      chatId: map['chat_id'] ?? '',
      senderId: map['sender_id'] ?? '',
      senderEmail: map['sender_email'] ?? '',
      content: map['content'] ?? '',
      timestamp: DateTime.parse(
        map['timestamp'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }
}
