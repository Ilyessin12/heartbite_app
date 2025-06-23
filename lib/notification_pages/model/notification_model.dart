import 'dart:convert';

class NotificationModel {
  final int id;
  final String senderId;
  final String receiverId;
  final String type;
  final String relatedId;
  final bool isRead;
  final DateTime createdAt;
  
  // UI-specific properties
  final String senderName;
  final String senderProfileImage;
  final String formattedTime;
  
  // Derived properties
  String? targetName;
  String? subtitle;
  String? imageUrl;
  bool? isMutualFollow;
  
  // Recipe-specific properties (for like_recipe and comment types)
  int? recipeId;
  String? recipeTitle;
  String? recipeDescription;
  
  NotificationModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.type,
    required this.relatedId,
    required this.isRead,
    required this.createdAt,
    required this.senderName,
    required this.senderProfileImage,
    required this.formattedTime,
    this.targetName,
    this.subtitle,
    this.imageUrl,
    this.isMutualFollow,
    this.recipeId,
    this.recipeTitle,
    this.recipeDescription,
  });
  // Convert Supabase response to NotificationModel
  factory NotificationModel.fromSupabase(Map<String, dynamic> item) {
    // Extract sender information
    final Map<String, dynamic> sender = item['sender'] ?? {};
    final String senderName = sender['username'] ?? 'Unknown User';
    final String profileImageUrl = sender['profile_picture'] ?? '';
    final String profileImage = profileImageUrl.isEmpty 
        ? 'assets/images/default_profile.png' 
        : profileImageUrl;
    
    // Parse date and format it
    final DateTime createdAt = DateTime.parse(item['created_at']).toLocal();
    final String formattedTime = '${createdAt.day}/${createdAt.month}/${createdAt.year} ${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}';
    
    // Initialize notification model with basic data
    final NotificationModel notification = NotificationModel(
      id: item['id'],
      senderId: item['sender_id'],
      receiverId: item['receiver_id'],
      type: item['type'],
      relatedId: item['related_id'],
      isRead: item['is_read'] ?? false,
      createdAt: createdAt,
      senderName: senderName,
      senderProfileImage: profileImage,
      formattedTime: formattedTime,
    );
    
    // Extract recipe information if included in the join
    final Map<String, dynamic> recipe = item['recipe'] ?? {};
    
    // Process the related data for display
    notification.processRelatedData(item, recipe);
    
    return notification;  }
  
  // Process related data to extract UI information
  void processRelatedData(Map<String, dynamic> item, [Map<String, dynamic>? recipeData]) {
    // Basic error handling and debugging
    print('Processing notification: ${item['id']}, type: ${item['type']}');
    
    // Get recipe data if available
    final Map<String, dynamic> recipe = recipeData ?? item['recipe'] ?? {};
    
    // Default values and simple processing for now to ensure notifications work
    final String content = item['content'] ?? '';
    
    // Set basic info based on type
    switch (type) {
      case 'like_recipe':
        // Try to get recipe details
        if (recipe.isNotEmpty) {
          // Use recipe data from join
          recipeId = recipe['id'];
          recipeTitle = recipe['title'];
          recipeDescription = recipe['description'];
          targetName = recipeTitle ?? 'Resep Anda';
            // Use recipe image if available
          final String recipeImageUrl = recipe['image_url'] ?? '';
          if (recipeImageUrl.isNotEmpty) {
            imageUrl = recipeImageUrl;
            print('Using recipe image: $imageUrl');
          } else {
            imageUrl = 'assets/images/default_food.png';
          }
        } else {
          targetName = 'Resep Anda';
          // Try to get int ID if possible
          try {
            final int? recipeIdVal = int.tryParse(relatedId);
            if (recipeIdVal != null) {
              recipeId = recipeIdVal;
            }
          } catch (e) {
            print('Error parsing recipe ID: $e');
          }
          imageUrl = 'assets/images/default_food.png';
        }
        break;
        case 'like_comment':
        targetName = content.isEmpty ? 'Komentar Anda' : content;
        subtitle = 'pada resep';
        break;

      case 'follow':
        isMutualFollow = false; // Default to false to show follow button
        break;

      case 'comment':
        subtitle = content;
        targetName = 'Resep Anda';
        imageUrl = 'assets/images/default_food.png';
        break;
        
      default:
        targetName = 'Notifikasi';
        break;
    }
  }
  
  // UI helpers
  String get displayType {
    switch (type) {
      case 'like_recipe': return 'like_resep';
      case 'like_comment': return 'like_komentar';
      case 'follow': return 'follow';
      case 'comment': return 'komentar_resep';
      default: return 'other';
    }
  }
  
  String get actionText {
    switch (type) {
      case 'like_recipe': return 'menyukai resep Anda';
      case 'like_comment': return 'menyukai komentar Anda';
      case 'follow': 
        return isMutualFollow == true
            ? 'telah mengikuti Anda kembali'
            : 'telah mengikuti Anda';
      case 'comment': return 'mengomentari resep Anda:';
      default: return 'berinteraksi dengan Anda';
    }
  }
  
  bool get hasImage => imageUrl != null;
  bool get hasSubtitle => subtitle != null;
  bool get showFollowButton => type == 'follow' && !(isMutualFollow ?? false);
  // Convert to map for existing UI code
  Map<String, dynamic> toUiMap() {
    final navigationInfo = getNavigationInfo();
    
    // Add debug print to see what's getting sent to UI
    print('Converting notification ${id} to UI map, type: ${displayType}');
    
    final map = {
      'id': id,
      'nama': senderName,
      'waktu': formattedTime,
      'gambarProfil': senderProfileImage,
      'dibaca': isRead,
      'tipe': displayType,
      'aksi': actionText,
      'adaGambar': hasImage,
      'targetNama': targetName ?? 'Notification',
      // Always provide gambarKonten to avoid null errors
      'gambarKonten': imageUrl ?? 'assets/images/default_food.png',
      // Provide subtitle with default if needed
      'subteks': subtitle ?? '',
      // Always include these boolean flags
      'adaTombolIkuti': type == 'follow' && !(isMutualFollow ?? false),
      'isFollowingYou': type == 'follow' && (isMutualFollow ?? false),
      // Navigation details
      'canNavigate': navigationInfo['canNavigate'],
      'navigationRoute': navigationInfo['route'],
      'navigationArgs': navigationInfo['arguments'],
      // Include recipe ID for direct reference
      'recipeId': recipeId ?? 0,
    };
    
    return map;
  }
  
  // Helper for navigation based on notification type
  Map<String, dynamic> getNavigationInfo() {
    final Map<String, dynamic> navigationInfo = {
      'canNavigate': false,
      'route': null,
      'arguments': null,
    };
    
    switch (type) {
      case 'like_recipe':
      case 'comment':
        if (recipeId != null) {
          navigationInfo['canNavigate'] = true;
          navigationInfo['route'] = '/recipe-detail';
          navigationInfo['arguments'] = {'recipeId': recipeId};
        }
        break;
        
      case 'like_comment':
        if (recipeId != null) {
          navigationInfo['canNavigate'] = true;
          navigationInfo['route'] = '/recipe-detail';
          navigationInfo['arguments'] = {
            'recipeId': recipeId,
            'scrollToComments': true
          };
        }
        break;
        
      case 'follow':
        navigationInfo['canNavigate'] = true;
        navigationInfo['route'] = '/profile';
        navigationInfo['arguments'] = {'userId': senderId};
        break;
    }
    
    return navigationInfo;
  }
}
