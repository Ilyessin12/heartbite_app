import 'package:timeago/timeago.dart' as timeago;

class Comment {
  final String id;
  final String userName;
  final String userImageUrl;
  final String text;
  final String timeAgo;
  bool isLiked;
  int likeCount;
  final int? parentCommentId;
  List<Comment> replies;
  final String userId; // Added userId field

  Comment({
    required this.id,
    required this.userId, // Added userId to constructor
    required this.userName,
    required this.userImageUrl,
    required this.text,
    required this.timeAgo,
    this.isLiked = false,
    required this.likeCount,
    this.parentCommentId,
    List<Comment>? replies,
  }) : replies = replies ?? [];

  // Factory constructor for creating a new comment locally (e.g., before sending to server)
  factory Comment.create({
    required String text,
    String userName = "Anda", // "You"
    String userImageUrl = "assets/images/avatars/avatar1.jpg", // Default placeholder
    int? parentCommentId,
    String userId = "", // Default empty or use actual current user ID if available
  }) {
    return Comment(
      id: DateTime.now().millisecondsSinceEpoch.toString(), // Temporary ID
      userId: userId, // Use provided or default userId
      userName: userName,
      userImageUrl: userImageUrl,
      text: text,
      timeAgo: "Baru saja", // "Just now"
      likeCount: 0,
      parentCommentId: parentCommentId,
      replies: [],
    );
  }

  // Factory constructor for parsing data from Supabase
  factory Comment.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic>? userData = json['users'] as Map<String, dynamic>?;
    final createdAt = DateTime.parse(json['created_at'] as String);

    // Supabase returns count as a list with a single map: e.g., [{'count': 5}]
    final List<dynamic> likeCountData = json['comment_likes'] as List<dynamic>? ?? [];
    final int likes = likeCountData.isNotEmpty ? (likeCountData.first['count'] as int? ?? 0) : 0;
    
    final String commentUserId = userData?['id'] as String? ?? json['user_id'] as String? ?? '';


    return Comment(
      id: json['id'].toString(),
      userId: commentUserId, // Extracted userId
      userName: userData?['username'] as String? ?? 'Unknown User',
      userImageUrl: userData?['profile_picture'] as String? ?? 'assets/images/avatars/avatar1.jpg',
      text: json['comment'] as String,
      timeAgo: timeago.format(createdAt, locale: 'id'), // Format timestamp to time ago string
      likeCount: likes,
      isLiked: json['is_liked_by_current_user'] as bool? ?? false, 
      parentCommentId: json['parent_comment_id'] as int?,
      replies: [], // Replies will be populated separately
    );
  }

  Comment copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userImageUrl,
    String? text,
    String? timeAgo,
    bool? isLiked,
    int? likeCount,
    int? parentCommentId,
    List<Comment>? replies,
  }) {
    return Comment(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userImageUrl: userImageUrl ?? this.userImageUrl,
      text: text ?? this.text,
      timeAgo: timeAgo ?? this.timeAgo,
      isLiked: isLiked ?? this.isLiked,
      likeCount: likeCount ?? this.likeCount,
      parentCommentId: parentCommentId ?? this.parentCommentId,
      replies: replies ?? this.replies,
    );
  }
}