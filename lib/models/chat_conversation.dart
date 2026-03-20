import 'chat_message.dart';

class ChatConversation {
  ChatConversation({
    required this.id,
    required this.name,
    required this.avatarUrl,
    required this.role,
    required this.status,
    required this.unreadCount,
    required this.lastMessage,
  });

  final String id;
  final String name;
  final String? avatarUrl;
  final String? role;
  final String status;
  final int unreadCount;
  final ChatMessage? lastMessage;

  factory ChatConversation.fromApi(Map<String, dynamic> json) {
    final lastMessageJson = json['lastMessage'];
    return ChatConversation(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? 'Conversation').toString(),
      avatarUrl: json['avatarUrl']?.toString(),
      role: json['role']?.toString(),
      status: (json['status'] ?? '').toString(),
      unreadCount: (json['unreadCount'] ?? 0) is int
          ? json['unreadCount'] as int
          : int.tryParse((json['unreadCount'] ?? '0').toString()) ?? 0,
      lastMessage: lastMessageJson is Map<String, dynamic>
          ? ChatMessage.fromApi(lastMessageJson)
          : null,
    );
  }
}
