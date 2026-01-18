import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/auth_state.dart';
import '../services/chat_service.dart';
import '../services/user_service.dart';
import '../models/chat_message.dart';
import '../models/user.dart';
import 'chat_page.dart';

class ConversationItem {
  final String otherUserId;
  final String otherUserName;
  final String lastMessage;
  final DateTime lastMessageTime;
  final int unreadCount;
  final List<String> requestIds;

  ConversationItem({
    required this.otherUserId,
    required this.otherUserName,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.unreadCount,
    required this.requestIds,
  });
}

class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key});

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  final ChatService _chatService = ChatService();
  final UserService _userService = UserService();
  late Future<List<ConversationItem>> _conversations;
  String searchTerm = '';
  String readFilter = 'All'; // 'All', 'Unread', 'Read'
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _conversations = _loadConversations();
  }

  Future<List<ConversationItem>> _loadConversations() async {
    try {
      final auth = context.read<AuthState>();
      final userId = auth.user!.userId;

      // Get all messages for this user
      final response = await _chatService.getAllUserMessages(userId);

      // Group messages by other user
      Map<String, List<ChatMessage>> conversationsByUser = {};
      Map<String, Set<String>> requestIdsByUser = {};

      for (final msg in response) {
        final otherUserId = msg.senderId == userId
            ? msg.recipientId
            : msg.senderId;

        if (!conversationsByUser.containsKey(otherUserId)) {
          conversationsByUser[otherUserId] = [];
          requestIdsByUser[otherUserId] = {};
        }

        conversationsByUser[otherUserId]!.add(msg);
        requestIdsByUser[otherUserId]!.add(msg.requestId);
      }

      // Create conversation items
      List<ConversationItem> items = [];

      for (final entry in conversationsByUser.entries) {
        final otherUserId = entry.key;
        final messages = entry.value;

        // Get user info
        UserModel? otherUser;
        try {
          otherUser = await _userService.getUserById(otherUserId);
        } catch (e) {
          // Handle error silently
        }

        // Sort messages by time (newest first)
        messages.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        // Get last message
        final lastMessage = messages.first;
        final lastMessagePreview = lastMessage.message.length > 50
            ? '${lastMessage.message.substring(0, 50)}...'
            : lastMessage.message;

        // Count unread messages for current user
        int unreadCount = 0;
        for (final msg in messages) {
          if (msg.recipientId == userId && !msg.isRead) {
            unreadCount++;
          }
        }

        items.add(
          ConversationItem(
            otherUserId: otherUserId,
            otherUserName: otherUser?.name ?? 'User',
            lastMessage: lastMessagePreview,
            lastMessageTime: lastMessage.createdAt,
            unreadCount: unreadCount,
            requestIds: requestIdsByUser[otherUserId]!.toList(),
          ),
        );
      }

      // Sort by last message time (newest first)
      items.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));

      return items;
    } catch (e) {
      throw Exception('Failed to load conversations: $e');
    }
  }

  void _refreshConversations() {
    setState(() {
      _conversations = _loadConversations();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ConversationItem> _filterConversations(
    List<ConversationItem> conversations,
  ) {
    return conversations.where((conversation) {
      // Search filter
      final matchesSearch = conversation.otherUserName.toLowerCase().contains(
        searchTerm.toLowerCase(),
      );

      // Read/Unread filter
      bool matchesReadFilter = true;
      if (readFilter == 'Unread') {
        matchesReadFilter = conversation.unreadCount > 0;
      } else if (readFilter == 'Read') {
        matchesReadFilter = conversation.unreadCount == 0;
      }

      return matchesSearch && matchesReadFilter;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          'Messages',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: FutureBuilder<List<ConversationItem>>(
        future: _conversations,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Colors.red.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading messages',
                    style: TextStyle(color: Colors.red.shade300, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          final conversations = snapshot.data ?? [];
          final filteredConversations = _filterConversations(conversations);

          if (conversations.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.message_outlined,
                    size: 64,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No messages yet',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your conversations will appear here',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            );
          }

          if (filteredConversations.isEmpty && conversations.isNotEmpty) {
            return SingleChildScrollView(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildSearchBar(),
                        const SizedBox(height: 12),
                        _buildReadFilter(),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 48),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 64,
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No conversations found',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Try adjusting your search or filter',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildSearchBar(),
                    const SizedBox(height: 12),
                    _buildReadFilter(),
                  ],
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async => _refreshConversations(),
                  child: ListView.builder(
                    itemCount: filteredConversations.length,
                    itemBuilder: (context, index) {
                      final conversation = filteredConversations[index];
                      return _buildConversationTile(conversation);
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildConversationTile(ConversationItem conversation) {
    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          leading: CircleAvatar(
            radius: 28,
            backgroundColor: Colors.blue.withOpacity(0.1),
            child: const Icon(Icons.person, color: Colors.blue, size: 28),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  conversation.otherUserName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (conversation.unreadCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${conversation.unreadCount}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          subtitle: Text(
            conversation.lastMessage,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
              overflow: TextOverflow.ellipsis,
            ),
            maxLines: 1,
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatMessageTime(conversation.lastMessageTime),
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
            ],
          ),
          onTap: () {
            // Open the most recent request conversation
            if (conversation.requestIds.isNotEmpty) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatPage(
                    requestId: conversation.requestIds.first,
                    otherUserId: conversation.otherUserId,
                    otherUserName: conversation.otherUserName,
                  ),
                ),
              ).then((_) => _refreshConversations());
            }
          },
        ),
        Divider(height: 1, color: Colors.grey.shade200),
      ],
    );
  }

  String _formatMessageTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (messageDate == today) {
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (messageDate == yesterday) {
      return 'Yesterday';
    } else if (now.difference(messageDate).inDays < 7) {
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return days[dateTime.weekday - 1];
    } else {
      return '${dateTime.day}/${dateTime.month}';
    }
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Search by name...',
        prefixIcon: const Icon(Icons.search),
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      onChanged: (value) {
        setState(() => searchTerm = value);
      },
    );
  }

  Widget _buildReadFilter() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: ['All', 'Unread', 'Read'].map((filter) {
          final isActive = readFilter == filter;
          Color getFilterColor(String f) {
            if (f == 'Unread') return Colors.red;
            if (f == 'Read') return Colors.green;
            return Colors.grey;
          }

          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: ChoiceChip(
              label: Text(filter),
              selected: isActive,
              onSelected: (_) => setState(() => readFilter = filter),
              selectedColor: getFilterColor(filter),
              backgroundColor: Colors.white,
              labelStyle: TextStyle(
                color: isActive ? Colors.white : Colors.black54,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
              shape: StadiumBorder(
                side: BorderSide(
                  color: isActive
                      ? getFilterColor(filter)
                      : Colors.grey.shade300,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
