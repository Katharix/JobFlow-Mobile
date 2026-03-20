class ChatMessage {
  ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.content,
    required this.attachmentUrl,
    required this.sentAt,
    required this.senderName,
    required this.senderAvatarUrl,
    required this.isMine,
    required this.isRead,
  });

  final String id;
  final String conversationId;
  final String? senderId;
  final String content;
  final String? attachmentUrl;
  final DateTime sentAt;
  final String? senderName;
  final String? senderAvatarUrl;
  final bool isMine;
  final bool isRead;

  factory ChatMessage.fromApi(Map<String, dynamic> json) {
    final sentAtRaw = json['sentAt']?.toString() ?? '';
    DateTime sentAt;
    try {
      sentAt = DateTime.parse(sentAtRaw).toLocal();
    } catch (_) {
      sentAt = DateTime.now();
    }

    return ChatMessage(
      id: (json['id'] ?? '').toString(),
      conversationId: (json['conversationId'] ?? '').toString(),
      senderId: json['senderId']?.toString(),
      content: (json['content'] ?? '').toString(),
      attachmentUrl: json['attachmentUrl']?.toString(),
      sentAt: sentAt,
      senderName: json['senderName']?.toString(),
      senderAvatarUrl: json['senderAvatarUrl']?.toString(),
      isMine: json['isMine'] == true,
      isRead: json['isRead'] == true,
    );
  }
}
