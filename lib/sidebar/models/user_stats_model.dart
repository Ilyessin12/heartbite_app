class UserStatsModel {
  final int recipesCount;
  final int followersCount;
  final int followingCount;

  UserStatsModel({
    required this.recipesCount,
    required this.followersCount,
    required this.followingCount,
  });

  factory UserStatsModel.fromJson(Map<String, dynamic> json) {
    return UserStatsModel(
      recipesCount: json['recipes_count'] ?? 0,
      followersCount: json['followers_count'] ?? 0,
      followingCount: json['following_count'] ?? 0,
    );
  }
}
