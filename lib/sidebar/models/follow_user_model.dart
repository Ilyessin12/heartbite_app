class FollowUserModel {
  final String id;
  final String fullName;
  final String username;
  final String? profilePicture;
  final DateTime followedAt;
  final bool isFollowing; // untuk track status follow/unfollow

  FollowUserModel({
    required this.id,
    required this.fullName,
    required this.username,
    this.profilePicture,
    required this.followedAt,
    this.isFollowing = true,
  });

  factory FollowUserModel.fromJson(Map<String, dynamic> json) {
    return FollowUserModel(
      id: json['id'],
      fullName: json['full_name'],
      username: json['username'],
      profilePicture: json['profile_picture'],
      followedAt: DateTime.parse(json['created_at']),
      isFollowing: json['is_following'] ?? true,
    );
  }

  FollowUserModel copyWith({
    String? id,
    String? fullName,
    String? username,
    String? profilePicture,
    DateTime? followedAt,
    bool? isFollowing,
  }) {
    return FollowUserModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      username: username ?? this.username,
      profilePicture: profilePicture ?? this.profilePicture,
      followedAt: followedAt ?? this.followedAt,
      isFollowing: isFollowing ?? this.isFollowing,
    );
  }
}
