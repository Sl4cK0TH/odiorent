import 'package:cloud_firestore/cloud_firestore.dart';

// Enum to represent the type of attachment in a message
enum MessageAttachmentType {
  image,
  video,
  file,
}

// Helper to convert string to enum
MessageAttachmentType? attachmentTypeFromString(String? type) {
  if (type == null) return null;
  switch (type) {
    case 'image':
      return MessageAttachmentType.image;
    case 'video':
      return MessageAttachmentType.video;
    case 'file':
      return MessageAttachmentType.file;
    default:
      return null;
  }
}

// Helper to convert enum to string
String? attachmentTypeToString(MessageAttachmentType? type) {
  return type?.toString().split('.').last;
}


class Message {
  final String? id;
  final String chatId;
  final String senderId;
  final String? text; // Was 'content', now nullable
  final DateTime sentAt;

  // New fields for read receipts and attachments
  final DateTime? readAt;
  final String? attachmentUrl;
  final MessageAttachmentType? attachmentType;

  Message({
    this.id,
    required this.chatId,
    required this.senderId,
    this.text, // Nullable
    required this.sentAt,
    this.readAt, // Nullable
    this.attachmentUrl, // Nullable
    this.attachmentType, // Nullable
  });

  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      id: map['id'],
      chatId: map['chat_id'],
      senderId: map['sender_id'],
      text: map['text'], // Now 'text'
      sentAt: DateTime.parse(map['sent_at']),
      readAt: map['read_at'] != null ? DateTime.parse(map['read_at']) : null,
      attachmentUrl: map['attachment_url'],
      attachmentType: attachmentTypeFromString(map['attachment_type']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'chat_id': chatId,
      'sender_id': senderId,
      'text': text,
      'sent_at': sentAt.toIso8601String(),
      'read_at': readAt?.toIso8601String(),
      'attachment_url': attachmentUrl,
      'attachment_type': attachmentTypeToString(attachmentType),
    };
  }

  /// --- `toFirestore` Method ---
  /// Converts a Message object into a Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'chatId': chatId,
      'senderId': senderId,
      'text': text,
      'sentAt': Timestamp.fromDate(sentAt),
      'readAt': readAt != null ? Timestamp.fromDate(readAt!) : null,
      'attachmentUrl': attachmentUrl,
      'attachmentType': attachmentTypeToString(attachmentType),
    };
  }

  /// --- `fromFirestore` Factory ---
  /// Creates a Message object from a Firestore DocumentSnapshot
  factory Message.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Message(
      id: doc.id,
      chatId: data['chatId'] as String,
      senderId: data['senderId'] as String,
      text: data['text'] as String?,
      sentAt: (data['sentAt'] as Timestamp).toDate(),
      readAt: (data['readAt'] as Timestamp?)?.toDate(),
      attachmentUrl: data['attachmentUrl'] as String?,
      attachmentType: attachmentTypeFromString(data['attachmentType'] as String?),
    );
  }
}
