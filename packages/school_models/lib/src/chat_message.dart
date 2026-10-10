class ChatMessage {
  final String id;
  final String conversationId;
  final String schoolId;
  final String senderId;
  final String senderName;
  final String messageType;
  final String? text;
  final String? attachmentUrl;
  final String? attachmentName;
  final String? replyToMessageId;
  final bool isEdited;
  final bool isDeleted;
  final DateTime? sentAt;
  final DateTime? editedAt;
  final DateTime? createdAt;

  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.schoolId,
    required this.senderId,
    required this.senderName,
    this.messageType = 'text',
    this.text,
    this.attachmentUrl,
    this.attachmentName,
    this.replyToMessageId,
    this.isEdited = false,
    this.isDeleted = false,
    this.sentAt,
    this.editedAt,
    this.createdAt,
  });

  factory ChatMessage.fromMap(
    String id,
    Map<String, dynamic> map,
  ) {
    return ChatMessage(
      id: id,
      conversationId: map['conversationId'] as String? ?? '',
      schoolId: map['schoolId'] as String? ?? '',
      senderId: map['senderId'] as String? ?? '',
      senderName: map['senderName'] as String? ?? '',
      messageType: map['messageType'] as String? ?? 'text',
      text: map['text'] as String?,
      attachmentUrl: map['attachmentUrl'] as String?,
      attachmentName: map['attachmentName'] as String?,
      replyToMessageId: map['replyToMessageId'] as String?,
      isEdited: map['isEdited'] as bool? ?? false,
      isDeleted: map['isDeleted'] as bool? ?? false,
      sentAt: _chatMessageDateTime(map['sentAt']),
      editedAt: _chatMessageDateTime(map['editedAt']),
      createdAt: _chatMessageDateTime(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'conversationId': conversationId,
      'schoolId': schoolId,
      'senderId': senderId,
      'senderName': senderName,
      'messageType': messageType,
      'text': text,
      'attachmentUrl': attachmentUrl,
      'attachmentName': attachmentName,
      'replyToMessageId': replyToMessageId,
      'isEdited': isEdited,
      'isDeleted': isDeleted,
      'sentAt': sentAt,
      'editedAt': editedAt,
      'createdAt': createdAt,
    };
  }

  bool get isTextMessage => messageType == 'text';

  bool get isImageMessage => messageType == 'image';

  bool get isFileMessage => messageType == 'file';

  bool get hasAttachment => attachmentUrl != null &&
      attachmentUrl!.isNotEmpty;

  ChatMessage copyWith({
    String? id,
    String? conversationId,
    String? schoolId,
    String? senderId,
    String? senderName,
    String? messageType,
    String? text,
    String? attachmentUrl,
    String? attachmentName,
    String? replyToMessageId,
    bool? isEdited,
    bool? isDeleted,
    DateTime? sentAt,
    DateTime? editedAt,
    DateTime? createdAt,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      schoolId: schoolId ?? this.schoolId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      messageType: messageType ?? this.messageType,
      text: text ?? this.text,
      attachmentUrl: attachmentUrl ?? this.attachmentUrl,
      attachmentName: attachmentName ?? this.attachmentName,
      replyToMessageId: replyToMessageId ?? this.replyToMessageId,
      isEdited: isEdited ?? this.isEdited,
      isDeleted: isDeleted ?? this.isDeleted,
      sentAt: sentAt ?? this.sentAt,
      editedAt: editedAt ?? this.editedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

DateTime? _chatMessageDateTime(dynamic value) {
  if (value == null) return null;

  if (value is DateTime) return value;

  if (value is String) {
    return DateTime.tryParse(value);
  }

  try {
    final dynamic timestamp = value;
    final DateTime date = timestamp.toDate() as DateTime;
    return date;
  } catch (_) {
    return null;
  }
}