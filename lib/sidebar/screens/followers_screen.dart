import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_back_button.dart';
import '../widgets/user_list_item.dart';

class FollowersScreen extends StatelessWidget {
  const FollowersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> followers = [
      {
        'name': 'Griffin',
        'username': '@griffin',
        'avatarUrl': 'assets/images/avatars/avatar1.jpg',
      },
      {
        'name': 'Senator Armstrong',
        'username': '@senatorarmstrong',
        'avatarUrl': 'assets/images/avatars/avatar2.jpg',
      },
      {
        'name': 'Johnny Cann',
        'username': '@johnnycann',
        'avatarUrl': 'assets/images/avatars/avatar3.jpg',
      },
      {
        'name': 'Anna Villanueva',
        'username': '@annavillanueva',
        'avatarUrl': 'assets/images/avatars/avatar4.jpg',
      },
      {
        'name': 'Elliot Rodgers',
        'username': '@elliotrodgers',
        'avatarUrl': 'assets/images/avatars/avatar5.jpg',
      },
      {
        'name': 'Dekan',
        'username': '@dekanofficial',
        'avatarUrl': 'assets/images/avatars/avatar2.jpg',
      },
    ];

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: ListView.builder(
                itemCount: followers.length,
                itemBuilder: (context, index) {
                  final user = followers[index];
                  return UserListItem(
                    name: user['name'],
                    username: user['username'],
                    avatarUrl: user['avatarUrl'],
                    onFollowTap: () {},
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          CustomBackButton(
            onPressed: () => Navigator.pop(context),
          ),
          const Expanded(
            child: Center(
              child: Text(
                'Follower',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ),
          const SizedBox(width: 32), // For balance
        ],
      ),
    );
  }
}
