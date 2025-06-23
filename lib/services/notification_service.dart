import 'package:heartbite_tubesprovis/services/supabase_client.dart';
import 'package:heartbite_tubesprovis/notification_pages/model/notification_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationService {
  final SupabaseClient _client = SupabaseClientWrapper().client;
  RealtimeChannel? _notificationChannel;
  
  NotificationService();  // Subscribe to realtime notifications for a specific user
  void subscribeToUserNotifications(String userId, Function(List<NotificationModel>) onNotification) {
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
  Future<List<NotificationModel>> fetchUserNotifications(String userId) async {
    try {
      // First get basic notification data with sender info
      final response = await _client
        .from('notifications')
        .select('''
          *,
          sender:sender_id(*)
        ''')
        .eq('receiver_id', userId)
        .order('created_at', ascending: false);
      
      final notifications = response as List<dynamic>;
      print('Found ${notifications.length} notifications for user $userId');
        // Process notifications to add related data based on type
      final processedNotifications = await Future.wait(notifications.map((item) async {
        // If this is a like_recipe notification, fetch the recipe data
        if (item['type'] == 'like_recipe') {
          try {
            final recipeId = int.tryParse(item['related_id']);
            if (recipeId != null) {
              print('Fetching recipe data for notification ${item['id']}, recipe $recipeId');
              
              final recipeData = await _client
                .from('recipes')
                .select('id, title, image_url, description')
                .eq('id', recipeId)
                .maybeSingle();
              
              if (recipeData != null) {
                // Store recipe data in the 'recipe' field expected by NotificationModel.fromSupabase
                item['recipe'] = recipeData;
                print('Found recipe: ${recipeData['title']}');
              } else {
                print('Recipe $recipeId not found');
              }
            }
          } catch (e) {
            print('Error fetching recipe data: $e');
          }
        }
        
        // Similar handling could be added for other types like comment
        // that might need extra data
        
        return item;
      }));
        // Convert to notification models
      final notificationModels = processedNotifications.map<NotificationModel>((item) {
        // Debug the recipe data
        if (item['type'] == 'like_recipe') {
          print('Converting notification ${item['id']} with recipe data:');
          if (item.containsKey('recipe')) {
            print('  Recipe found: ${item['recipe']['title'] ?? 'No title'}, ${item['recipe']['image_url'] ?? 'No image'}');
          } else {
            print('  No recipe data found for this notification');
          }
        }
        
        return NotificationModel.fromSupabase(item);
      }).toList();
      
      // Debug the final notification models
      for (final model in notificationModels) {
        if (model.type == 'like_recipe') {
          print('Final notification model ${model.id}:');
          print('  recipeId: ${model.recipeId}');
          print('  recipeTitle: ${model.recipeTitle}');
          print('  imageUrl: ${model.imageUrl}');
        }
      }
      
      return notificationModels;
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
  }
  // Helper method to group notifications by read/unread status
  Map<String, List<Map<String, dynamic>>> groupNotificationsByReadStatus(
      List<NotificationModel> notifications) {
    final unreadNotifications = <Map<String, dynamic>>[];
    final readNotifications = <Map<String, dynamic>>[];
    
    print('Grouping ${notifications.length} notifications');
    
    for (final notification in notifications) {
      try {
        final notificationMap = notification.toUiMap();
        
        if (notification.isRead) {
          readNotifications.add(notificationMap);
          print('Added read notification: ${notification.id}');
        } else {
          unreadNotifications.add(notificationMap);
          print('Added unread notification: ${notification.id}');
        }
      } catch (e) {
        print('Error converting notification ${notification.id} to UI map: $e');
      }
    }
    
    print('Grouped ${unreadNotifications.length} unread and ${readNotifications.length} read notifications');
    
    return {
      'unread': unreadNotifications,
      'read': readNotifications,
    };
  }
}
