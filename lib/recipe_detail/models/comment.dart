class Comment {
  final String id;
  final String userName;
  final String userImageUrl;
  final String text;
  final String timeAgo;
  bool isLiked;
  int likeCount;
  
  Comment({
    required this.id,
    required this.userName,
    required this.userImageUrl,
    required this.text,
    required this.timeAgo,
    this.isLiked = false,
    required this.likeCount,
  });
  
  // Factory constructor untuk user membuat komen baru
  factory Comment.create({
    required String text,
    String userName = "Anda",
    String userImageUrl = "assets/images/avatars/avatar1.jpg",
  }) {
    return Comment(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userName: userName,
      userImageUrl: userImageUrl,
      text: text,
      timeAgo: "Baru saja",
      likeCount: 0,
    );
  }
  
  Comment copyWith({
    String? id,
    String? userName,
    String? userImageUrl,
    String? text,
    String? timeAgo,
    bool? isLiked,
    int? likeCount,
  }) {
    return Comment(
      id: id ?? this.id,
      userName: userName ?? this.userName,
      userImageUrl: userImageUrl ?? this.userImageUrl,
      text: text ?? this.text,
      timeAgo: timeAgo ?? this.timeAgo,
      isLiked: isLiked ?? this.isLiked,
      likeCount: likeCount ?? this.likeCount,
    );
  }
}