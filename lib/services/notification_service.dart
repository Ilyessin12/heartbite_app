import 'dart:convert';
import 'package:heartbite_tubesprovis/services/supabase_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;

class NotificationService {
  final SupabaseClient _client = SupabaseClientWrapper().client;
  RealtimeChannel? _notificationChannel;
  
  NotificationService();
  // Subscribe to realtime notifications for a specific user
  void subscribeToUserNotifications(String userId, Function(List<dynamic>) onNotification) {
    // First unsubscribe any existing subscription
    unsubscribeFromUserNotifications();
    
    // Create a new channel subscription for this user
    _notificationChannel = _client.channel('public:notifications:$userId');
    
    // Configure the channel to listen for notification changes
    _notificationChannel = _notificationChannel!.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'notifications',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'receiver_id',
        value: userId,
      ),
      callback: (payload) {
        // Fetch updated notifications after new one is received
        fetchUserNotifications(userId).then(onNotification);
      },
    );
    
    // Subscribe to the channel
    _notificationChannel?.subscribe();
  }

  // Unsubscribe from notifications channel
  void unsubscribeFromUserNotifications() {
    if (_notificationChannel != null) {
      _notificationChannel?.unsubscribe();
      _notificationChannel = null;
    }
  }  // Fetch all notifications for a user
  Future<List<Map<String, dynamic>>> fetchUserNotifications(String userId) async {
    try {
      // Query that doesn't try to join on related_id since it might not be a valid foreign key reference
      final response = await _client
        .from('notifications')
        .select('''
          *,
          sender:sender_id(*)
        ''')
        .eq('receiver_id', userId)
        .order('created_at', ascending: false);
      
      final notifications = response as List<dynamic>;
      
      // Format the data for our UI
      final formattedNotifications = notifications.map<Map<String, dynamic>>((item) {
        // Parse the date from database
        final DateTime createdAt = DateTime.parse(item['created_at']).toLocal();
        
        // Format the date to show actual timestamp instead of relative time
        final String formattedTime = '${createdAt.day}/${createdAt.month}/${createdAt.year} ${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}';
        
        // Build a notification object that matches our UI format
        return _formatNotificationForUI(item, formattedTime);
      }).toList();
      
      return formattedNotifications;
    } catch (e) {
      print('Error fetching notifications: $e');
      return [];
    }
  }
  // Mark notification as read
  Future<void> markNotificationAsRead(int notificationId) async {
    try {
      await _client
        .from('notifications')
        .update({'is_read': true})
        .eq('id', notificationId);
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  // Mark all notifications as read for a user
  Future<void> markAllNotificationsAsRead(String userId) async {
    try {
      await _client
        .from('notifications')
        .update({'is_read': true})
        .eq('receiver_id', userId)
        .eq('is_read', false);
    } catch (e) {
      print('Error marking all notifications as read: $e');
    }
  }// Format notification from Supabase to match our UI
  Map<String, dynamic> _formatNotificationForUI(Map<String, dynamic> item, String formattedTime) {
    // Extract sender and user profile info
    final sender = item['sender'] ?? {};
    
    final String senderName = sender['username'] ?? 'Unknown User';
    final String profileImageUrl = sender['avatar_url'] ?? '';
    // Default profile image if no URL is available
    final String profileImage = profileImageUrl.isEmpty 
        ? 'assets/images/default_profile.png' 
        : profileImageUrl;
    
    // Initialize notification object with common fields
    final Map<String, dynamic> notification = {
      'id': item['id'],
      'nama': senderName,
      'waktu': formattedTime,
      'gambarProfil': profileImage,
      'dibaca': item['is_read'] ?? false,
    };
    
    // Try to parse related_data if it's a string, or use direct fields if available
    Map<String, dynamic> relatedData = {};
    
    if (item['related_data'] != null) {
      if (item['related_data'] is Map) {
        relatedData = item['related_data'] as Map<String, dynamic>;
      } else if (item['related_data'] is String) {
        try {
          // Try to parse JSON string
          relatedData = Map<String, dynamic>.from(jsonDecode(item['related_data']));
        } catch (e) {
          // If parsing fails, we'll use the direct fields
        }
      }
    }
    
    // Get notification type
    final String type = item['type'] ?? '';
    
    // Get content and recipe_title from direct fields if available
    final String content = item['content'] ?? relatedData['content'] ?? '';
    final String recipeTitle = item['recipe_title'] ?? relatedData['recipe_title'] ?? 'Resep';
    
    // Determine the notification type and format accordingly
    switch (type) {
      case 'like_recipe':
        notification['tipe'] = 'like_resep';
        notification['aksi'] = 'menyukai resep Anda';
        notification['adaGambar'] = true;
        notification['targetNama'] = relatedData['title'] ?? recipeTitle;
        notification['gambarKonten'] = relatedData['image_url'] ?? 'assets/images/default_food.png';
        break;
        
      case 'like_comment':
        notification['tipe'] = 'like_komentar';
        notification['aksi'] = 'menyukai komentar Anda';
        notification['adaGambar'] = false;
        notification['targetNama'] = content.isEmpty ? 'Komentar Anda' : content;
        notification['subteks'] = 'pada resep $recipeTitle';
        break;

      case 'follow':
        notification['tipe'] = 'follow';
        // Check if this is a mutual follow based on if the sender is following the receiver
        final bool isMutual = relatedData['is_mutual'] ?? false;
        notification['aksi'] = isMutual 
            ? 'telah mengikuti Anda kembali' 
            : 'telah mengikuti Anda';
        notification['adaGambar'] = false;
        notification['adaTombolIkuti'] = !isMutual;
        notification['isFollowingYou'] = isMutual;        break;

      case 'comment':
        notification['tipe'] = 'komentar_resep';
        notification['aksi'] = 'mengomentari resep Anda:';
        notification['adaGambar'] = true;
        notification['subteks'] = content;
        notification['gambarKonten'] = relatedData['image_url'] ?? 'assets/images/default_food.png';
        notification['targetNama'] = relatedData['title'] ?? recipeTitle;
        break;

      default:
        notification['tipe'] = 'other';
        notification['aksi'] = 'berinteraksi dengan Anda';
        notification['adaGambar'] = false;
    }
    
    return notification;
  }
  
  // Helper method to group notifications by read/unread status
  Map<String, List<Map<String, dynamic>>> groupNotificationsByReadStatus(
      List<Map<String, dynamic>> notifications) {
    final unreadNotifications = <Map<String, dynamic>>[];
    final readNotifications = <Map<String, dynamic>>[];
    
    for (final notification in notifications) {
      if (notification['dibaca'] == true) {
        readNotifications.add(notification);
      } else {
        unreadNotifications.add(notification);
      }
    }
    
    return {
      'unread': unreadNotifications,
      'read': readNotifications,
    };
  }
}
