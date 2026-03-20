import 'dart:convert';

import '../constants/app_constants.dart';
import '../models/chat_conversation.dart';
import '../models/chat_message.dart';
import '../state/app_session.dart';
import 'api_client.dart';

class ChatService {
  ChatService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient(baseUrl: AppConstants.apiBaseUrl);

  final ApiClient _apiClient;

  Future<List<ChatConversation>> fetchConversations() async {
    if (!AppSession.isAuthenticated) {
      return demoConversations;
    }

    final response = await _apiClient.get(AppConstants.chatConversationsPath);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      return demoConversations;
    }

    final data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((item) => ChatConversation.fromApi(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<ChatMessage>> fetchMessages(String conversationId) async {
    if (!AppSession.isAuthenticated) {
      return demoMessages;
    }

    final response = await _apiClient.get('${AppConstants.chatMessagesPath}/$conversationId');
    if (response.statusCode < 200 || response.statusCode >= 300) {
      return demoMessages;
    }

    final data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((item) => ChatMessage.fromApi(item as Map<String, dynamic>))
        .toList();
  }

  Future<ChatMessage?> sendMessage({
    required String conversationId,
    required String content,
    String? attachmentUrl,
  }) async {
    if (!AppSession.isAuthenticated) {
      return null;
    }

    final response = await _apiClient.postJson(
      AppConstants.chatMessagesPath,
      {
        'conversationId': conversationId,
        'content': content,
        'attachmentUrl': attachmentUrl,
      },
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      return null;
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return ChatMessage.fromApi(data);
  }

  Future<bool> markConversationRead(String conversationId) async {
    if (!AppSession.isAuthenticated) {
      return false;
    }

    final response = await _apiClient.postJson(
      '${AppConstants.chatReadPath}/$conversationId/read',
      {},
    );
    return response.statusCode >= 200 && response.statusCode < 300;
  }
}

final List<ChatConversation> demoConversations = [
  ChatConversation(
    id: 'e2b5f60a-1234-4ae2-9fcd-774e7f0e1a11',
    name: 'Dispatch updates',
    avatarUrl: null,
    role: 'Dispatch',
    status: 'Active',
    unreadCount: 1,
    lastMessage: ChatMessage(
      id: '14f9f60a-1234-4ae2-9fcd-774e7f0e1a55',
      conversationId: 'e2b5f60a-1234-4ae2-9fcd-774e7f0e1a11',
      senderId: null,
      content: 'Job 214 pulled permit. Call client if any delays.',
      attachmentUrl: null,
      sentAt: DateTime.now().subtract(const Duration(minutes: 30)),
      senderName: 'Dispatch',
      senderAvatarUrl: null,
      isMine: false,
      isRead: false,
    ),
  ),
];

final List<ChatMessage> demoMessages = [
  ChatMessage(
    id: '14f9f60a-1234-4ae2-9fcd-774e7f0e1a55',
    conversationId: 'e2b5f60a-1234-4ae2-9fcd-774e7f0e1a11',
    senderId: null,
    content: 'Job 214 pulled permit. Call client if any delays.',
    attachmentUrl: null,
    sentAt: DateTime.now().subtract(const Duration(minutes: 30)),
    senderName: 'Dispatch',
    senderAvatarUrl: null,
    isMine: false,
    isRead: false,
  ),
  ChatMessage(
    id: '22f9f60a-1234-4ae2-9fcd-774e7f0e1a66',
    conversationId: 'e2b5f60a-1234-4ae2-9fcd-774e7f0e1a11',
    senderId: 'me',
    content: 'On the way. ETA 15 mins.',
    attachmentUrl: null,
    sentAt: DateTime.now().subtract(const Duration(minutes: 12)),
    senderName: 'You',
    senderAvatarUrl: null,
    isMine: true,
    isRead: true,
  ),
];
