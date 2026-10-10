
class Conversation {
  final String id;
  final String schoolId;
  final List<String> participantIds;
  final String conversationType;
  final String? title;
  final String? studentId;
  final String? lastMessage;
  final String? lastMessageSenderId;
  final DateTime? lastMessageAt;
  final Map<String, DateTime?> lastReadAt;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Conversation({
    required this.id,
    required this.schoolId,
    required this.participantIds,
    this.conversationType = 'direct',
    this.title,
    this.studentId,
    this.lastMessage,
    this.lastMessageSenderId,
    this.lastMessageAt,
    this.lastReadAt = const {},
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  factory Conversation.fromMap(
    String id,
    Map<String, dynamic> map,
  ) {
    final rawParticipants = map['participantIds'];
    final rawLastReadAt = map['lastReadAt'];

    final participants = rawParticipants is List
        ? rawParticipants.whereType<String>().toList()
        : <String>[];

    final Map<String, DateTime?> readTimes = {};

    if (rawLastReadAt is Map) {
      for (final entry in rawLastReadAt.entries) {
        if (entry.key is String) {
          readTimes[entry.key as String] =
              _conversationDateTime(entry.value);
        }
      }
    }

    return Conversation(
      id: id,
      schoolId: map['schoolId'] as String? ?? '',
      participantIds: participants,
      conversationType:
          map['conversationType'] as String? ?? 'direct',
      title: map['title'] as String?,
      studentId: map['studentId'] as String?,
      lastMessage: map['lastMessage'] as String?,
      lastMessageSenderId: map['lastMessageSenderId'] as String?,
      lastMessageAt: _conversationDateTime(map['lastMessageAt']),
      lastReadAt: readTimes,
      isActive: map['isActive'] as bool? ?? true,
      createdAt: _conversationDateTime(map['createdAt']),
      updatedAt: _conversationDateTime(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'schoolId': schoolId,
      'participantIds': participantIds,
      'conversationType': conversationType,
      'title': title,
      'studentId': studentId,
      'lastMessage': lastMessage,
      'lastMessageSenderId': lastMessageSenderId,
      'lastMessageAt': lastMessageAt,
      'lastReadAt': lastReadAt.map(
        (key, value) => MapEntry(key, value),
      ),
      'isActive': isActive,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  bool get isDirect => conversationType == 'direct';

  bool get isGroup => conversationType == 'group';

  bool hasParticipant(String userId) {
    return participantIds.contains(userId);
  }

  Conversation copyWith({
    String? id,
    String? schoolId,
    List<String>? participantIds,
    String? conversationType,
    String? title,
    String? studentId,
    String? lastMessage,
    String? lastMessageSenderId,
    DateTime? lastMessageAt,
    Map<String, DateTime?>? lastReadAt,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Conversation(
      id: id ?? this.id,
      schoolId: schoolId ?? this.schoolId,
      participantIds: participantIds ?? this.participantIds,
      conversationType: conversationType ?? this.conversationType,
      title: title ?? this.title,
      studentId: studentId ?? this.studentId,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageSenderId:
          lastMessageSenderId ?? this.lastMessageSenderId,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      lastReadAt: lastReadAt ?? this.lastReadAt,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

DateTime? _conversationDateTime(dynamic value) {
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