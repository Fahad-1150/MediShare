import '../models/chat_message.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

/// Service for managing chat messages using Supabase
class ChatService {
  final _supabase = Supabase.instance.client;

  /// Map Supabase row to ChatMessage model
  ChatMessage _mapRowToChatMessage(Map<String, dynamic> row) {
    return ChatMessage.fromJson(row);
  }

  /// Send a new message
  Future<String> sendMessage({
    required String requestId,
    required String senderId,
    required String senderName,
    required String recipientId,
    required String message,
  }) async {
    try {
      final messageId = const Uuid().v4();

      final response = await _supabase
          .from('chat_messages')
          .insert({
            'id': messageId,
            'request_id': requestId,
            'sender_id': senderId,
            'sender_name': senderName,
            'recipient_id': recipientId,
            'message': message,
            'created_at': DateTime.now().toIso8601String(),
            'is_read': false,
          })
          .select()
          .single();

      return response['id'] as String;
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  /// Get all messages for a request (ordered by created_at)
  Future<List<ChatMessage>> getMessagesByRequest(String requestId) async {
    try {
      final response = await _supabase
          .from('chat_messages')
          .select()
          .eq('request_id', requestId)
          .order('created_at', ascending: true);

      return (response as List)
          .map((row) => _mapRowToChatMessage(row as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch messages: $e');
    }
  }

  /// Get messages between two users for a specific request
  Future<List<ChatMessage>> getConversation(
    String requestId,
    String userId1,
    String userId2,
  ) async {
    try {
      final response = await _supabase
          .from('chat_messages')
          .select()
          .eq('request_id', requestId)
          .or(
            'and(sender_id.eq.$userId1,recipient_id.eq.$userId2),and(sender_id.eq.$userId2,recipient_id.eq.$userId1)',
          )
          .order('created_at', ascending: true);

      return (response as List)
          .map((row) => _mapRowToChatMessage(row as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch conversation: $e');
    }
  }

  /// Mark message as read
  Future<void> markMessageAsRead(String messageId) async {
    try {
      await _supabase
          .from('chat_messages')
          .update({'is_read': true})
          .eq('id', messageId);
    } catch (e) {
      throw Exception('Failed to mark message as read: $e');
    }
  }

  /// Mark all messages as read for a user in a request
  Future<void> markAllMessagesAsRead(String requestId, String userId) async {
    try {
      await _supabase
          .from('chat_messages')
          .update({'is_read': true})
          .eq('request_id', requestId)
          .eq('recipient_id', userId);
    } catch (e) {
      throw Exception('Failed to mark messages as read: $e');
    }
  }

  /// Delete a message
  Future<void> deleteMessage(String messageId) async {
    try {
      await _supabase.from('chat_messages').delete().eq('id', messageId);
    } catch (e) {
      throw Exception('Failed to delete message: $e');
    }
  }

  /// Get unread message count for a user in a request
  Future<int> getUnreadCount(String requestId, String userId) async {
    try {
      final response = await _supabase
          .from('chat_messages')
          .select()
          .eq('request_id', requestId)
          .eq('recipient_id', userId)
          .eq('is_read', false);

      return (response as List).length;
    } catch (e) {
      return 0;
    }
  }

  /// Get all messages (admin only)
  Future<List<ChatMessage>> getAllMessages() async {
    try {
      final response = await _supabase
          .from('chat_messages')
          .select()
          .order('created_at', ascending: false);

      return (response as List)
          .map((row) => _mapRowToChatMessage(row as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch all messages: $e');
    }
  }

  /// Get all messages involving a user (for messages list)
  Future<List<ChatMessage>> getAllUserMessages(String userId) async {
    try {
      final response = await _supabase
          .from('chat_messages')
          .select()
          .or('sender_id.eq.$userId,recipient_id.eq.$userId')
          .order('created_at', ascending: false);

      return (response as List)
          .map((row) => _mapRowToChatMessage(row as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch user messages: $e');
    }
  }
}
