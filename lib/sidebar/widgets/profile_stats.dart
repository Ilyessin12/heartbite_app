// widgets/profile_stats.dart
import 'package:flutter/material.dart';

class ProfileStats extends StatelessWidget {
  final int recipes;
  final int following;
  final int followers;
  final VoidCallback onFollowingTap;
  final VoidCallback onFollowersTap;

  const ProfileStats({
    super.key,
    required this.recipes,
    required this.following,
    required this.followers,
    required this.onFollowingTap,
    required this.onFollowersTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildStat('Resep', recipes),
        GestureDetector(
          onTap: onFollowingTap,
          child: _buildStat('Mengikuti', following),
        ),
        GestureDetector(
          onTap: onFollowersTap,
          child: _buildStat('Pengikut', followers),
        ),
      ],
    );
  }

  Widget _buildStat(String label, int count) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Color.fromARGB(255, 42, 42, 42)),
        ),
      ],
    );
  }
}
