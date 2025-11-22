class Message {
  final String? id;
  final String chatId;
  final String senderId;
  final String senderEmail;
  final String content;
  final DateTime sentAt;

  Message({
    this.id,
    required this.chatId,
    required this.senderId,
    required this.senderEmail,
    required this.content,
    required this.sentAt,
  });

  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      id: map['id'],
      chatId: map['chat_id'],
      senderId: map['sender_id'],
      senderEmail: map['sender_email'],
      content: map['content'],
      sentAt: DateTime.parse(map['sent_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'chat_id': chatId,
      'sender_id': senderId,
      'sender_email': senderEmail,
      'content': content,
      'sent_at': sentAt.toIso8601String(),
    };
  }
}
