import 'package:flutter/material.dart';

import '../models/chat_conversation.dart';
import '../models/chat_message.dart';
import '../services/chat_service.dart';
import '../widgets/jobflow_app_bar.dart';
import '../widgets/section_card.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final _chatService = ChatService();
  final _messageController = TextEditingController();
  List<ChatConversation> _conversations = const [];
  List<ChatMessage> _messages = const [];
  ChatConversation? _activeConversation;
  bool _isLoading = true;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadConversations() async {
    final conversations = await _chatService.fetchConversations();
    if (!mounted) {
      return;
    }
    setState(() {
      _conversations = conversations;
      _isLoading = false;
      if (_activeConversation == null && conversations.isNotEmpty) {
        _activeConversation = conversations.first;
      }
    });
    if (_activeConversation != null) {
      await _loadMessages(_activeConversation!);
    }
  }

  Future<void> _loadMessages(ChatConversation conversation) async {
    final messages = await _chatService.fetchMessages(conversation.id);
    if (!mounted) {
      return;
    }
    setState(() {
      _activeConversation = conversation;
      _messages = messages;
    });
    await _chatService.markConversationRead(conversation.id);
  }

  Future<void> _sendMessage() async {
    if (_isSending || _activeConversation == null) {
      return;
    }
    final content = _messageController.text.trim();
    if (content.isEmpty) {
      return;
    }

    setState(() => _isSending = true);
    final message = await _chatService.sendMessage(
      conversationId: _activeConversation!.id,
      content: content,
    );
    if (!mounted) {
      return;
    }

    if (message != null) {
      setState(() {
        _messages = [..._messages, message];
        _messageController.clear();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to send message.')),
      );
    }

    setState(() => _isSending = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const JobFlowAppBar(title: 'Org channel'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Conversations', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 12),
                      if (_conversations.isEmpty)
                        const Text('No conversations yet.')
                      else
                        ..._conversations.map(
                          (conversation) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(conversation.name),
                            subtitle: Text(conversation.lastMessage?.content ?? 'No messages yet'),
                            trailing: conversation.unreadCount > 0
                                ? CircleAvatar(
                                    radius: 12,
                                    backgroundColor: Theme.of(context).colorScheme.primary,
                                    child: Text(
                                      conversation.unreadCount.toString(),
                                      style: const TextStyle(color: Colors.white, fontSize: 12),
                                    ),
                                  )
                                : null,
                            onTap: () => _loadMessages(conversation),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Messages', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 12),
                      if (_activeConversation == null)
                        const Text('Select a conversation to view messages.')
                      else if (_messages.isEmpty)
                        const Text('No messages yet.')
                      else
                        ..._messages.map(
                          (message) => Align(
                            alignment: message.isMine ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: message.isMine
                                    ? Theme.of(context).colorScheme.primary.withOpacity(0.12)
                                    : Theme.of(context).colorScheme.surfaceVariant,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(message.content),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Send message', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _messageController,
                        maxLines: 3,
                        decoration: const InputDecoration(hintText: 'Type a quick update...'),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isSending ? null : _sendMessage,
                          icon: const Icon(Icons.send_outlined),
                          label: Text(_isSending ? 'Sending...' : 'Send'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
